    # File Locations
    
    ## docker compose
    
    ```
    volumes:
      - "/svc/mnt/prism/pictures:/photoprism/originals"  # Original media files (DO NOT REMOVE)
      - "/svc/mnt/prism/import:/photoprism/import"       # *Optional* base folder from which files can be imported to originals
      - "/share/hhartmann/var/prism/storage:/photoprism/storage"     # *Writable* storage folder for cache, database, and sidecar files (DO NOT REMOVE)
    ```
    
    ## Makefile
    
    ```sh
    #
    # Photo Library / Originals
    #
    mkdir -p /svc/mnt/prism/pictures
    sudo bindfs -u 1000 -operms=a-w /share/hhartmann/garage/Pictures/Prism/ \
      /svc/mnt/prism/pictures

    mkdir -p /svc/mnt/prism/pictures/attic
    sudo bindfs -u 1000 -operms=a-w /share/hhartmann/attic/Pictures/ \
      /svc/mnt/prism/pictures/attic

    #
    # Import folders
    #
    mkdir -p /svc/mnt/prism/import/camera-upload
    sudo bindfs ... /share/hhartmann/garage/camera-upload/ /svc/mnt/prism/import/camera-upload

    mkdir -p /svc/mnt/prism/import/sd-staging
    sudo bindfs ... /share/hhartmann/garage/SD-Staging/ /svc/mnt/prism/import/sd-staging
    ```
