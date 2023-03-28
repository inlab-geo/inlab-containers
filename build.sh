#!/bin/bash

container_engine="podman"   # or "docker"
file="Containerfile"
username="inlab"
targets=("cofi" "espresso" "cofi_n_espresso" "inlab")
tag="latest"

for t in "${targets[@]}"; do   # The quotes are necessary here
    echo "-> Building target image: $t"
    $container_engine build \
        --target $t \
        --file $file \
        -t $username/$t:$tag \
        --format docker \
        .
    echo "-> Finished target image: $t"
done
