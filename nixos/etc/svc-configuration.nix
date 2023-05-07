{ config, lib, pkgs, ... }:

{

  systemd.services.svc-startup = {
    description = "Start /svc services";
    after = [ "network.target" "zfs.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = { ConditionPathExists = "/svc"; };
    path =
      [ pkgs.coreutils pkgs.bash pkgs.gnumake pkgs.docker-compose pkgs.bindfs pkgs.sudo ];
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/svc";
      ExecStart = "${pkgs.gnumake}/bin/make -C /svc startup";
    };
  };

  systemd.services.svc-shutdown = {
    description = "Stop /svc services";
    before = [ "shutdown.target" ];
    path = [ pkgs.coreutils pkgs.bash pkgs.gnumake pkgs.bindfs pkgs.sudo ];
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/svc";
      ExecStop = "${pkgs.gnumake}/bin/make -C /svc shutdown";
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
}
