{
  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    nix-utils = {
      url = "github:charmoniumQ/nix-utils";
    };
    nix-documents = {
      url = "github:charmoniumQ/nix-documents";
    };
  };
  outputs = { self, nixpkgs, flake-utils, nix-utils, nix-documents }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nix-lib = nixpkgs.lib;
          nix-utils-lib = nix-utils.lib.${system};
          nix-documents-lib = nix-documents.lib.${system};
        in
        rec {
          formatter = pkgs.nixpkgs-fmt;

          packages = nix-utils-lib.packageSetRec (self: [
            (nix-documents-lib.graphvizFigure {
              src = ./figure;
              name = "figure.svg";
            })
            (nix-documents-lib.markdownDocument {
              src = ./document;
              name = "document.pdf";
              pdfEngine = "xelatex";
              texlivePackages = nix-documents-lib.pandocTexlivePackages // {
                inherit (pkgs.texlive)
                  fancyhdr
                  # other TeXlive packages here
                  # See https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/tools/typesetting/tex/texlive/pkgs.nix
                  ;
              };

              # Nix package inputs will be accessible in the source directory by the derivation.name
              inputs = [
                self."figure.svg"
              ];
            })
            (nix-utils-lib.mergeDerivations {
              name = "default";
              packageSet = (nix-utils-lib.packageSet [
                # Comment out if you don't need the figure separately.
                self."figure.svg"
                self."document.pdf"
              ]);
            })
          ]);

          checks = { } // packages;
        }
      );
}
