# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.05";

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;
  system.autoUpgrade.channel = "https://nixos.org/channels/nixos-22.11";

  imports = [ ./hardware-configuration.nix ];

  networking = {
    hostName = "pve";
    hostId = "73eb52c1"; # "$(head -c 8 /etc/machine-id)";
    networkmanager.enable = false;
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    interfaces.eno2.ipv4.addresses = [
      {
        address = "192.168.2.12";
        prefixLength = 24;
      }
      {
        address = "192.168.2.13"; # samba
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.2.1";
  };

  # Bootloader Config
  boot.loader.systemd-boot.enable = true;

  # Cleanup system automatically
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.package = pkgs.nixVersions.latest;

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
    # System User: This option only has an effect if uid is null, in which case it determines whether the user’s UID is allocated in the range for system users (below 1000) or in the range for normal users (starting at 1000).
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups =
      [ "wheel" "docker" "qemu-libvirtd" "smbgroup" ]; # wheel = ‘sudo’
    openssh.authorizedKeys.keyFiles = [ ./etc/authorized_keys ];
  };

  # Passwordless sudo
  security.sudo.wheelNeedsPassword = false;
  security.sudo.enable = true;

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    zsh
    emacs-nox
    curl
    wget
    tmux
    git
    git-lfs
    zsh
    ripgrep
    docker-compose
    gnumake

    htop
    bridge-utils

    ethtool # manage NIC settings (offload, NIC feeatures, ...)
    tcpdump # view network traffic
    conntrack-tools # view network connection states
    iptables
    nftables

    bcc
    bpftrace
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  i18n = { defaultLocale = "en_US.UTF-8"; };

  programs.zsh.enable = true;
  programs.mosh.enable = true;
  networking.firewall.enable = false;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
    };
  };
  virtualisation.docker = {
    enable = true;
    storageDriver = "overlay2";
    extraOptions =
      "--registry-mirror=https://dockercache.heinrichhartmann.net --metrics-addr=0.0.0.0:9323 --log-opt fluentd-address=192.168.3.3:8006 --log-opt fluentd-async=true";
    logDriver = "fluentd";
  };

  # Access for "upload" user used by usb-pi
  # Add user for uploading files
  users.users.upload = {
    isNormalUser = true;
    home = "/share/hhartmann/garage/upload";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDUeADHUudcZqvkeiWYhb0Fpxx89ulerWVm+Tp0XqKjYEaXLyuxc7pMpUJURWLxRVRzp9y55hEbb8ezrXMkIqFhEk41TkVULA0w1H4qMLpHKNghhLKw1zeOLbIFD/YA1sGYeO11WS8bUxmza3wQ5u+GbOkPzyc7/hGPEIFYi8l3zOTWI6Xrgc6snMFZ4X7+k7AZnjYMIBhC8usRSAqkdggIhot+0vBpTI4dJuUpptLEfKd52OoEL9bC3faQF7iW+GTj27oX+YCR1YoVcc+wUpNJ3xX2N5DUE352Pc9zdkKDvmGxmZzcmflwmAqYfM3IZyFQS7AdXZQLyZ6cQu/eh3YYlDTeQmLoW0YgthM3MF1LWRTTq2IEsk7aiuhJF8rq5ROeS3jkIk/DLfTT6VHLb+TlCEs2B1dYmckt40M8dkL5nBZWdvdksnd37wkz56Wg8SDR1n6VdBAI/395h4FlUJUelqGIp+RSCYIwwlan/NETl4Tjoxg7NIkwkqhRcQ8FF2c= pi@piusb"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDlE0NvrB2V6pCLmUu5JImY4yP4q0GgqIcAZfQGptoFG6VbKwJHsw4TZN5HynSWq/thmbo1riNrKPjPHVV3QK+z/fIp0SmOrt4s0d9SBRX+pM9pZskJyQ8OCkr339Diz1gc7vo5FdiD13onHhbJrtX1npLcWboDBr2BWQN5lIAOhoQ95MBY3My6pOdbhgcBFTu7F+O+DKO6dT4rnI61nTH68f33/wDsyc2mtiiLktaq+gsR5hNXxi8eommUH47p/cZyc8wMVmBvwAxnyKuWjgRyRospKzTnKZHRi8GdNAIFoyOE2NEWbkvRBxG7ZWUqitlE6JypVs+fR5YAN1BDZJoorqIgDBX7nzW/gjGZH2+6aI8DpDmX6VQjKK8JiEczRaFnnQ3UZRHIQw/vMaGvya643Dg35nLAfbPafGvGIJ2RgkSuwB/mrFUAcGE4apNI3pU1g2SCeqEQFZOIuDdikbGoynL0CfNcgz6sgkhjBZzI/xV528l3+s/8c4F4twC6hVs= root@nixos"
    ];
  };

  # nix cache available through https://nix.heinrichhartmann.net/
  services.nix-serve = {
    enable = true;
    port = 9090;
  };

  # Allow cross-compilation for RPI
  # https://nixos.wiki/wiki/NixOS_on_ARM#Compiling_through_QEMU
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  environment.etc = {
    "test.txt".text = "Hello world!";
  };

}
