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

          checks = { } // packages;

          packages = nix-utils-lib.packageSetRec (self: [

            # Example of a figure:
            (nix-documents-lib.graphvizFigure {
              src = ./figure;
            })

            # Example of markdown document:
            (nix-documents-lib.markdownDocument {
              src = ./document-markdown;
              # xelatex > pdflatex, if you get to choose
              pdfEngine = "xelatex";
              texlivePackages = nix-documents-lib.pandocTexlivePackages // {
                inherit (pkgs.texlive)
                  fancyhdr
                  # other TeXlive packages here
                  # See https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/tools/typesetting/tex/texlive/pkgs.nix
                  ;
              };

              inputs = [
                # Example of including a figure:
                self."figure.svg"
              ];
            })

            # Example of a latex document:
            (nix-documents-lib.latexDocument {
              src = ./document-latex;

              # These options work the same way as in markdownDocument above.
              texEngine = "xelatex";
              texlivePackages = {
                inherit (pkgs.texlive) fancyhdr;
              };
              inputs = [ ];
            })

            (nix-utils-lib.mergeDerivations {
              name = "default";
              packageSet = (nix-utils-lib.packageSet [
                # Comment out if you don't need the figure separately.
                self."figure.svg"
                self."document-latex.pdf"
                self."document-markdown.pdf"
              ]);
            })
          ]);
        }
      );
}
