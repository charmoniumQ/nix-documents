{
  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    nix-documents = {
      url = "github:charmoniumQ/nix-documents";
    };
  };
  outputs = { self, nixpkgs, flake-utils, nix-documents }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nix-documents-lib = nix-utils.lib.${system};
      in
      rec {

        packages = nix-utils-lib.packageSet [
          (nix-documents-lib.markdownDocument {
            src = ./.;
          })
        ];

        checks = { } // packages;
      }
    );
}
