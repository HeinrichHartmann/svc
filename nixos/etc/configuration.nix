# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion =
    "22.05"; # i.e. maintain compatibility with this version of NixOS

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;
  system.autoUpgrade.channel = "https://nixos.org/channels/nixos-22.11";

  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./network-configuration.nix
    ./zfs-configuration.nix
    ./svc-configuration.nix
  ];

  # Bootloader Config
  boot.loader.systemd-boot.enable = true;

  # Copy configuration on switch
  system.copySystemConfiguration = true;

  # Cleanup system automatically
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Lot's of data is stored with this uid and gid
  users.groups.smbgroup.gid = 101;
  users.users.smbuser.uid = 100;
  users.users.smbuser.group = "smbgroup";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.hhartmann = {
    # Exactly one of isNormalUser and isSystemUser must be true
    # Normal User: This automatically sets group to users, createHome to true, home to /home/«username», useDefaultShell to true, and isSystemUser to false. Exactly one of isNormalUser and isSystemUser must be true.
    # System User:  This option only has an effect if uid is null, in which case it determines whether the user’s UID is allocated in the range for system users (below 1000) or in the range for normal users (starting at 1000).
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups =
      [ "wheel" "docker" "qemu-libvirtd" "smbgroup" ]; # wheel = ‘sudo’
    openssh.authorizedKeys.keyFiles = [ /etc/nixos/ssh/authorized_keys ];
  };

  # Passwordless sudo
  security.sudo.wheelNeedsPassword = false;

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    zsh
    emacs
    curl
    wget
    tmux
    git
    git-lfs
    zsh
    ripgrep
    docker-compose
    bridge-utils
    gnumake
    htop
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  i18n = { defaultLocale = "en_US.UTF-8"; };

  programs.zsh.enable = true;
  programs.mosh.enable = true;
  services.openssh.enable = true;
  networking.firewall.enable = false;
  virtualisation.docker = {
    enable = true;
    storageDriver = "overlay2";
    extraOptions =
      "--registry-mirror=https://dockercache.heinrichhartmann.net --metrics-addr=0.0.0.0:9323 --log-opt fluentd-address=192.168.3.3:8006 --log-opt fluentd-async=true";
    logDriver = "fluentd";
  };

  # usb-pi
  # Add user for uploading files
  users.users.upload = {
    isNormalUser = true;
    home = "/share/hhartmann/garage/upload";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDUeADHUudcZqvkeiWYhb0Fpxx89ulerWVm+Tp0XqKjYEaXLyuxc7pMpUJURWLxRVRzp9y55hEbb8ezrXMkIqFhEk41TkVULA0w1H4qMLpHKNghhLKw1zeOLbIFD/YA1sGYeO11WS8bUxmza3wQ5u+GbOkPzyc7/hGPEIFYi8l3zOTWI6Xrgc6snMFZ4X7+k7AZnjYMIBhC8usRSAqkdggIhot+0vBpTI4dJuUpptLEfKd52OoEL9bC3faQF7iW+GTj27oX+YCR1YoVcc+wUpNJ3xX2N5DUE352Pc9zdkKDvmGxmZzcmflwmAqYfM3IZyFQS7AdXZQLyZ6cQu/eh3YYlDTeQmLoW0YgthM3MF1LWRTTq2IEsk7aiuhJF8rq5ROeS3jkIk/DLfTT6VHLb+TlCEs2B1dYmckt40M8dkL5nBZWdvdksnd37wkz56Wg8SDR1n6VdBAI/395h4FlUJUelqGIp+RSCYIwwlan/NETl4Tjoxg7NIkwkqhRcQ8FF2c= pi@piusb"
    ];
  };

  # nix cache available through https://nix.heinrichhartmann.net/
  services.nix-serve = {
    enable = true;
    port = 9090;
  };

}
