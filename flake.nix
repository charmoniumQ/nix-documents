{
  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    nix-utils = {
      url = "github:charmoniumQ/nix-utils";
    };
  };
  outputs = { self, nixpkgs, flake-utils, nix-utils }:
    {
      templates = {
        default = {
          path = ./templates;
          description = "Template for making documents as a Nix Flake";
        };
      };
    } // flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nix-lib = nixpkgs.lib;
          nix-utils-lib = nix-utils.lib.${system};
        in
        {
          formatter = pkgs.nixpkgs-fmt;
          checks = { } // self.packages.${system};
        } // ((import ./lib.nix) pkgs nix-lib nix-utils-lib)
      );


  # TODO: packageSet should check for dups.
  # TODO: Check that file exists
  # TODO: Type check texLivePackages
  # TODO: Function returns a map of packages; use attr to specify the output type, e.g. `(markdownDocument {}).pdf`.
  # TODO: dvi2svg https://dvisvgm.de/
  # TODO: revealjs presentation
  # TODO: add pdfengine packages to markdownDocument automatically.
  # TODO: Fix fontconfig error
  # Fontconfig error: No writable cache directories
}
