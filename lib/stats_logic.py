#!/usr/bin/env python3
import csv
import sys
from datetime import datetime, timedelta
from statistics import mean

# Default file path if no arguments are provided
DEFAULT_FILE = "/var/log/pm/pm.log"

def analyze_energy(file_path):
    data = []
    
    try:
        with open(file_path, mode='r', encoding='utf-8') as f:
            reader = csv.reader(f)
            for row in reader:
                if not row or len(row) < 3:
                    continue
                try:
                    ts_raw = row[0].replace('Z', '+00:00')
                    power_val = float(row[2])
                except (ValueError, TypeError, IndexError):
                    continue

                try:
                    ts = datetime.fromisoformat(ts_raw)
                except ValueError:
                    ts_str = ts_raw.replace('T', ' ')
                    if len(ts_str) > 19 and ts_str[-6] == ':':
                        ts_str = ts_str[:-3] + ts_str[-2:]
                    try:
                        ts = datetime.fromisoformat(ts_str)
                    except ValueError:
                        try:
                            ts = datetime.strptime(row[0], '%Y-%m-%d %H:%M:%S')
                        except (ValueError, IndexError):
                            continue

                data.append({
                    'timestamp': ts,
                    'power_w': power_val
                })
    except FileNotFoundError:
        print(f"Error: {file_path} not found.")
        return
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return

    if not data:
        print(f"--- {file_path} ---")
        print("No valid data available.")
        return

    data.sort(key=lambda x: x['timestamp'])
    last_time = data[-1]['timestamp']
    first_ts = data[0]['timestamp']
    
    metrics = [
        ("Average Power (Last 10 Min)", last_time - timedelta(minutes=10)),
        ("Average Power (Last Hour)",   last_time - timedelta(hours=1)),
        ("Average Power (Last Day)",    last_time - timedelta(days=1)),
        ("Average Power (Last Week)",   last_time - timedelta(weeks=1)),
        ("Average Power (MTD)",         last_time.replace(day=1, hour=0, minute=0, second=0, microsecond=0)),
        ("Average Power (YTD)",         last_time.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0))
    ]

    def safe_mean(lst):
        return mean(lst) if lst else 0.0

    print(f"\n--- {file_path} ---")
    avg_all = safe_mean([d['power_w'] for d in data])
    print(f"Global Baseline:          {avg_all:.2f} W\n")

    # Collect results to calculate max for scaling the bar chart
    plot_results = []

    for label, threshold in metrics:
        if threshold <= first_ts:
            continue

        period_power = [d['power_w'] for d in data if d['timestamp'] >= threshold]
        avg_val = safe_mean(period_power)
        plot_results.append((label, avg_val))

    if not plot_results:
        print("No period-specific metrics available.")
        return

    # --- ASCII BAR PLOT LOGIC ---
    max_val = max([r[1] for r in plot_results] + [avg_all]) # Scale against highest value
    bar_width = 60  # Character width of the bar itself (to make it wide)
    
    print(f"{'Metric':<28} | {'Visual Trend (Scaled)':<{bar_width}} | Value")
    print("-" * (31 + bar_width + 15))

    for label, val in plot_results:
        # Calculate scaling factor for the bar width
        if max_val > 0:
            scaled_len = int((val / max_val) * bar_width)
        else:
            scaled_len = 0
            
        bar = "█" * scaled_len
        print(f"{label:<28} | {bar:<{bar_width}} | {val:>7.2f} W")

    print() # Spacer
    print(f"Data Range:  {data[0]['timestamp']} to {data[-1]['timestamp']}")
    print(f"Total Records: {len(data)}")

if __name__ == "__main__":
   files_to_process = sys.argv[1:] if len(sys.argv) > 1 else [DEFAULT_FILE]

   for arg in files_to_process:
       analyze_energy(arg)

