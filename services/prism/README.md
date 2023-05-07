# Photoprism

Example Docker Compose config file for PhotoPrism (Linux / AMD64)

Note:
- Running PhotoPrism on a server with less than 4 GB of swap space or setting a memory/swap limit can cause unexpected
  restarts ("crashes"), for example, when the indexer temporarily needs more memory to process large files.# - If you install PhotoPrism on a public server outside your home network, please always run it behind a secure
  HTTPS reverse proxy such as Traefik or Caddy. Your files and passwords will otherwise be transmitted
  in clear text and can be intercepted by anyone, including your provider, hackers, and governments:
  https://docs.photoprism.app/getting-started/proxies/traefik/

Documentation : https://docs.photoprism.app/getting-started/docker-compose/
Docker Hub URL: https://hub.docker.com/r/photoprism/photoprism/

DOCKER COMPOSE COMMAND REFERENCE
see https://docs.photoprism.app/getting-started/docker-compose/#command-line-interface
--------------------------------------------------------------------------
Start    | docker-compose up -d
Stop     | docker-compose stop
Update   | docker-compose pull
Logs     | docker-compose logs --tail=25 -f
Terminal | docker-compose exec photoprism bash
Help     | docker-compose exec photoprism photoprism help
Config   | docker-compose exec photoprism photoprism config
Reset    | docker-compose exec photoprism photoprism reset
Backup   | docker-compose exec photoprism photoprism backup -a -i
Restore  | docker-compose exec photoprism photoprism restore -a -i
Index    | docker-compose exec photoprism photoprism index
Reindex  | docker-compose exec photoprism photoprism index -f
Import   | docker-compose exec photoprism photoprism import

To search originals for faces without a complete rescan:
docker-compose exec photoprism photoprism faces index

All commands may have to be prefixed with "sudo" when not running as root.
This will point the home directory shortcut ~ to /root in volume mounts.
