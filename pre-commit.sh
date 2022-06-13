#! /usr/bin/env nix-shell
#! nix-shell -p jq -i bash

set -o errexit -o nounset -o xtrace -o pipefail

nix fmt
nix --show-trace --print-build-logs flake check

rm --recursive --force examples
nix --print-build-logs build .#examples
cp --dereference --recursive result examples
chmod --recursive u+rw,g+rw examples
unlink result

git add flake.nix flake.lock examples
