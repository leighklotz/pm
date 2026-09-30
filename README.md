# pm - Power Monitor

A lightweight monitoring system to track real-time power consumption from a smart plug via an API, log the data, and provide tools for analysis and visualization.

## Sample Output
```
klotz@tensor:~/wip/pm👣$ ./bin/pm-plot --span=month > example.txt
Energy Usage: month (/var/log/pm/pm.log*)                                                
     16 +--------------------------------------------------------------------------------------------------------------+ 200
        | |                         +                           +                          +                           |
        | |                                                                                                      $ $   |
     14 |-|                                                                                                 $ $      +-| 180
        |  |                                                                                          $ $ $            |
     12 |-+|                                                                                    $ $ $                  |
        |  |                                                                                $ $                      +-| 160
        |  |                                                                          $ $ $                            |
     10 |-+|                                                                    $ $ $                                  |
        |  |                                                                $ $                                      +-| 140
        |  |                                                         $  $ $                                            |
      8 |-+|                                                   $ $ $                                                 * (Watts/Power)
        |   |                +                       +   $ $ $                                                         |
        |   |           +   +|                       | $                                                             +-| 120
      6 |-+ |           |+ +  |                $ $ $| |                                                                |
        |   |          |  +   |          + $ $      | |                                         +                      |
      4 |-+ +       +  |      |  +   $ $ ||         |  |                            +          | |                   +-| 100
        |    -+    + | |      |$|$+$-+  | |        |   +                            ||  +   +  | |          +    +-+   |
        |      -+-+  ||   $  $ ||  +  + |  |-+   +-+    -+-+-+-+  -+               | | + + + -+   |-+  -+  + + --      |
      2 |-+         $ + $      +       +   +  + +               -+  -+--+  -+-+-+  |  +   +       +  -+  -+   +      +-| 80
        |       $ $                            +                         -+      -+                                    |
        | $ $ $                     +                           +                          +                           |
      0 +--------------------------------------------------------------------------------------------------------------+ 60
      09/03                       09/10                       09/17                      09/24                       10/01
                                                             Time
                                               Cost ($)    $   Power (*) +-----+
                                                                                                                                    
```


## Features
- **Automated Logging**: Runs as a `systemd` service to capture power metrics (Power, Voltage, Current, Total Energy) every 10 seconds in CSV format.
- **Visualization**: Generates terminal ASCII plots of average power and cumulative electricity cost using `gnuplot`. Reads the complete rotated-log history, including gzip-compressed logs, and preserves visible gaps in recorded data.
- **Advanced Analysis**: Calculates average wattage across multiple windows: All Time, Last Hour, Last 10 Minutes, Last Day, Last Week, Month to Date (MTD), and Year to Date (YTD).

## Prerequisites
Ensure the following tools are installed on your system:
- `curl` - To fetch data from the API.
- `jq` - To parse JSON responses.
- `gnuplot` - For generating terminal plots.
- `gzip` - To read compressed rotated log files.
- GNU core utilities plus `find` and `awk` - Used by the Bash plotting tools.
- `python3` - For running analysis scripts.

## Installation

1. **Clone the repository** (or place these files in your desired directory).
2. **Configure the Service**: 
   Open `/etc/pm.service` and ensure the `ExecStart` path matches the actual absolute path of your `lib/daemon.sh` script on your machine.
3. **Run the Install Script**: 
   This will configure the systemd service, reload the daemon, and start monitoring. This requires `sudo` privileges.
   ```bash
   chmod +x install.sh bin/*
   ./install.sh
   ```


## Usage

### 1. Monitoring (Background Service)
The monitoring script runs automatically as a background service configured to restart on failure.
```bash
# Check service status
systemctl status pm.service

# View real-time logs
tail -f /var/log/pm/pm.log
```

### 2. Plotting Data (One-off)

`pm-plot` automatically reads all power-monitor logs in `/var/log/pm`,
including rotated and gzip-compressed logs such as:

- `pm.log`
- `pm.log.1`
- `pm.log.2`
- `pm.log.3.gz`

```bash
# Plot all available history
bin/pm-plot

# Limit the displayed time range
bin/pm-plot --span=hour
bin/pm-plot --span=day
bin/pm-plot --span=week
bin/pm-plot --span=month
bin/pm-plot --span=ytd

# Select plotted data
bin/pm-plot --cost
bin/pm-plot --power
bin/pm-plot --both
```

The default is `--both`.

Power samples are averaged into display bins. Cumulative cost is calculated
from the smart plug's cumulative `energy_kwh` meter rather than from the
display bins, so changing plot resolution does not change the calculated cost.

Large gaps in logging are shown as gaps in the power trace rather than being
interpolated across missing data. CSV header lines may occur anywhere in the
rotated logs and are ignored automatically.

### 3. Watching Data (Live Update)
To run the plot in a loop, updating every 10 seconds:
```bash
bin/pm-watch
```

### 4. Analyzing Averages
Run the statistical engine to generate reports for a specific log file:
```bash
# Uses default /var/log/pm/pm.log if no argument is provided
bin/pm-stats [/path/to/your/logfile]
```

## File Descriptions
- `lib/daemon.sh`: The core script that polls the API and writes CSV data to a log file.
- `/etc/pm.service`: Systemd unit file for persistent background execution.
- `./install.sh`: Helper script to automate service installation and setup.
- `bin/pm-plot`: Bash/gnuplot terminal plotter that reads plain and gzip-compressed rotated logs, plots binned power, and calculates cumulative cost from the plug's energy meter.
- `bin/pm-watch`: A wrapper that uses `watch` to refresh the plot automatically.
- `bin/pm-stats`: Python engine for calculating statistical averages across various time windows with visual bar trends.
```
