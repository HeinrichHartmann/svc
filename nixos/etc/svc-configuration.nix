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

  systemd.services.fluentbit = {
    description = "Fluentbit log exporter";
    wantedBy = [ "multi-user.target" ];
    after = [ "svc.service" ];
    requires = [ "svc.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.fluent-bit}/bin/fluent-bit -c ${./fluentbit.conf}
      '';
    };
  };

  systemd.services.promtail = {
    description = "Promtail service for Loki";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart =
        "${pkgs.grafana-loki}/bin/promtail --config.file ${./promtail.yaml}";
    };
  };

  systemd.services.docker-events = {
    description = "Docker events to logs";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      ExecStart = ''
        ${pkgs.docker}/bin/docker events --format '{{json .}}' -f 'event=start' -f 'event=stop'
      '';
    };
  };

}
