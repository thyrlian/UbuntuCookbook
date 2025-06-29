## Ref

* [Product Page](https://www.clockworkpi.com/uconsole)
* [Code Repo](https://github.com/clockworkpi/uConsole)
* [QMK firmware for uConsole keyboard](https://forum.clockworkpi.com/t/qmk-firmware-for-uconsole-keyboard/14410)

## Setup

### Network

#### Unblock Wi-Fi and Set WLAN Country

You might see the following message after the first boot:
```bash
Wi-Fi is currently blocked by rfkill.
Use raspi-config to set the country before use.
```

Run the following commands to properly configure Wi-Fi:
```bash
rfkill list
sudo rfkill unblock all

sudo raspi-config
# Navigate to: Localisation Options → WLAN Country → select your country
# If the down arrow key doesn’t respond, press Fn + PgDn first, then use the up arrow to navigate.

# Verify that the country code was set correctly
iw reg get

# Reboot the system for the changes to take effect
sudo reboot
```

#### Connect to Wi-Fi

```bash
# Check if the WLAN interface is available
nmcli device status

# List nearby Wi-Fi networks
nmcli device wifi list

# Connect to your target Wi-Fi (replace with actual SSID and password)
nmcli device wifi connect "YourWiFiSSID" password "YourPassword"

# Verify the connection status
nmcli connection show
nmcli connection show --active
nmcli device status

# If disconnected, reconnect using the saved profile
nmcli connection up id "YourWiFiSSID"
```

### Update System Packages

```bash
sudo apt update && sudo apt upgrade -y
```

### Enable SSH Access

```bash
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh

# (Optional) Enhance security by enabling a basic firewall
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable
```
