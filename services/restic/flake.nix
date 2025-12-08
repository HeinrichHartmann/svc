{
  inputs = {
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils }: utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          restic
          backblaze-b2
          opentofu
          just
        ];
      };

      packages.container = pkgs.dockerTools.buildImage {
        name = "restic-job";
        tag = "latest";
        copyToRoot = pkgs.buildEnv {
          name = "image-root";
          paths = with pkgs; [
            restic
            just
            coreutils
            bash
            cacert
            (pkgs.writeTextDir "svc/services/restic/justfile" (builtins.readFile ./justfile))
            (pkgs.writeTextDir "svc/services/restic/cmd.sh" (builtins.readFile ./cmd.sh))
          ];
          pathsToLink = [ "/bin" "/etc" "/svc" ];
        };
        config = {
          WorkingDir = "/svc/services/restic";
          Env = [
            "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
            "TMPDIR=/tmp"
          ];
          Cmd = [ "${pkgs.bash}/bin/bash" "cmd.sh" ];
        };
      };
    }
  );
}
