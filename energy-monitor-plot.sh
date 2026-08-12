#!/bin/bash

### How it works
### 
### * No `--span` → whole file, default 5 min bins.
### * With a span (e.g., --span=day) the end is `now`, start is computed with GNU `date`:
###   * hour  = now - 1 hour
###   * day   = now - 1 day
###   * week  = now - 1 week
###   * month = now - 1 month
###   * ytd   = 1 Jan of current year 00:00
### * `BIN_WIDTH = DURATION / 120` with a 30 s floor.
### 

DEFAULT_LOG="/var/log/energy-monitor/energy-monitor.log"

# --- Argument Parsing ---
FILE="$DEFAULT_LOG"
SPAN=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --span=*) # Matches --span=day, --span=hour, etc.
            SPAN="${1#*=}"
            shift
            ;;
        --span)   # Matches --span day (with a space)
            if [ -n "$2" ] && [[ "$2" != --* ]]; then
                SPAN="$2"
                shift 2
            else
                echo "Error: --span requires an argument (hour, day, week, month, ytd)"
                exit 1
            fi
            ;;
        -h|--help)
            echo "Usage: $0 [--span=<interval>] [logfile]"
            echo "Intervals: hour, day, week, month, ytd"
            exit 0
            ;;
        -*) # Error on unknown flags
            echo "Error: Unknown option $1"
            exit 1
            ;;
        *) # Positional argument is treated as the log file
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

START_EPOCH=""
END_EPOCH=""
BIN_WIDTH=300          # default 5 min for a free run

if [ -n "$SPAN" ]; then
    END_EPOCH=$(date +%s)
    case "${SPAN,,}" in
        hour)          START_EPOCH=$(date -d "1 hour ago" +%s) ;;
        day)           START_EPOCH=$(date -d "1 day ago"  +%s) ;;
        week)         START_EPOCH=$(date -d "1 week ago"  +%s) ;;
        month)        START_EPOCH=$(date -d "1 month ago" +%s) ;;
        ytd|year-to-date) START_EPOCH=$(date -d "$(date +%Y)-01-01 00:00:00" +%s) ;;
        *) echo "Error: Span must be one of hour, day, week, month, ytd"; exit 1 ;;
    esac

    DURATION=$(( END_EPOCH - START_EPOCH ))
    TARGET_BINS=120
    BIN_WIDTH=$(( DURATION / TARGET_BINS ))
    [ $BIN_WIDTH -lt 30 ] && BIN_WIDTH=30
fi

TMP_DATA=$(mktemp)

awk -F, -v start="$START_EPOCH" -v end="$END_EPOCH" -v bw="$BIN_WIDTH" '
BEGIN{ OFS=" " }
{
    dt = substr($1, 1, 19);
    gsub(/[-T:]/, " ", dt);
    epoch = mktime(dt);
    if(start!="" && (epoch < start || epoch >= end)) next
    bin=int(epoch/bw)*bw
    sum[bin]+=$3; cnt[bin]++
}
END{
    n=asorti(sum,keys)
    for(i=1;i<=n;i++){
        b=keys[i]
        avg=sum[b]/cnt[b]
        cmd="date -d @" b " +\"%Y-%m-%dT%H:%M:%S\""
        cmd | getline t; close(cmd)
        print t, avg
    }
}
' "$FILE" > "$TMP_DATA"

SPAN_LABEL=${SPAN:-whole file}
gnuplot -e "
set xdata time;
set timefmt '%Y-%m-%dT%H:%M:%S';
set title 'Power over Time - binned avg, bin=${BIN_WIDTH}s, span=$SPAN_LABEL ($FILE)';
set xlabel 'Time';
set ylabel 'Watts';
set term dumb size 132,24;
plot '$TMP_DATA' using 1:2 with lines title 'Power (W) avg'
"

rm "$TMP_DATA"
