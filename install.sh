#!/bin/bash -x

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE}")")"

cd ${SCRIPT_DIR}

sudo cp energy-monitor.service /etc/systemd/system/energy-monitor.service
sudo systemctl daemon-reload
sudo systemctl enable energy-monitor.service
sudo systemctl start energy-monitor.service
sudo systemctl status energy-monitor.service

tail /var/log/energy-monitor/energy-monitor.log
