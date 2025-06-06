




sudo mkdir -p /var/lib/tor/hidden_service
sudo chown -R debian-tor:debian-tor /var/lib/tor/hidden_service
sudo chmod 700 /var/lib/tor/hidden_service



sudo nano /etc/tor/torrc

  HiddenServiceDir /var/lib/tor/hidden_service
  HiddenServicePort 80 127.0.0.1:9180


sudo systemctl restart tor

sudo journalctl -xeu tor.service | tail -n 30

sudo pkill tor

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart tor
