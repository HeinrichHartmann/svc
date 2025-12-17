{
  description = "mbsync Docker image for syncing Gmail to Maildir";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Entrypoint script
        entrypoint = pkgs.writeScriptBin "docker-entrypoint" ''
          #!${pkgs.bash}/bin/bash
          set -e

          # Parse mbsyncrc to extract and create Path directories
          if [ -f /config/.mbsyncrc ]; then
            ${pkgs.gnugrep}/bin/grep '^Path ' /config/.mbsyncrc | while read -r _ path; do
              # Remove trailing slash if present and create directory
              path_clean="''${path%/}"
              if [ -n "$path_clean" ]; then
                echo "Creating Maildir path: $path_clean"
                mkdir -p "$path_clean"
              fi
            done
          fi

          # Execute mbsync with config from /config and passed arguments
          exec ${pkgs.isync}/bin/mbsync -c /config/.mbsyncrc "$@"
        '';

        # Build a minimal Docker image with mbsync
        mbsyncImage = pkgs.dockerTools.buildImage {
          name = "mbsync";
          tag = "latest";

          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = with pkgs; [
              isync  # provides mbsync
              coreutils
              bash
              gnugrep
              gawk
              cacert  # SSL certificates
              entrypoint
            ];
            pathsToLink = [ "/bin" "/etc/ssl" ];
          };

          config = {
            Entrypoint = [ "${entrypoint}/bin/docker-entrypoint" ];
            Cmd = [ "-a" "-V" ];
            WorkingDir = "/data";
            Env = [
              "HOME=/data"
              "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
            ];
          };
        };

        # Safe sync wrapper with Ruby
        safeSyncWrapper = pkgs.writeShellScriptBin "safe-sync" ''
          exec ${pkgs.ruby}/bin/ruby ${./safe-sync.rb} "$@"
        '';

      in {
        packages = {
          dockerImage = mbsyncImage;
          safe-sync = safeSyncWrapper;
          default = mbsyncImage;
        };

        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            isync
            ruby
          ];
        };
      }
    );
}
