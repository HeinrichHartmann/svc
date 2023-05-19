## Bootstrapping / Installation

1. Make sure internet is working

1. Make sure zfs volumnes are mounted under /share/hhartmann/*

1. Get access to secrets using `git-crypt`. See `./crypt/README.md`.

1. Update/Check DNS entries. See `./infrastructure/aws/`. We need a docker registry available under docker.heinrichhartmann.net.

1. Create/Update SSL Certificates. `make certs`

1. Enable services `./svc.sh activate $name`. Start services `make start`
