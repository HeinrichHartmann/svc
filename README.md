# SVC - Local Service Configurations

This repository contains the configuration for several services I run at home.

This is not intended to be re-usable on the spot, if you want to run this yourself, you will need to make several adjustements (e.g. override secrets).
The code minimal and straight forward, so adjustments should be straight forward.
This is shared for transparency and inspiration.

## Features

* Configured web services are available under `$service.heinrichhartmann.net` on tailscale VPN.
* Configured web services are available under `$service.lan.heinrichhartmann.net` inside home network.
* All web services are secured using https via letsencryp.
* Services are dockerised and consits of a `docker-compose.yaml` and a simple `Makefile`
* List of available services is contained in [/services](services)

## Structure

### Host Setup

This setup is designed to work in different environments including an dedicated server machine, a RPI and Linux Desktop environments.
The main server is running NixOS, with a config managed under [/nixos](nixos).

Requirements:

* This repository must be available under `/svc`.
* Basic shell tools (`make`, `git`, `curl`) must be installed as well as `docker-compose` and `bindfs`. See `make install-deps` for more details.

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


### Secrets

Secrets are managed inside this repository using [git-crypt](https://github.com/AGWA/git-crypt).
Files ending with `.crypt` are encrpyted inside the git repostiry, and only readable if your host is trusted.
The trust model works as follows:

1. On a new host, generate GPG keys and add the public key to the repository, then push.
2. On an already trusted host, pull in the public keys and mark them as trusted, then push.
3. On the new host, pull latest version. It now has access to the secrets.

See [/crypt/README.md](crypt/README.md) for more details.

**Open ends**

- There is no way to retire keys for the repository at this point in time. 

### DNS

The configuration now relies on AWS services for [DNS](https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones#ListRecordSets/Z01776191I9YNA03Q8DIE)
and PKI.

All required AWS configuration is managed using terraform located in `/infra/aws`.

- DNS records for `*.heinrichhartmann.net` point to the "svc" node inside the tailscale network.
- DNS records for `*.lan.heinrichhartmann.net` point to the "svc" node inside the local netowrk.
- Known hosts in the tailscale network are exposed under `$host.ts.heinrichhartmann.net` (requires manual updates)

**Learnings.** Earlier version of this repository had self-hosted DHCP, DNS and PKI (Private
Key Infrastructure for https certificates) included in the config. This has the
obvious drawback that all clients have to install a self-signed certificate. But
even once this is done, there are more difficulties caused by various clients
decided to ignore the DHCP provided DNS services and/or ignore the root
certificates installed by the OS. Repeated offenders were Firefox, Firefox on
Android, Safari on iPhone.

At some point I stopped trying and accepted the fact, that I will be using an
external service for DNS and PKI.

### Certificates

Certificates are generated via `letsencrypt` and use DNS authentification faciliated by AWS.
Generated certificates are stored under `/svc/var`.

Reneawal is performed using `make certs` from `/svc`.

### Ingress

We use Traefik[https://traefik.io/] as ingress proxy.

This tool terminates HTTPS, and routes HTTP requests to the appropriate backend.
Service discovery is dynamic, and configured using labels associated to docker containers.
It also allows to configure HTTP Basic Auth for services by adding a label.

Example:
```yaml
   labels:
      - "traefik.enable=true"
      - "traefik.http.routers.books.rule=HostRegexp(`books.{domain:.*}`)"
      - "traefik.http.routers.books.entrypoints=https"
      - "traefik.http.routers.books.tls=true"
```

**Learnings.** Prior iterations used Nginx and HAProxy as for routing requests.
I found these solutions harder to maintain, as they required to keep the config files in sync, and the syntax (in particular of HAProxy) was hard to manage.
Traefik offers a good out-of-the box experiences for the standard use-cases.
Debugging of the docker labels is sometimes a little bit tedious, as there is no linting or syntax checking.

**Open ends.** 
- I would really like to have OAuth in front of all my services, so I can safely connect and give others the ability to connect without manually managing passwords. Unfortunately the Traefik OAuth plugin is proprietary, and they don't have pricing information on thier page.
- At Zalando we maintain an in-house solution [Skipper](https://github.com/zalando/skipper) which comes with OAuth support. I want to try this out at some point.

### Service Configuration

Service configurations are stored in `./services/$name` they typically consists of two files:

- A `docker-compose.yaml` containing the actual service configuration
- A `Makefile` exposing targets `start`, `stop`, `test`.

Services can be selectively enabled/disabled using the `./svc.sh` tool.
Only enabled services are started on `make start` and on boot.

``` shell
./svc.sh new $name # create new service scaffolding from template

./svc.sh enable $name # enable service with given name

./svc.sh list-available # list available services

./svc.sh list # list enabled services

make start # start all enabled services

make stop # stop all enabled services

make test # test status of all services and print results
```

### Storage

The main server where this configuration is running is equipped with two 8TB HDD drives.
Those are configured as a ZFS pool with a RAID 0 configuration, allowing us to compensate for the loss of one of the disks.

We use zfs-autosnapshot to protect against accidental deletion.
Off-site backup is realized via [restic](services/restic) to backblaze for selected datasets.

There are 3 main filesystems on the pool, that differ in backup and replication strategy.

* `/share/shelf`. Working data-set that is intended to be replicated to all working machines. 
  Data in shelf is snapshotted and backed-up. Contents are mainly documents that are work in progress.
* `/share/attic`. Data in the attic is snapshotted and backed-up.
  Content includes archived projects, private photo collection, important media.
* `/share/garage`. Data in garage is snapshotted but not backed-up. 
  Here goes the long-tail of less valuable data I wound not mind loosing.

The naming of the datasets is reflecting the different storage tiers, that I use for personal stuff:

- Things in the garage are subject to moisture and my easily get stolen when I inadvertently leave the door open.
- Things in the attic are safe from the elements. Here I keep things of value that I don't want to loose. 
- Things on the shelf are used for daily operations. Those may get bumped and scratched, and I can easily replace them.

**Open Ends**

* Fix data replication on shelf.
  - Initially I used Dropbox to sync files in shelf between different machines.
    As Dropbox removed support for zfs, this was no longer possible.
    I also lost trust in their prouct alltogether, given the questionable "improvements" to the Desktop clients, and moved away from it entirely.
    Now that zfs is support again, it may be worth to revisit this decision.
  - For a while I used Syncthing to replicate data between hosts.
    This was always a lot more complicated and brittle. Afterseveral episodes of data loss, I gave up on this approach for now.
    I am sure I am able to get this to work well-enough if I invested more time, but right now I this feature is not a priority.

