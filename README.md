# SVC - Local Service Configurations

This repository contains the configuration for several services I run at home.
This is not intended to be re-usable on the spot. 
It's open-sourced as inspiration for others and reference.

## Features

* Configured web services are available under `$service.heinrichhartmann.net` on tailscale VPN.
* Configured web services are available under `$service.lan.heinrichhartmann.net` inside home network.
* All web services are secured using https via letsencryp.
* Services are dockerised and consits of a `docker-compose.yaml` and a simple `Makefile`
* List of available services is contained in [/services](services)

## Structure

### Host Setup

This setup is designed to work in different environments including an dedicated
 server machine, a RPI and Linux Desktop environments.

On the host, this repository must be available under `/svc`.

The configuration rely on basic shell tools (`make`, `git`, `curl`) be installed as well as `docker-compose`. 
See the definition of `make install-deps` for more details.

<details>
I was confused about the "correct" place to host the configuration for a long time, keeping it under $HOME/svc.
This complicated a lot of scripts since, I wanted to changes to be self-contained and local:
I.e. don't write to other directories (keep everything in containers or within the tree) and use relative only relative directories.
This approach ran into challenges when managing bind mount points and scratch files written by the services.

The current approach is:

1. To avoid bind mounts and scratch files as much as possible.
2. If bind mounts they are unavoidable (shared volumes, user-id mappings) keep them under /svc/mnt
3. If scratch files are unavoidable (e.g. shared scratch files popuplated by non-docker tools) keep them under /svc/var

In this way all mounts can be clean-up by unmounting `/svc/mnt/*`.
And all scratch files can be cleaned-up by pruning docker volumens and clearing `/svc/var`.

From a conceptual point of view, it can be argued that we are configuring the node itself, not services consumed by one user. 
Hence using paths that are relative to the node root-fs "/" i.e. absolute is sensible. 
</details>


### Crypt

Secrets are managed inside this repository using [git-crypt](https://github.com/AGWA/git-crypt).
The trust model works as follows:

1. On a new host, generate GPG keys and add the public key to the repository, then push.
2. On an already trusted host, pull in the public keys and mark them as trusted, then push.
3. On the new host, pull latest version. It now has access to the secrets.

See ./crypt/README.md for more details.

**Open ends**

- There is no way to retire keys for the repository at this point in time. 

### DNS

Earlier version of this repository had self-hosted DHCP, DNS and PKI (Private
Key Infrastructure for https certificates) included in the config. This has the
obvious drawback that all clients have to install a self-signed certificate. But
even once this is done, there are more difficulties caused by various clients
decided to ignore the DHCP provided DNS services and/or ignore the root
certificates installed by the OS. Repeated offenders were Firefox, Firefox on
Android, Safari on iPhone.

At some point I stopped trying and accepted the fact, that I will be using an
external service for DNS and PKI.

The configuration now relies on AWS services for [DNS](https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones#ListRecordSets/Z01776191I9YNA03Q8DIE)
and PKI.

All required AWS configuration is managed using terraform located in `/infra/aws`.

- DNS records for `*.heinrichhartmann.net` point to the "svc" node inside the tailscale network.
- DNS records for `*.lan.heinrichhartmann.net` point to the "svc" node inside the local netowrk.
- Known hosts in the tailscale network are exposed under `$host.ts.heinrichhartmann.net` (requires manual updates)

### Certificates

Certificates are generated via `letsencrypt` and use DNS authentification faciliated by AWS.
Generated certificates are stored under `/svc/var`.

### Ingress


### Service Configuration

Service configurations are stored in `./services/$name` they typically consists of two files:

- `docker-compose.yaml` containing the actual service configuration
- `Makefile` exposing targets `start`, `stop`, `test`

Services are not enabled by default.
Services are not started on boot by default.

Services are managed with the tool `./svc.sh`.
Befor a service can be used it must be enabled with `./svc.sh enable $name`, this will create a symlink in `./services.enabled`.

``` shell

./svc.sh list-available # list available services

./svc.sh enable $name # enable service with given name

./svc.sh list # list enabled services

make start # start all enabled services

make stop # stop all enabled services

make test # test status of all services and print results
```

## Bootstrapping / Installation

1. Make sure internet is working

1. Make sure zfs volumnes are mounted under /share/hhartmann/*

1. Get access to secrets using `git-crypt`. See `./crypt/README.md`.

1. Update/Check DNS entries. See `./infrastructure/aws/`. We need a docker registry available under docker.heinrichhartmann.net.

1. Create/Update SSL Certificates. `make certs`

1. Enable services `./svc.sh activate $name`. Start services `make start`
