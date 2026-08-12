# Energy Monitor

A lightweight monitoring system to track real-time power consumption from a smart plug via an API, log the data, and provide tools for analysis and visualization.

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
   Open `energy-monitor.service` and ensure the `ExecStart` path matches the actual absolute path of your `energy-monitor.sh` script on your machine.
3. **Run the Install Script**: 
   This will configure the systemd service, reload the daemon, and start monitoring. This requires `sudo` privileges.
   ```bash
   chmod +x *.sh
   ./energy-monitor-install.sh
   ```

## Usage

### 1. Monitoring (Background Service)
The monitoring script runs automatically as a background service configured to restart on failure.
```bash
# Check service status
systemctl status energy-monitor.service

# View real-time logs
tail -f /var/log/energy-monitor/energy-monitor.log
```

### 2. Plotting Data (One-off)
To see a terminal-based line graph of the power consumption over time:
```bash
./energy-monitor-plot.sh [/path/to/your/logfile]
```
*(Defaults to `/var/log/energy-monitor/energy-monitor.log` if no argument is provided)*

### 3. Watching Data (Live Update)
To run the plot in a loop, updating every 10 seconds:
```bash
$ ./watch-plot.sh

                                               Cost ($)    $   Power (*) +-----+                                                    
                                                                                                                                    
                               Energy Usage: month (/var/log/energy-monitor/energy-monitor.log)                                     
     18 +--------------------------------------------------------------------------------------------------------------+ 170        
        |                     +                     +                      +                     +             +  $$$  |            
     16 |-+                                                                                                   $|$$+  +-| 160        
        |                                                                                                 $$$$ |  |    |            
        |                                                                                            $$$+$     |  |  +-| 150        
     14 |-+                                       +                                              $$$$   |      |  ||   |            
        |                                         |                                         $$$$$       |     ||  ||   |            
     12 |-+                                       |                                     $$$$   +        |     ||  |+ +-| 140        
        |                                         ||                               $$$$$       |        ||    ||  ||   |            
        |                           +             ||  +                       $$$$$      +     |     +  ||    + | || +-| 130        
     10 |-+                         |             ||  |                   $$$$           |     |     |  ||    | || |   |            
        |              +      +    || +           |+  |           + $$$$$$               |     |     |  |+    | || | * (Watts/Power)
      8 |-+        +   |      | +  +| |           ||  |         $$|$                  +  |     |     || ||    | || |   |            
        |          |   |      | |  || |           ||  |  $$$$$$$  |                   |  |    | |    ||| |  + | ||  |+-| 110        
        |          |  ||    +|| |  | ||         +| | ||$$$        ||                  | | |+  | | + | || |  | | ||  +  |            
      6 |-+        |  +|    || || |  ||         ||$|$| | +        ||                 || | ||  | | | | +| |  ||  ||  |+-| 100        
        |          |  ||    |+ || +  | |    +$$$||  || | |        ||     +           +| | ||| | | ||| ||  ||||  ||  |  |            
      4 |-+         | || +  |  || |  | |$+$$|  |||  |+ | |        |+     | ++     +  | |+ ||+ + | |+| ||  || |  ++  |  |            
        |           || + |||   +| |$$|$| |  || + |  || | |        || +  + |||  +  +  | || ||| | || |+  |  |+ |      |+-| 90         
        |           ||  + +|  $$||$  + | ||| + | |  |  ||+  +     | ||+ | |  |+ +| ||  || ++ |  +| ||  |  || |      +  |            
      2 |-+         |+   $$|$$  +|     +| ||  |  |  +  +| + ||  + | +  +  +  +   + ++  |     +   + +   +  +  +       +-| 80         
        |           +$$$$  +  +  +      + ++  +  +  +   +  + +++ ++        +           +         +                     |            
      0 +--------------------------------------------------------------------------------------------------------------+ 70         
      07/09                 07/16                 07/23                  07/30                 08/06                 08/13          
```                                                             Time                                                                   

### 4. Analyzing Averages
Run the Python analysis engine to generate statistical reports for a specific log file:
```bash
# Uses default /var/log/energy-monitor/energy-monitor.log if no argument is provided
python3 power-avg.py [/path/to/your/logfile]
```

## File Descriptions
- `energy-monitor.sh`: The core script that polls the API and writes CSV data to a log file.
- `energy-monitor.service`: Systemd unit file for persistent background execution.
- `energy-monitor-install.sh`: Helper script to automate service installation and setup.
- `energy-monitor-plot.sh`: Bash script using `gnuplot` to render ASCII line charts.
- `watch-plot.sh`: A wrapper that uses `watch` to refresh the plot automatically.
- `power-avg.py`: Python engine for calculating statistical averages across various time windows.
