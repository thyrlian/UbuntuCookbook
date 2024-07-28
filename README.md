# UbuntuCookbook
A comprehensive setup guide for Ubuntu

## Configuration

* Unblock the restriction on unprivileged namespace (for Ubuntu 24.04 LTS)
  ```bash
  # Edit the /etc/sysctl.conf file, and add one configuration to the end
  kernel.apparmor_restrict_unprivileged_userns=0
  # Apply the changes
  sudo sysctl -p
  # This ensures that the setting is applied every time the system boots up
  ```
* [Optimize swap](https://help.ubuntu.com/community/SwapFaq) by adjusting swappiness parameter
  ```bash
  # To check the swappiness value
  cat /proc/sys/vm/swappiness
  # To change the swappiness value A temporary change (lost on reboot) with a swappiness value of 10 can be made with
  sudo sysctl vm.swappiness=10
  # To make a change permanent, edit the configuration file with your favorite editor:
  gksudo gedit /etc/sysctl.conf
  # Search for vm.swappiness and change its value as desired. If vm.swappiness does not exist, add it to the end of the file like so:
  vm.swappiness=10
  # Save the file and reboot.
  ```
* [Generating a new SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

## Software

### Productivity

* [AppImageKit](https://github.com/AppImage/AppImageKit/wiki/FUSE)
* [Fcitx 5](https://github.com/fcitx/fcitx5)
  * [Install & Config](https://medium.com/@brightoning/cozy-ubuntu-24-04-install-fcitx5-for-chinese-input-f4278b14cf6f)
* [Obsidian](https://obsidian.md/)
  * [cross-platform sync solution](https://forum.obsidian.md/t/accessing-icloud-obsidian-folder-from-ubuntu-linux/33478/2)
* [Xmind](https://xmind.app/)
* [Albert launcher](https://github.com/albertlauncher/albert)

### Development

* [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
  * Fonts
    * [Powerline Font](https://github.com/powerline/fonts)
    * [Nerd Font](https://github.com/ryanoasis/nerd-fonts)
  * Theme: [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
* [Starship](https://github.com/starship/starship)
* [VS Code](https://code.visualstudio.com/)
* [Sublime Text](https://www.sublimetext.com/)
* [Sublime Merge](https://www.sublimemerge.com/)
* [GitKraken](https://www.gitkraken.com/)
* [Docker](https://www.docker.com/)
  * [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
  * [Install Docker Desktop on Ubuntu](https://docs.docker.com/desktop/install/ubuntu/)
  * [Sign in to Docker Desktop](https://docs.docker.com/desktop/get-started/#credentials-management-for-linux-users)
* Emulation
  * [OSX-KVM](https://github.com/kholia/OSX-KVM)
  * [darling](https://github.com/darlinghq/darling)
  * [quickemu](https://github.com/quickemu-project/quickemu)
* [Warp](https://www.warp.dev/)
* [Arduino IDE](https://www.arduino.cc/en/software)

### Entertainment

* [VLC](https://www.videolan.org/)
