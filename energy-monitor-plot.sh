#!/bin/bash

### How it works ###
### * No `--span` → dynamically detects file range, fits to terminal columns.
### * With a span → end is `now`, start is computed with GNU `date`.
### * BIN_WIDTH matches the terminal plot size to prevent character overlap.

DEFAULT_LOG="/var/log/energy-monitor/energy-monitor.log"

# --- Argument Parsing ---
FILE="$DEFAULT_LOG"
SPAN=""
MODE="both"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --span=*)
            SPAN="${1#*=}"
            shift
            ;;
        --span)
            if [ -n "$2" ] && [[ "$2" != --* ]]; then
                SPAN="$2"
                shift 2
            else
                echo "Error: --span requires an argument (hour, day, week, month, ytd)"
                exit 1
            fi
            ;;
        --cost|--power|--both)
            MODE="${1#--}"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--span=<interval>] [--cost | --power | --both] [logfile]"
            echo "Intervals: hour, day, week, month, ytd"
            exit 0
            ;;
        -*)
            echo "Error: Unknown option $1"
            exit 1
            ;;
        *)
            FILE="$1"
            shift
            ;;
    esac
done

# --- Validation ---
if [ ! -f "$FILE" ]; then
    echo "Error: File $FILE not found."
    exit 1
fi

# Define terminal configuration boundaries
TERM_WIDTH=132
TERM_HEIGHT=30
TARGET_BINS=110  # Leave some columns open for borders/y-axis tics
MIN_BIN_WIDTH=10

START_EPOCH=""
END_EPOCH=""

if [ -n "$SPAN" ]; then
    END_EPOCH=$(date +%s)
    case "${SPAN,,}" in
        hour)  START_EPOCH=$(date -d "1 hour ago" +%s) ;;
        day)   START_EPOCH=$(date -d "1 day ago" +%s) ;;
        week)  START_EPOCH=$(date -d "1 week ago" +%s) ;;
        month) START_EPOCH=$(date -d "1 month ago" +%s) ;;
        ytd|year-to-date) START_EPOCH=$(date -d "$(date +%Y)-01-01 00:00:00" +%s) ;;
        *) echo "Error: Span must be one of hour, day, week, month, ytd"; exit 1 ;;
    esac
    DURATION=$(( END_EPOCH - START_EPOCH ))
    BIN_WIDTH=$(( DURATION / TARGET_BINS ))
else
    # If no span is provided, scan the file to find the actual start and end timestamps
    FIRST_LINE=$(head -n 1 "$FILE" 2>/dev/null)
    LAST_LINE=$(tail -n 1 "$FILE" 2>/dev/null)
    
    if [ -n "$FIRST_LINE" ] && [ -n "$LAST_LINE" ]; then
        # Extract and parse timestamps safely into epochs using awk
        START_EPOCH=$(awk -F, '{dt=substr($1,1,19); gsub(/[-T:]/," ",dt); print mktime(dt); exit}' <<< "$FIRST_LINE")
        END_EPOCH=$(awk -F, '{dt=substr($1,1,19); gsub(/[-T:]/," ",dt); print mktime(dt); exit}' <<< "$LAST_LINE")
        
        if [ -n "$START_EPOCH" ] && [ -n "$END_EPOCH" ] && [ "$END_EPOCH" -gt "$START_EPOCH" ]; then
            DURATION=$(( END_EPOCH - START_EPOCH ))
            BIN_WIDTH=$(( DURATION / TARGET_BINS ))
        else
            BIN_WIDTH=300
        fi
    else
        BIN_WIDTH=300
    fi
fi

[ $BIN_WIDTH -lt $MIN_BIN_WIDTH ] && BIN_WIDTH=$MIN_BIN_WIDTH

TMP_DATA=$(mktemp)

# Calculate average power and cumulative cost accurately across balanced bins
awk -F, -v start="$START_EPOCH" -v end="$END_EPOCH" -v bw="$BIN_WIDTH" '
BEGIN { OFS=" " }
{
    dt = substr($1, 1, 19);
    gsub(/[-T:]/, " ", dt);
    epoch = mktime(dt);
    
    # Filter bounds
    if(start!="" && (epoch < start || epoch >= end)) next
    
    bin = int(epoch / bw) * bw
    sum[bin] += $3;
    cnt[bin]++
}
END {
    n = asorti(sum, keys)
    running_cost = 0
    for(i = 1; i <= n; i++) {
        b = keys[i]
        avg_w = sum[b] / cnt[b]
        
        # Energy in kWh: (Watts * bin_width_seconds) / (3600 sec/hr * 1000 W/kW)
        bin_kwh = (avg_w * bw) / 3600000
        running_cost += (bin_kwh * 0.25)
        
        cmd = "date -d @" b " +\"%Y-%m-%dT%H:%M:%S\""
        cmd | getline t; close(cmd)
        print t, avg_w, running_cost
    }
}' "$FILE" > "$TMP_DATA"

SPAN_LABEL=${SPAN:-whole file}

# --- Gnuplot Execution ---
# "nofeed" stops gnuplot from replacing overlapping elements with '#'
if [[ "$MODE" == "both" ]]; then
    gnuplot -e "
        set xdata time;
        set timefmt '%Y-%m-%dT%H:%M:%S';
        set title 'Energy Usage: $SPAN_LABEL ($FILE)';
        set xlabel 'Time';
        set ylabel '$ Cumulative';
        set key outside bottom center horizontal;
        set y2label '* (Watts/Power)';
        set term dumb size $TERM_WIDTH,$TERM_HEIGHT ansi;
        set ytics nomirror;
        set y2tics;
        set key outside top center horizontal;
        plot '$TMP_DATA' using 1:3 with points pt '$' title 'Cost ($)', \
             '' using 1:2 axis x1y2 with lines title 'Power (*)'
    "
elif [[ "$MODE" == "cost" ]]; then
    gnuplot -e "
        set xdata time;
        set timefmt '%Y-%m-%dT%H:%M:%S';
        set title 'Cumulative Cost: $SPAN_LABEL ($FILE)';
        set xlabel 'Time';
        set ylabel '$ Cumulative';
        set term dumb size $TERM_WIDTH,$TERM_HEIGHT ansi;
        set key outside top center horizontal;
        plot '$TMP_DATA' using 1:3 with lines title 'Cost ($)'
    "
elif [[ "$MODE" == "power" ]]; then
    gnuplot -e "
        set xdata time;
        set timefmt '%Y-%m-%dT%H:%M:%S';
        set title 'Power over Time: $SPAN_LABEL ($FILE)';
        set xlabel 'Time';
        set ylabel '* (Watts)';
        set term dumb size $TERM_WIDTH,$TERM_HEIGHT ansi;
        set key outside top center horizontal;
        plot '$TMP_DATA' using 1:2 with lines title 'Power (*) avg'
    "
fi

rm "$TMP_DATA"

