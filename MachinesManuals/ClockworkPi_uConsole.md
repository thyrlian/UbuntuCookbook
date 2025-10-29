## Ref

* [Product Page](https://www.clockworkpi.com/uconsole)
* [Code Repo](https://github.com/clockworkpi/uConsole)
* [QMK firmware for uConsole keyboard](https://forum.clockworkpi.com/t/qmk-firmware-for-uconsole-keyboard/14410)

## Setup

### Environment Variables

```console
nano ~/.bashrc
```

```bash
# ------------------------------------------------------------
# Add administrative system paths to user PATH
# Purpose: Ensure user sessions can access system utilities
# (e.g., /sbin/iw for wireless tools)
# ------------------------------------------------------------
if ! echo "$PATH" | grep -q "/sbin"; then
    export PATH="$PATH:/sbin:/usr/sbin"
fi
```

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

#### Enable SSH Access

```bash
# Update System Packages
sudo apt update && sudo apt upgrade -y

# Enable and start SSH service
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh

# (Optional) Enhance security by enabling a basic firewall
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable

# Set up passwordless key-based SSH login
mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys

# Append the client’s public key (e.g., ~/.ssh/id_rsa.pub) to the authorized_keys file created above

# Ensure PubkeyAuthentication is enabled
grep -qE '^\s*#?\s*PubkeyAuthentication\s+' /etc/ssh/sshd_config && \
  sudo sed -i 's/^\s*#\?\s*PubkeyAuthentication\s\+.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config || \
  echo -e '\n# Enable public key authentication\nPubkeyAuthentication yes' | sudo tee -a /etc/ssh/sshd_config

# Disable PasswordAuthentication for better security
grep -qE '^\s*#?\s*PasswordAuthentication\s+' /etc/ssh/sshd_config && \
  sudo sed -i 's/^\s*#\?\s*PasswordAuthentication\s\+.*/PasswordAuthentication no/' /etc/ssh/sshd_config || \
  echo -e '\n# Disable password login for security\nPasswordAuthentication no' | sudo tee -a /etc/ssh/sshd_config

# Restart the SSH service to apply the changes
sudo systemctl restart ssh

# (Optional) Limit SSH login rate to mitigate brute-force attacks
# This enhances security without disabling PasswordAuthentication, it simply throttles repeated failed attempts
sudo ufw limit ssh
```

### EEPROM

#### Update EEPROM Firmware

```bash
# Check current EEPROM version
vcgencmd version
vcgencmd bootloader_version

# Check for EEPROM bootloader update
sudo rpi-eeprom-update

# Apply update if available
sudo rpi-eeprom-update -a
sudo reboot
```

#### Update EEPROM Configuration

* **Step 1**: Backup current configuration
```bash
sudo mkdir -p /etc/rpi-eeprom-backup
sudo rpi-eeprom-config | sudo tee /etc/rpi-eeprom-backup/config-backup.txt > /dev/null
```

* **Step 2**: (Optional) View the backup
```bash
cat /etc/rpi-eeprom-backup/config-backup.txt

# Expected output:

[all]
BOOT_UART=1
# Default BOOT_ORDER for provisioning
# SD -> NVMe -> USB -> Network
BOOT_ORDER=0xf2461
```

* **Step 3**: Edit EEPROM configuration
```bash
sudo rpi-eeprom-config -e
```
In the editor, replace the full content with:
```bash
[all]
BOOT_UART=1

# Switch off PMIC outputs on HALT
POWER_OFF_ON_HALT=1

# Try boot on SDCard repeatedly
BOOT_ORDER=0xf1
SD_BOOT_MAX_RETRIES=2

# Slow down SDCard SDR Mode on bootloader
SD_QUIRKS=1
```

* **Step 4**: Hard shutdown and power cycle
```bash
sudo shutdown -h now
# Then physically disconnect power (and battery if needed), wait 10+ seconds, then power on
```

* **Step 5**: Verify changes applied
```bash
sudo rpi-eeprom-config
```

### Desktop Environment

#### Add and Configure XFCE

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install XFCE desktop environment and common components
sudo apt install xfce4 xfce4-goodies -y

# Install LightDM as the display manager (lightweight login screen for XFCE)
sudo apt install lightdm -y

# Set system to boot by default into graphical target (GUI) instead of multi-user target (text-only TTY)
sudo systemctl set-default graphical.target

# (Optional) Check the current default target
systemctl get-default
# Should return: graphical.target

# Reboot to launch the graphical interface
sudo reboot
```

#### Rotate Display for Login Screen and Desktop (Optional)

```bash
# Create LightDM config directory if it doesn't exist
sudo mkdir -p /usr/share/lightdm/lightdm.conf.d

# Check the actual display output name (e.g., DSI-1, DSI-2, HDMI-1, etc.)
xrandr --query

# Create a config file to rotate the screen before LightDM starts
# Replace 'DSI-1' below with the correct name shown as "connected" in the previous command
echo '[Seat:*]' | sudo tee /usr/share/lightdm/lightdm.conf.d/50-display-rotate.conf > /dev/null
echo 'display-setup-script=xrandr --output DSI-1 --rotate right' | sudo tee -a /usr/share/lightdm/lightdm.conf.d/50-display-rotate.conf > /dev/null

# Reboot to apply the change
sudo reboot
```

#### Display System Tray Icons for WiFi and Bluetooth

* WiFi

```bash
# Install the Network Manager applet
sudo apt update
sudo apt install network-manager-gnome -y

# (Optional) Run it immediately
nm-applet &

# Set it to auto-start on login
mkdir -p ~/.config/autostart

cat <<EOF > ~/.config/autostart/nm-applet.desktop
[Desktop Entry]
Type=Application
Exec=nm-applet
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Network Manager Applet
Comment=Show WiFi status in system tray
EOF
```

* Bluetooth

```bash
# Install the Bluetooth manager
sudo apt update
sudo apt install blueman -y

# (Optional) Run it immediately
blueman-applet &

# Set it to auto-start on login
mkdir -p ~/.config/autostart

cat <<EOF > ~/.config/autostart/blueman-applet.desktop
[Desktop Entry]
Type=Application
Exec=blueman-applet
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Bluetooth Manager Applet
Comment=Show Bluetooth status in system tray
EOF
```

### Language

#### Add Chinese language support

```bash
# Install locale management tools
sudo apt update
sudo apt install locales -y

# Interactively enable zh_CN.UTF-8
sudo dpkg-reconfigure locales

# Verify that zh_CN.UTF-8 is now available
locale -a | grep zh_CN
# Expected output:
zh_CN.utf8
```

### Keyboard

#### Check and Configure Keyboard Settings

```bash
sudo raspi-config

# Navigate to: Localisation Options → Keyboard
# Choose the following values for each prompt:
# Keyboard model → Generic 105-key PC
# Keyboard layout → English (US)
# Key to function as AltGr → The default for the keyboard layout
# Compose key → No compose key

# Check and validate locale settings
localectl status
```

#### Trackball

The trackball module (Clockwork uConsole Keyboard Mouse) registers a **press-down** as a **middle click**.  Use the **L** and **R** buttons next to the arrow keys to perform **left** and **right mouse clicks** respectively.

### Battery

#### Check Battery/Charging Status

```bash
# Check battery status (capacity, charge state, voltage, and health)
clear
echo "[Battery Info]"
echo "Battery: $(cat /sys/class/power_supply/axp20x-battery/capacity)%"
echo "Status : $(cat /sys/class/power_supply/axp20x-battery/status)"
echo "Voltage: $(awk '{printf "%.2f", $1 / 1000000}' /sys/class/power_supply/axp20x-battery/voltage_now) V"
echo "Health : $(cat /sys/class/power_supply/axp20x-battery/health)"
```

### Miscellaneous

#### Optimize Filesystem Write Behavior (Optional)

Improve system stability during **sudden power loss** or **low-battery situations** by increasing the commit interval (i.e., how frequently ext4 journal commits data to disk).

This is especially important for systems using microSD storage (e.g. Raspberry Pi Compute Module Lite), which are more vulnerable to corruption compared to Compute Module with eMMC that often include better hardware-level caching and power-loss protection.

```bash
# Backup original fstab
sudo cp /etc/fstab /etc/fstab.bak

# Add `commit=30` to the root (/) ext4 mount options if not already present
sudo sed -i '/^[^#].*\s\/\s\+ext4/ {
  /commit=30/! s/\<defaults\>\([^,]*\)\(,[^ ]*\)*/defaults\1\2,commit=30/
}' /etc/fstab

# Reboot to apply changes
sudo reboot

# Verify that the parameter has taken effect
mount | grep " on / "
```

#### Add App Distribution Platform: Flatpak (Optional)

```bash
# Install Flatpak
sudo apt update && sudo apt install flatpak -y

# (Optional) Install plugin to integrate Flatpak with graphical software manager (GNOME Software)
sudo apt install gnome-software-plugin-flatpak -y

# Add the Flathub repository (the main source of Flatpak apps)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Reboot to apply environment changes
sudo reboot

# Example: Install Chromium browser
# !!!Note: Chromium installed via Flatpak does NOT support Widevine DRM due to sandboxing restrictions, so Netflix and other DRM-protected content will NOT play.
flatpak install flathub org.chromium.Chromium
# Check current Flatpak permissions for Chromium
flatpak info --show-permissions org.chromium.Chromium
# Add read-only access to common font directories
flatpak override --user org.chromium.Chromium \
  --filesystem=/usr/share/fonts:ro \
  --filesystem=/usr/local/share/fonts:ro \
  --filesystem=~/.fonts:ro
# Set environment variable to use Chinese locale
flatpak override --user org.chromium.Chromium --env=LANG=zh_CN.UTF-8

# Tip: Some apps may not appear in Application Finder until after a reboot or logout/login
```

### Hardware

#### Enhance Wireless Connection

The built-in Wi-Fi module (Broadcom chipset with the antenna) delivers rather weak signal performance.  Therefore, it is highly recommended to keep a compact USB Wi-Fi adapter permanently connected to improve wireless stability and range.  After extensive testing, the [TP-Link Archer T2U Nano AC600 Nano Wireless USB Adapter](https://www.tp-link.com/en/home-networking/adapter/archer-t2u-nano/) has proven to be a reliable and effective choice for this purpose.

The setup process is outlined below.

```console
# --- Identify the USB Wi-Fi Adapter ---
# Check that the system recognizes the adapter and confirm the chipset.
lsusb
# => Bus xxx Device xxx: ID xxxx:xxxx TP-Link AC600 wireless Realtek RTL8811AU [Archer T2U Nano]

# --- Check the Current Kernel Version ---
# Needed to link the correct kernel headers.
uname -r
# => kernel version (e.g., 6.12.55-v8-16k+)

# --- Link Kernel Headers for DKMS Compilation ---
# Ensure both 'build' and 'source' symlinks are correctly pointing to the headers.
KVER=$(uname -r)
sudo mkdir -p /lib/modules/${KVER}/{build,source}
sudo ln -sf /usr/src/linux-headers-${KVER} /lib/modules/${KVER}/build
sudo ln -sf /usr/src/linux-headers-${KVER} /lib/modules/${KVER}/source
ls -l /lib/modules/${KVER}/build
ls -l /lib/modules/${KVER}/source

# --- Install Required Build Dependencies ---
# 'dkms' for dynamic kernel module support
# 'build-essential' for compiler tools
# 'git' to clone the driver repo
# 'bc' for math expressions
sudo apt update
sudo apt install -y dkms build-essential git bc

# --- Download and Build the Driver ---
mkdir -p ~/Drivers
cd ~/Drivers
git clone https://github.com/morrownr/8821au-20210708 8821au
cd 8821au
sudo ./install-driver.sh
# This will automatically build and install the DKMS module.
# The installed driver options file is stored here: /etc/modprobe.d/8821au.conf

# --- Verify and Set the Wireless Regulatory Domain ---
# Check the current region configuration.
# If the global regulatory domain is already set to 'DE', no action is needed.
iw reg get
# Otherwise, run the following command to set it manually:
sudo iw reg set DE

# --- Check Adapter Availability ---
# Verify that wlan1 (the external adapter) is recognized and active.
# You can configure it via 'iwconfig' or through the graphical Wi-Fi UI.
iwconfig wlan1

# --- Prioritize External Wi-Fi Adapter Globally ---
# Create a dispatcher script to automatically set route priorities when interfaces go up.
sudo nano /etc/NetworkManager/dispatcher.d/10-wifi-metric.sh

# -------------------------------------------------- #
#!/bin/bash
# 10-wifi-metric.sh
# Purpose: Always prefer the external USB Wi-Fi adapter (wlan1) over the internal Wi-Fi (wlan0)
# This script runs automatically when NetworkManager brings an interface up or down.

interface=$1
action=$2

case "$action" in
    up)
        if [ "$interface" = "wlan1" ]; then
            # External USB Wi-Fi: set a lower route metric (higher priority)
            nmcli device modify wlan1 ipv4.route-metric 10 ipv6.route-metric 10
        elif [ "$interface" = "wlan0" ]; then
            # Internal Wi-Fi: set a higher route metric (lower priority)
            nmcli device modify wlan0 ipv4.route-metric 20 ipv6.route-metric 20
        fi
        ;;
esac
# -------------------------------------------------- #

# Make the script executable
sudo chmod +x /etc/NetworkManager/dispatcher.d/10-wifi-metric.sh
# Restart NetworkManager to apply changes
sudo systemctl restart NetworkManager
# Verify route priority
# wlan1 should have metric=10 and wlan0 metric=20.
ip route

# --- Reboot to take effect ---
sudo reboot
```

## Known Issues

* Static noise when battery is low (CM5-specific)

  When the battery level gets low, you may hear noticeable static or background noise from the speaker.  This issue is specific to Raspberry Pi CM5, because uConsole’s onboard audio is generated via PWM (Pulse Width Modulation) rather than using a dedicated DAC.  On the CM5, when under heavy load or low battery conditions, its power management module can exhibit minor voltage fluctuations.  These fluctuations affect the PWM signal stability, causing noise artifacts to appear in the audio output.
