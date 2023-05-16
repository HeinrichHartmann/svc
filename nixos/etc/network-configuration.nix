{ config, pkgs, ... }:

{
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

  # make the tailscale command usable to users
  environment.systemPackages = [
    pkgs.tailscale
    pkgs.ethtool # manage NIC settings (offload, NIC feeatures, ...)
    pkgs.tcpdump # view network traffic
    pkgs.conntrack-tools # view network connection states
    pkgs.iptables
    pkgs.nftables
  ];

  # enable the tailscale service
  services.tailscale.enable = true;

  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
      	echo "Running"
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up -authkey tskey-kXukoi4CNTRL-PkCxC5MBh7VbUwNzTXK5v
    '';
  };
}

