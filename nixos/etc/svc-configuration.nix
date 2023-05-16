{ config, lib, pkgs, ... }:

let
  svcpath = [
    pkgs.coreutils
    pkgs.bash
    pkgs.gnumake
    pkgs.docker-compose
    pkgs.bindfs
    pkgs.sudo
    pkgs.nix
  ];
in {

  systemd.services.svc-startup = {
    description = "Start /svc services";
    after = [ "network.target" "zfs.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = { ConditionPathExists = "/svc"; };
    path = svcpath;
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/svc";
      ExecStart = "${pkgs.gnumake}/bin/make -C /svc startup";
    };
  };

  systemd.services.svc-shutdown = {
    description = "Stop /svc services";
    before = [ "shutdown.target" ];
    unitConfig = { ConditionPathExists = "/svc"; };
    path = svcpath;
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/svc";
      ExecStop = "${pkgs.gnumake}/bin/make -C /svc shutdown";
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
    timerConfig = {
      OnCalendar = "*:0/1";
      Persistent = true;
      Unit = "svc-cron.service";
    };
  };

  systemd.services.node-exporter = {
    description = "Prometheus node exporter";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.prometheus-node-exporter}/bin/node_exporter";
      Restart = "always";
    };
  };

  systemd.services.promtail = {
    description = "Promtail service for Loki";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = ''
        ${pkgs.grafana-loki}/bin/promtail --config.file /svc/nixos/conf/promtail.yaml
      '';
    };
  };

}
