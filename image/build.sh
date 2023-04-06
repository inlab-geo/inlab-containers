#!/bin/bash

engine="docker"   # "podman" or "docker"
file="Containerfile"
username="inlabgeo"
targets=("cofi" "espresso" "cofi_n_espresso" "inlab")
tag="latest"
extra_args=$([ "$engine" == "docker" ] && echo "" || echo "--format docker")

for t in "${targets[@]}"; do   # The quotes are necessary here
    echo "-> Building target image: $t"
    $engine build \
        --no-cache \
        --target $t \
        --file $file \
        -t $username/$t:$tag \
        $extra_args \
        .
    echo "-> Finished target image: $t"
done
