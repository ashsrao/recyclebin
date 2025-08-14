.
├── README.md
├── utkarai_cert.pem - Certificate used by the utkarai.py HTTPS server. This is self-signed. 
├── utkarai.config   - config file used by the utkarai.cron and utkarai_helper
├── utkarai.cron     - The cron job that periodically updates the IP address of vmegh.
├── utkarai_helper   - The script that is executed when the user presses the button
├── utkarai_key.pem  - The private key used by the utkarai.py HTTPs server. This is self-signed.
├── utkarai.py       - The HTTPS webserve that executes the helper script when the user presses a button.
└── utkarai.service  - The systemd service config to run the HTTPs server. 


The utkarai consists of three modules
1. The HTTPs webserver
2. The cron job that refreshes the dns to IP mapping
3. The helper script that is executed by the HTTPs webserver
