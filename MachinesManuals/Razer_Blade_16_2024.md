* **Hardware Upgrade**
	* [Razer Blade 16 RAM- & SSD-Upgrades](https://www.crucial.de/compatible-upgrade-for/razer/razer-blade-16)
* **Update BIOS** (must be in Windows)
* **Update Samsung SSD Firmware**
	* [Samsung Magician](https://semiconductor.samsung.com/consumer-storage/magician/)
	* [How To Update Samsung SSD Firmware on Linux](https://www.cyberciti.biz/faq/upgrade-update-samsung-ssd-firmware/)
* **THX Spatial Audio**
	* [THX Spatial License Code](https://gold.razer.com/eu/en/gold/catalog/thx-spatial-audio)
* **Dual-Boot**
  * Install Ubuntu
    * Manual installation
    * Create New Partition
      * **Root Partition**
        * File System Type: `Ext4`
        * Mount Point: `/`
      * **Swap Partition**
        * Size:
          * typically 1-2 times the amount of RAM
          * at least equal to the size of your RAM to support hibernate function, because it needs to store the entire contents of the memory.
        * File System Type: `Swap`
        * Mount Point: (leave it blank)
      * **EFI System Partition** (automatically created by system)
        * File System Type: `FAT32`
        * Mount Point: `/boot/efi`
* **Fix & Tweaks**
	* [No audio](https://www.reddit.com/r/razer/comments/1b9wh22/blade_202324_sound_issue_on_linux/)
		* `sudo apt install alsa-tools`
		* run script [RB16_2024_enable_internal_speakers.sh](https://github.com/thyrlian/UbuntuCookbook/blob/main/MachinesManuals/RB16_2024_enable_internal_speakers.sh)
	* RAM frequency (5600 MHz → 5200 MHz)
		* [Razer Blade 16" (2024) supports Up to 96 GB DDR5-5200 MHz](https://mysupport.razer.com/app/answers/detail/a_id/5652/~/razer-blade-maximum-supported-storage-and-memory)
		* [Razer Blade Pro 17 2020 No XMP profile?](https://insider.razer.com/razer-support-45/razer-blade-pro-17-2020-no-xmp-profile-11247)
		* [Is XMP support coming to the Blade 16 at some point?](https://www.reddit.com/r/razer/comments/17yiw6i/is_xmp_support_coming_to_the_blade_16_at_some/)
		* [2019 Razer Blade 15 Advanced 3200MHz RAM XMP Profile](https://www.reddit.com/r/razer/comments/13fbuf0/2019_razer_blade_15_advanced_3200mhz_ram_xmp/)
	* Adjust display refresh rate (240 Hz → 60 Hz)
	* Boot up takes too long time
		* Disable Secure Boot (`UEFI` → `Security` → `Secure Boot` → `Disabled` )
	* Long time black screen after Ubuntu login
		* Reinstall NVIDIA Driver
  		```
  		sudo apt purge ~nnvidia
  		sudo apt autoremove
  		sudo apt clean
  		sudo apt update
  		sudo apt full-upgrade
  		```
		* Software & Updates → Additional Drivers → NVIDIA Corporation: AD106M [GeForce RTX 4070 Max-Q/Mobile] → Using NVIDIA driver metapackage from nvidia-driver-535 (proprietary, tested)
* **Installation**
	* [OpenRazer](https://openrazer.github.io/)
