
# Docker registry 

Provides docker registry to be deployed at `docker.heinrichhartmann.net`

- The registry is providing services at `*:5000` which is marked as exposed in
  the container metadata.

- Rounting, SSL termination and port mapping is taken care of by treafik
  configured via labels

See: https://docs.docker.com/registry/deploying/

## Dependencies

- zfs volume mounted on /share/hhartmann/docker-registry
