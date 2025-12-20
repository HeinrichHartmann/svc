{ config, pkgs, ... }:

{
  systemd.services.mbsync = {
    description = "Mbsync mail synchronization with backup";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "hhartmann";
      WorkingDirectory = "/svc/services/mail";
      ExecStart = "${pkgs.direnv}/bin/direnv exec . ${pkgs.gnumake}/bin/make job-run";
      StandardOutput = "journal";
      StandardError = "journal";

      # Security hardening
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  systemd.timers.mbsync = {
    description = "Timer for mbsync mail synchronization";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "*:0/15";  # Every 15 minutes
      Persistent = true;
      RandomizedDelaySec = "60";
    };
  };
}
