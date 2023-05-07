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

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.hhartmann = {
    isNormalUser = true;
    # change default shell
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "docker" "qemu-libvirtd" ]; # wheel = ‘sudo’
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
    extraOptions =
      "--registry-mirror=https://dockercache.heinrichhartmann.net --metrics-addr=0.0.0.0:9323";
  };
}
