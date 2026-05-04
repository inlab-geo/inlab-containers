#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

engine="${ENGINE:-docker}"
file="${FILE:-${repo_root}/image/Containerfile}"
username="${USERNAME:-inlabgeo}"
tag="${TAG:-latest}"
platforms="${PLATFORMS:-$(uname -m)}"
targets=(${TARGETS:-cofi inlab})

case "${platforms}" in
    x86_64) platforms="linux/amd64" ;;
    arm64|aarch64) platforms="linux/arm64" ;;
esac

build_cmd=("${engine}" buildx build)
if [[ "${engine}" != "docker" ]]; then
    build_cmd=("${engine}" build)
fi

for target in "${targets[@]}"; do
    echo "-> Building target image: ${target} (${platforms})"
    if [[ "${engine}" == "docker" ]]; then
        args=(
            --platform "${platforms}"
            --target "${target}"
            --file "${file}"
            --tag "${username}/${target}:${tag}"
        )
        if [[ "${PUSH:-false}" == "true" ]]; then
            args+=(--push)
        elif [[ "${platforms}" != *","* ]]; then
            args+=(--load)
        fi
        "${build_cmd[@]}" "${args[@]}" "${repo_root}"
    else
        "${build_cmd[@]}" \
            --target "${target}" \
            --file "${file}" \
            --tag "${username}/${target}:${tag}" \
            "${repo_root}"
    fi
    echo "-> Finished target image: ${target}"
done
