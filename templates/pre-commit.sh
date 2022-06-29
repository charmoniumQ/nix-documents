#! /usr/bin/env nix-shell
#! nix-shell -p jq -i bash

set -o errexit -o nounset -o xtrace -o pipefail

rm --recursive --force build
nix --keep-going --show-trace --print-build-logs build
cp --dereference --recursive result build
chmod --recursive u+rw,g+rw build
unlink result
git add build
