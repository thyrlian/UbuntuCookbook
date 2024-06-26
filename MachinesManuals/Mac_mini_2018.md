**Mac mini** 2018 install **Ubuntu** 22.04.1 LTS

## Setup

* Disable [Secure Boot](https://support.apple.com/zh-cn/HT208198) on Mac with T2 Security Chip
* Prepare a bootable Ubuntu OS USB drive
* Hold **⌥** key and boot up Mac
* Choose the USB drive to boot from
* In the GRUB UI, select ”Try or Install Ubuntu”
* Erase disk and install
    * partition #1 of /dev/nvme0n1 as ESP
    * partition #2 of /dev/nvme0n1 as ext4
* Config and install
* Error on installation
    * Unable to install GRUB in /dev/nvme0n1
    * Executing ‘grub-install /dev/nvme0n1’ failed.
    * This is a fatal error.
* OK and restart (remove the installation medium, then press ENTER)
* Land in a grub terminal, and execute the following

    ```
    grub> ls
    #=> (proc) (hd0) (hd0,gpt2) (hd0,gpt1)
    # traverse the list, until you find your user's home directory
    grub> ls (hd0)/home
    #=> error: unknown filesystem.
    grub> ls (hd0,gpt1)/home
    #=> error: file '/home' not found.
    grub> ls (hd0,gpt2)/home
    #=> jli/
    
    # traverse all gpt* until you find the proper /boot/grub directory
    grub> ls (hd0,gpt2)/boot/grub
    #=> gfxblacklist.txt unicode.pf2 x86_64-efi/ locale/ fonts/ grubenv
    
    grub> set root=(hd0,gpt2)
    
    # get the UUID of the drive and use it to boot properly
    grub> ls -l (hd0,gpt2)
    #=> Partition hd0,gpt2: Filesystem type ext* ... UUID 5358198d-b34c-472a-9763-559b7fb80500 ...
    grub> linux /boot/vmlinuz-*.*.*-*-generic .efi.signed root=UUID=<UUID_from_above>
    # set the initial RAM disk
    grub> initrd /boot/initrd.img-*.*.*-*-generic
    
    # reboot
    grub> boot
    ```
* After reboot, you land in the Ubuntu Desktop, update the system (fix grub): `sudo update-grub`, then reboot
* In the Disks application, you should see a boot loader partition:
    * Contents: FAT (32-bit version) - Mounted at /boot/efi
    * Device: /dev/nvme0n1p1
    * Partition Type: EFI System
* Get WIFI working
    * [Broadcom BCM4364 802.11ac Wireless Network Adapter](https://linux-hardware.org/?id=pci:14e4-4464-106b-07bf)
    * Get the wireless adapter info in Ubuntu:
        * `lspci | grep -i broadcom`
        * `lshw -C network`
    * WIFI firmware is located on your MAC:
        * `/usr/share/firmware/wifi`
        * `C-4364__s-B2` or `C-4364__s-B3`
        * All trx files are in fact alias (e.g. kauai.trx), their original file is `ekans.trx` (for `C-4364__s-B2`) or `borneo.trx` (for `C-4364__s-B3`)
    * Copy firmware from macOS to Ubuntu: `sudo cp ekans.trx /lib/firmware/brcm/brcmfmac4364-pcie.bin`
    * Install firmware in terminal

        ```
        sudo apt update
        sudo apt install bcmwl-kernel-source
        sudo modprobe wl
        ```
    * References of how to enable WiFi
        * https://gist.github.com/niftylettuce/5619c2be9906bcbd893e1e1a25b9d795
        * https://askubuntu.com/questions/146425/how-can-i-install-and-download-drivers-without-internet

### References

* [How to Install and Dual Boot Linux on Your Mac](https://www.makeuseof.com/tag/install-linux-macbook-pro/)
* [REUSE, RECYCLE: SET UP A MAC MINI AS A LINUX SERVER](https://eshop.macsales.com/blog/67497-mac-mini-as-linux-server/)
* [Install Ubuntu On Mac Mini](https://install-ubuntu-on-mac-mini.peatix.com/)
* [Installation of Ubuntu on Mac Mini](https://nsrc.org/workshops/2015/nsrc-icann-dns-ttt-dubai/raw-attachment/wiki/Agenda/install-ubuntu-mac-mini.htm)
* grub-install fatal error
    * [SO answer 1](https://askubuntu.com/questions/1256686/cannot-install-ubuntu-20-04-on-mac-mini-2020)
    * [SO answer 2](https://unix.stackexchange.com/questions/636709/ubuntu-on-mac-executing-grub-install-dev-nvme0n1-failed)
* WIFI
    * [SO answer 1](https://askubuntu.com/questions/1260088/how-can-i-activate-wifi-on-bcm4364-using-brcmfac-driver-firmware)
    * [answer 2](https://www.linux.org/threads/solved-cannot-get-wifi-recognized-when-installing-popos-22-04-on-2015-macbook-pro.40277/)
    * [answer 3](https://easylinuxtipsproject.blogspot.com/p/internet.html#ID1.2)
    * [answer 4](https://wiki.ubuntuusers.de/WLAN/Broadcom_bcm43xx/)
    * [answer 5](https://super-unix.com/ubuntu/ubuntu-how-to-activate-wifi-on-bcm4364-using-brcmfac-driver-firmware/)
    * [answer 6](https://gist.github.com/niftylettuce/5619c2be9906bcbd893e1e1a25b9d795)
    * [answer 7](https://askubuntu.com/questions/1076964/macbook-can-t-find-wifi-for-ubuntu-18-04)
    * [answer 8](https://askubuntu.com/questions/1357817/ubuntu-21-04-dual-boot-on-imac-bigsur-wireless-device-not-supported)
    * [answer 9](https://www.amirootyet.com/post/how-to-get-wifi-to-work-after/)

## Software

### SSH

```
sudo apt install openssh-server -y
sudo systemctl status ssh
sudo ufw allow 22/tcp
sudo ufw enable && sudo ufw reload

# disable SSH service
sudo systemctl stop --now ssh
sudo systemctl disable --now ssh

# set passwordless authentication (key based)
mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
# then append the local public key to the authorized file
cat ~/.ssh/id_rsa.pub

# config SSH

# ~/.ssh/config
Host *
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_rsa

# hostname
# /etc/resolv.conf
# point to your router
nameserver 192.168.50.1
```

### VNC

* Login to Ubuntu Desktop
* Go to Settings -> Sharing, and make sure it’s toggled on
* Click Remote Desktop
    * Enable Remote Desktop
    * Enable Legacy VNC Protocol
        * Click the menu button and select “Require a password”
    * Enable Remote Control
    * Change Password under Authentication if you prefer

[How to Install and Configure VNC on Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-vnc-on-ubuntu-22-04)

```
sudo apt install tightvncserver
vncserver

# configure
vncserver -kill :1
nano ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup

sudo ufw allow 5901:5910/tcp
sudo ufw enable && sudo ufw reload
```

### Docker

[How To Install and Use Docker on Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04)

## Other

### Wireless Network Adapter
#### Generic
* [Wireless connection troubleshooter](https://help.ubuntu.com/stable/ubuntu-help/net-wireless-troubleshooting-hardware-check.html.en)
* [Wireless network troubleshooter](https://help.ubuntu.com/stable/ubuntu-help/net-wireless-troubleshooting-device-drivers.html.en)
* [WifiDocs/WirelessCardsSupported](https://help.ubuntu.com/community/WifiDocs/WirelessCardsSupported)
#### Driver
* [88x2bu](https://github.com/morrownr/88x2bu-20210702)
* [REALTEK RTL88x2B USB Linux Driver](https://github.com/RinCat/RTL88x2BU-Linux-Driver)
* [rtl88x2bu](https://github.com/cilynx/rtl88x2bu)
