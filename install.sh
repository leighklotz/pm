#!/bin/bash -x

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE}")")"

cd ${SCRIPT_DIR}

sudo cp pm.service /etc/systemd/system/pm.service
sudo systemctl daemon-reload
sudo systemctl enable pm.service
sudo systemctl start pm.service
sudo systemctl status pm.service

tail /var/log/pm/pm.log
