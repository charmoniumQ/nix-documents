#! /usr/bin/env nix-shell
#! nix-shell -p jq -i bash

set -o errexit -o nounset -o xtrace -o pipefail

# nix fmt
# git add flake.nix flake.lock 
# nix --keep-going --show-trace --print-build-logs flake check

# rm --recursive --force examples
# nix --keep-going --show-trace --print-build-logs build .#examples
# cp --dereference --recursive result examples
# chmod --recursive u+rw,g+rw examples
# unlink result
# git add examples

rm --recursive --force test-template
mkdir test-template
cd test-template
nix flake init --template ..
git add -A .
nix build
cd ..
git rm --recursive --force test-template
