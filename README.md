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
- **Visualization**: Generates ASCII plots of power over time directly in the terminal using `gnuplot`.
- **Advanced Analysis**: Calculates average wattage across multiple windows: All Time, Last Hour, Last 10 Minutes, Last Day, Last Week, Month to Date (MTD), and Year to Date (YTD).

## Prerequisites
Ensure the following tools are installed on your system:
- `curl` - To fetch data from the API.
- `jq` - To parse JSON responses.
- `gnuplot` - For generating terminal plots.
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
To see a terminal-based line graph of the power consumption over time:
```bash
bin/pm-plot [/path/to/your/logfile]
```
*(Defaults to `/var/log/pm/pm.log` if no argument is provided)*

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
- `bin/pm-plot`: Bash script using `gnuplot` to render ASCII line charts.
- `bin/pm-watch`: A wrapper that uses `watch` to refresh the plot automatically.
- `bin/pm-stats`: Python engine for calculating statistical averages across various time windows with visual bar trends.
```
