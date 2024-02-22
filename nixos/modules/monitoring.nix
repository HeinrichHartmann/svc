{ config, lib, pkgs, ... }:

{

  systemd.services.node-exporter = {
    description = "Prometheus node exporter";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart =
        "${pkgs.prometheus-node-exporter}/bin/node_exporter --collector.textfile.directory=/svc/var/prom/textfile_exporter";
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
        ${pkgs.fluent-bit}/bin/fluent-bit -c ${./etc/fluentbit.conf}
      '';
    };
  };

  systemd.services.promtail = {
    description = "Promtail service for Loki";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.grafana-loki}/bin/promtail --config.file ${
          ./etc/promtail.yaml
        }";
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
