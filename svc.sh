#!/usr/bin/env sh

set -e # exit on error


while [[ "$#" -gt 0 ]]
do
    cmd=$1
    shift
    case $cmd in
        "list-available")
            (cd ./services; ls -1);
            break
            ;;
        "list" | "list-active" | "ls")
            mkdir -p services.enabled
            (cd ./services.enabled; ls -1);
            break
            ;;
        "enable")
            set -x # echo commands
            mkdir -p services.enabled
            # check if service is available
            if [ ! -d "./services/$1" ]; then
                echo "Service $1 not found"
                exit 1
            fi
            (cd services.enabled && ln -s "../services/$1");
            break
            ;;
        "disable")
            set -x # echo commands
            rm "services.enabled/$1"
            break
            ;;
        *)
            cat $0
            exit 1
            ;;
    esac
done


exit 0
