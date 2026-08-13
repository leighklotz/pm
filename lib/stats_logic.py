#!/usr/bin/env python3
import csv
import sys
import glob
from datetime import datetime, timedelta
from statistics import mean

# Default file path if no arguments are provided
DEFAULT_LOG_BASE = "/var/log/pm/pm.log"

def parse_timestamp(ts_raw):
    """Helper to handle various timestamp formats robustly."""
    try:
        # Handle ISO format (2023-10-01T12:00:00Z)
        return datetime.fromisoformat(ts_raw.replace('Z', '+00:00'))
    except ValueError:
        try:
            # Try fallback formats
            for fmt in ('%Y-%m-%d %H:%M:%S', '%Y/%m/%d %H:%M:%S'):
                try:
                    return datetime.strptime(ts_raw, fmt)
                except ValueError:
                    continue
        except Exception:
            pass
    return None

def load_data(file_paths):
    """Reads multiple files and returns a single sorted list of data points."""
    combined_data = []
    for file_path in file_paths:
        try:
            with open(file_path, mode='r', encoding='utf-8') as f:
                reader = csv.reader(f)
                for row in reader:
                    if not row or len(row) < 3:
                        continue

                    ts = parse_timestamp(row[0])
                    try:
                        power_val = float(row[2])
                    except (ValueError, IndexError):
                        continue

                    if ts:
                        combined_data.append({
                            'timestamp': ts,
                            'power_w': power_val
                        })
        except FileNotFoundError:
            print(f"Warning: {file_path} not found. Skipping...")
        except Exception as e:
            print(f"Error reading {file_path}: {e}")

    # Sort everything by timestamp to ensure timeline continuity across files
    combined_data.sort(key=lambda x: x['timestamp'])
    return combined_data

def analyze_energy(all_data, source_info):
    """Performs analysis on the aggregated dataset."""
    if not all_data:
        print("\nNo valid data found in any provided files.")
        return

    last_time = all_data[-1]['timestamp']
    first_ts = all_data[0]['timestamp']

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

    print(f"\n--- Statistics ({source_info}) ---")
    avg_all = safe_mean([d['power_w'] for d in all_data])
    print(f"Global Baseline:          {avg_all:.2f} W\n")

    plot_results = []
    for label, threshold in metrics:
        if threshold <= first_ts:
            continue # Skip if the metric period is older than our logs start date

        period_power = [d['power_w'] for d in all_data if d['timestamp'] >= threshold]
        avg_val = safe_mean(period_power)
        plot_results.append((label, avg_val))

    if not plot_results:
        print("No period-specific metrics available (logs may be too short).")
    else:
        # --- ASCII BAR PLOT LOGIC ---
        max_val = max([r[1] for r in plot_results] + [avg_all])
        bar_width = 60

        print(f"{'Metric':<28} | {'Visual Trend (Scaled)':<{bar_width}} | Value")
        print("-" * (31 + bar_width + 15))

        for label, val in plot_results:
            scaled_len = int((val / max_val) * bar_width) if max_val > 0 else 0
            bar = "█" * scaled_len
            print(f"{label:<28} | {bar:<{bar_width}} | {val:>7.2f} W")

    print()
    print(f"Data Range:  {first_ts} to {last_time}")
    print(f"Total Records Analyzed: {len(all_data)}")

if __name__ == "__main__":
   # DECISION LOGIC:
   # If user provided arguments, use exactly those files.
   # If no args, look for pm.log AND all rotated versions (pm.log.1, etc.)
   if len(sys.argv) > 1:
       files_to_process = sys.argv[1:]
       source_label = f"Specific Files ({', '.join(files_to_process)})"
   else:
       # This is the "Fix": Use glob to find pm.log, pm.log.1, pm.log.2...
       pattern = DEFAULT_LOG_BASE + "*"
       files_to_process = sorted(glob.glob(pattern))
       source_label = f"All logs matching {DEFAULT_LOG_BASE}*"

   data = load_data(files_to_process)
   analyze_energy(data, source_label)
