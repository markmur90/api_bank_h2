#!/bin/bash
# UFW ALLOW

sudo ufw default allow incoming
sudo ufw default allow outgoing
sudo ufw logging full
sudo ufw enable



sudo systemctl daemon-reload