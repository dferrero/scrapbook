Title: Transmission
Date: 2017-08-17 10:46
Modified:
Slugs: transmission 
Authors: Dave F 
Tags: transmission, torrent, magnet 

# Installation

`sudo apt-get install transmission-cli transmission-common transmission-daemon`

# Customization

Create folders where we are going to download all files.

Modify an existing user to have permissions on transmission folders:

`sudo usermod -a -G debian-transmission <username>`

Update folder permissions:

```
sudo chgrp -R debian-transmission <folder-path>
sudo chmod -R 775 <folder-path>
```

Once we finish all configuration changes, we reload the demon to apply them:

`sudo service transmission-daemon reload`

# Configuration

```
{
    "alt-speed-down": 50,
    "alt-speed-enabled": false,
    "alt-speed-time-begin": 540,
    "alt-speed-time-day": 127,
    "alt-speed-time-enabled": false,
    "alt-speed-time-end": 1020,
    "alt-speed-up": 50,
    "bind-address-ipv4": "0.0.0.0",
    "bind-address-ipv6": "::",
    "blocklist-enabled": false,
    "blocklist-url": "http://www.example.com/blocklist",
    "cache-size-mb": 4,
    "dht-enabled": true,
    "download-dir": "<CHANGE-ME>",
    "download-limit": 100,
    "download-limit-enabled": 0,
    "download-queue-enabled": true,
    "download-queue-size": 6,
    "encryption": 1,
    "idle-seeding-limit": 30,
    "idle-seeding-limit-enabled": false,
    "incomplete-dir": "<CHANGE-ME>",
    "incomplete-dir-enabled": true,
    "lpd-enabled": false,
    "max-peers-global": 200,
    "message-level": 1,
    "peer-congestion-algorithm": "",
    "peer-id-ttl-hours": 6,
    "peer-limit-global": 200,
    "peer-limit-per-torrent": 50,
    "peer-port": 51413,
    "peer-port-random-high": 65535,
    "peer-port-random-low": 49152,
    "peer-port-random-on-start": false,
    "peer-socket-tos": "default",
    "pex-enabled": true,
    "port-forwarding-enabled": false,
    "preallocation": 1,
    "prefetch-enabled": 1,
    "queue-stalled-enabled": true,
    "queue-stalled-minutes": 30,
    "ratio-limit": 2,
    "ratio-limit-enabled": false,
    "rename-partial-files": true,
    "rpc-authentication-required": true,
    "rpc-bind-address": "0.0.0.0",
    "rpc-enabled": true,
    "rpc-password": "<PASSWORD>",
    "rpc-port": 8997,
    "rpc-url": "/transmission/",
    "rpc-username": "<CHANGE-ME>",
    "rpc-whitelist": "<CHANGE-ME>",
    "rpc-whitelist-enabled": true,
    "scrape-paused-torrents-enabled": true,
    "script-torrent-done-enabled": false,
    "script-torrent-done-filename": "",
    "seed-queue-enabled": false,
    "seed-queue-size": 10,
    "speed-limit-down": 300,
    "speed-limit-down-enabled": false,
    "speed-limit-up": 100,
    "speed-limit-up-enabled": false,
    "start-added-torrents": true,
    "trash-original-torrent-files": false,
    "umask": 2,
    "upload-limit": 100,
    "upload-limit-enabled": 0,
    "upload-slots-per-torrent": 14,
    "utp-enabled": true
}
```

# Notes

* Every time server is rebooted, it's necessary to perform `/etc/init.d/transmission-daemon reload` to reload configuratión. Otherwise, Transmission starts with default configuration (it's a bug which it's still open).
