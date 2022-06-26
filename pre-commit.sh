#! /usr/bin/env nix-shell
#! nix-shell -p jq -i bash

set -o errexit -o nounset -o xtrace -o pipefail

# Nix fmt
nix fmt
git add flake.nix flake.lock 
nix --keep-going --show-trace --print-build-logs flake check

# Compile example documents
rm --recursive --force examples
nix build '.#examples' --keep-going --show-trace --print-build-logs
cp --dereference --recursive result examples
chmod --recursive u+rw,g+rw examples
unlink result
git add examples

# Check that the Nix template works
echo -e "If you add a feature, this may fail, because the Nix template refers to the version of the flake in GitHub.
In that case, run this script after commiting/pushing."
rm --recursive --force test-template
mkdir test-template
cd test-template
nix flake init --template ..
git add -A . # add src so it shows up in the Nix build env.
nix build --keep-going --show-trace --print-build-logs
git add result # add the result so it gets `git rm`ed later.
cd ..
git rm -r --force test-template
