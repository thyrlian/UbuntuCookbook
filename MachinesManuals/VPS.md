## Security Hardening

* Update the system and reboot
  ```bash
  sudo apt update && sudo apt full-upgrade -y
  sudo reboot
  ```

* Create a non-root sudo user and copy the SSH key
  ```bash
  # Run the following commands as root
  USER_NAME="your_username" # replace with your actual username
  
  # Create the user and grant sudo privileges
  adduser --gecos "" "$USER_NAME"
  usermod -aG sudo "$USER_NAME"
  
  # Create the SSH directory and copy the root user's authorized_keys file
  install -d -m 700 -o "$USER_NAME" -g "$USER_NAME" /home/"$USER_NAME"/.ssh
  install -m 600 -o "$USER_NAME" -g "$USER_NAME" /root/.ssh/authorized_keys /home/"$USER_NAME"/.ssh/authorized_keys
  ```

* Verify SSH and sudo access
  ```bash
  # Verify SSH login with the new user in a new terminal
  ssh your_username@your_server_ip
  # Verify sudo privileges
  sudo whoami
  ```

* Harden SSH authentication
  ```bash
  # Create an SSH hardening override configuration
  sudo tee /etc/ssh/sshd_config.d/99-hardening.conf > /dev/null <<'EOF'
  KbdInteractiveAuthentication no
  PasswordAuthentication no
  PubkeyAuthentication yes
  PermitRootLogin prohibit-password
  EOF
  
  # Validate the SSH configuration and reload the SSH service
  sudo sshd -t && sudo systemctl reload ssh
  
  # Verify the effective SSH authentication settings
  sudo sshd -T | egrep 'kbdinteractiveauthentication|passwordauthentication|pubkeyauthentication|permitrootlogin'
  ```

* Configure the firewall
  ```bash
  # Allow SSH before enabling the firewall
  sudo ufw allow 22/tcp
  
  # Enable UFW
  sudo ufw enable
  
  # Optional: allow HTTP and HTTPS if you plan to deploy websites, reverse proxies, or other web services
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  
  # Show the current firewall status
  sudo ufw status verbose
  ```

* Enable automatic security updates
  ```bash
  # Install unattended-upgrades
  sudo apt update
  sudo apt install -y unattended-upgrades
  
  # Enable automatic updates
  sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<'EOF'
  APT::Periodic::Update-Package-Lists "1";
  APT::Periodic::Unattended-Upgrade "1";
  EOF
  
  # Show the automatic update configuration
  sudo cat /etc/apt/apt.conf.d/20auto-upgrades
  ```

* Install Fail2ban
  ```bash
  # Install Fail2ban as an additional layer of defense to reduce noisy malicious SSH scans and repeated failed login attempts
  sudo apt update
  sudo apt install -y fail2ban
  
  # Create a configuration for SSH protection
  sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
  [sshd]
  enabled = true
  bantime = 1h
  findtime = 10m
  maxretry = 5
  EOF
  
  # Enable and start the Fail2ban service
  sudo systemctl enable --now fail2ban
  
  # Show Fail2ban service status
  sudo systemctl status fail2ban --no-pager
  
  # Show overall Fail2ban status
  sudo fail2ban-client status
  
  # Show SSH jail status
  sudo fail2ban-client status sshd
  ```
