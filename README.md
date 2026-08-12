# pm - Power Monitor

A lightweight monitoring system to track real-time power consumption from a smart plug via an API, log the data, and provide tools for analysis and visualization.

## Sample Output
```bash
klotz@tensor:~/wip/energy-monitor🦶$ ./bin/pm-plot
                                                 Cost ($)    $   Power (*) +-----+                                                  
                                                                                                                                    
                                           Energy Usage: whole file (/var/log/pm/pm.log)                                            
     0.008 +-----------------------------------------------------------------------------------------------------------+ 500        
           |       +        +    +-++       +-++     +       +       +       +        +  + +-++       +    +   $$$     |            
           |                    +  |        |  |                                         |    +           +|$$       +-| 450        
     0.007 |-+                  |  |        |  |                                         |    |          + |           |            
           |                    |  |       |   |                                         |    |     $$$ $| |           |            
     0.006 |-+                  |  |       |   |                                         |    |$ $$      | |         +-| 400        
           |                    |  |       +   |                                         |   $|          | |           |            
           |                   |   |       |   |                                        |  $  |          | |         +-| 350        
     0.005 |-+                 |    |      |    |                                       | $   |          |  |          |            
           |                   |    |      |    |                                       |$     |         |  |          |            
           |                   |    |     |     |                                 $$$ $$|      |         |  |        +-| 300        
     0.004 |-+                 |    |     |     |                    $ $ $ $$$ $$       |      |         |  |        * (Watts/Power)
           |                   |    |     |     |         $$ $$ $$$ $                   |      |         |  |        +-| 250        
           |                   |    |     |     | $$ $ $ $                              |      |        |   |          |            
     0.003 |-+                 |    |     |   $$|                                       |      |        |   |          |            
           |                   |    ++    | $   +                                       |      +-+      |   ++       +-| 200        
     0.002 |-+                 |     |    |$    |                                       |        |      |    |         |            
           |                  |      $|$$$|      |                                     |         |      |     |      +-| 150        
           |                  |    $$ |  |       |                                     |          |     |     |        |            
     0.001 |-+                |  $    |  |       |                       +             |          |     |     |        |            
           |                  | $      | |        |                     + +            |          |     |      |     +-| 100        
           |      ++-+++-++-+++     +  +++  +     ++-+-+-+++-++-+++-++-+   +++-++-+++-++      +   +-+++-+      +++     |            
         0 +-----------------------------------------------------------------------------------------------------------+ 50         
         10:00   11:00    12:00   13:00   14:00    15:00   16:00   17:00   18:00    19:00   20:00   21:00    22:00   23:00          
                                                               Time                                                                 
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
