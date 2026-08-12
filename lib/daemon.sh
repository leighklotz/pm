#!/bin/bash
PLUG=plug4.klotz.me

# Keep the header aligned with the updated output format
echo timestamp,plug,power_w,voltage_v,current_a,energy_kwh

while true; do
    # Generate the ISO 8601 timestamp natively in Bash
    ts=$(date -Is)

    # Added --max-time 5 to prevent hanging and handled empty responses with // "0"
    p=$(curl -s --max-time 5 "$PLUG/sensor/Power" | jq -r '.value // 0')
    v=$(curl -s --max-time 5 "$PLUG/sensor/Voltage" | jq -r '.value // 0')
    c=$(curl -s --max-time 5 "$PLUG/sensor/Current" | jq -r '.value // 0')
    e=$(curl -s --max-time 5 "$PLUG/sensor/Total%20Daily%20Energy" | jq -r '.value // 0')
    
    printf '%s,%s,%s,%s,%s,%s\n' "$ts" "$PLUG" "$p" "$v" "$c" "$e"
    sleep 10
done
