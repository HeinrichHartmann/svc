{ config, lib, pkgs, ... }:

let
  svcpath = [
    pkgs.coreutils
    pkgs.util-linux # umount
    pkgs.bash
    pkgs.gnumake
    pkgs.docker
    pkgs.bindfs
    pkgs.sudo
    pkgs.nix
    pkgs.git
  ];

in {

  systemd.services.svc = {
    description = "Manage /svc services";
    after = [ "network.target" "zfs.target" "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = { ConditionPathExists = "/svc"; };
    path = svcpath;
    serviceConfig = {
      Type = "forking";
      WorkingDirectory = "/svc";
      ExecStart = "${pkgs.gnumake}/bin/make -C /svc startup";
      ExecStop = "${pkgs.gnumake}/bin/make -C /svc shutdown";
      RemainAfterExit = "yes";
    };
  };

  systemd.services.svc-cron = {
    description = "Run 'make cron' in /svc";
    after = [ "svc-startup.service" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = { ConditionPathExists = "/svc"; };
    path = svcpath;
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/svc";
      ExecStart = "${pkgs.gnumake}/bin/make -C /svc cron";
    };
  };

  systemd.timers.svc-cron = {
    description = "Run 'make cron' in /svc every hour";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* *:00:00";
      Persistent = true;
      Unit = "svc-cron.service";
    };
  };

  systemd.services.svc-metrics = {
    description = "Run 'make metrics' in /svc";
    after = [ "svc-startup.service" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = { ConditionPathExists = "/svc"; };
    path = svcpath;
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/svc";
      ExecStart = "${pkgs.gnumake}/bin/make -C /svc metrics";
    };
  };

  systemd.timers.svc-metrics = {
    description = "Run 'make metrics' in /svc every minute";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* *:*:00"; # every minute
      Persistent = true;
      Unit = "svc-metrics.service";
    };
  };

  systemd.services.nix-index = {
    description = "Run nix-index daily";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      Environment = "NIX_PATH=nixpkgs=${pkgs.path}";
      ExecStart = "${pkgs.nix-index}/bin/nix-index";
    };
  };

  systemd.timers.nix-index = {
    description = "Run nix-index daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      Unit = "nix-index.service";
    };
  };

}
