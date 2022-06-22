{
  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    nix-utils = {
      url = "github:charmoniumQ/nix-utils";
    };
    nix-documents = {
      # url = "github:charmoniumQ/nix-documents";
      url = "..";
    };
  };
  outputs = { self, nixpkgs, flake-utils, nix-utils, nix-documents }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nix-documents-lib = nix-documents.lib.${system};
          nix-utils-lib = nix-utils.lib.${system};
          nix-utils-pkgs = nix-utils.packages.${system};
          nix-lib = nixpkgs.lib;
        in
        rec {
          formatter = pkgs.nixpkgs-fmt;

          packages = nix-utils-lib.packageSet ([
              (nix-documents-lib.graphvizFigure {
                src = ./graphviz;

                # Will be `$(basename $src).$outputFormat` by default.
                name = "graphviz.svg";

                # This is the default
                main = "index.dot";

                # See https://graphviz.org/docs/outputs/
                # This is the default
                outputFormat = "svg";

                # This is the default
                # See https://graphviz.org/docs/layouts/
                layoutEngine = "dot";

                # Will be empty by default.
                vars = {
                  hello = "world";
                };

                # Nix derivations, accessible in $src by their derivation name
                # This is the default
                inputs = [ ];
              })

              (nix-documents-lib.markdownDocument {
                src = ./markdown;

                # This is the default
                main = "index.md";

                # $(basename $src).$suffix by default
                name = "markdown-pdflatex.pdf";

                # This is the default
                # Currently, I support pdflatex, xelatex, and context
                pdfEngine = "xelatex";

                # This is the default
                # See https://pandoc.org/MANUAL.html#option--to
                outputFormat = "pdf";

                # date is needed if you want a deterministic document
                # specified in seconds since the Unix Epoch
                date = 1655528400;

                texlivePackages = {
                  inherit (pkgs.texlive)
                    fancyhdr
                    # other TeXlive packages here
                    # See https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/tools/typesetting/tex/texlive/pkgs.nix
                    ;
                };

                # nixPackages will be accessible on the $PATH
                nixPackages = [ ];

                # Nix package inputs will be accessible in the source directory by the derivation.name
                inputs = [
                  self.packages.${system}."graphviz.svg"
                ];

                # Should be a list of strings
                # Avoid using this option if you can.
                # Instead use dedicated Nix parameters or set metadata variables in YAML
                # This is the default
                pandocArgs = [ ];
              })


              (nix-documents-lib.markdownDocument {
                src = ./markdown;
                pdfEngine = "xelatex";
                name = "markdown-xelatex.pdf";
              })

              # (nix-documents-lib.markdownDocument {
              #   src = ./markdown;
              #   pdfEngine = "lualatex";
              #   name = "markdown-document-lualatex.pdf";
              # })

              (nix-documents-lib.markdownDocument {
                src = ./markdown;
                pdfEngine = "context";
                name = "markdown-context.pdf";
              })

              (nix-documents-lib.latexDocument {
                src = ./latex;
                name = "pdflatex.pdf";
                texEngine = "pdflatex";
                texlivePackages = { inherit (pkgs.texlive) fancyhdr; };
              })

              # (nix-documents-lib.latexDocument {
              #   src = ./latex;
              #   name = "lualatex.pdf";
              #   texEngine = "lualatex";
              #   texlivePackages = { inherit (pkgs.texlive) fancyhdr; };
              # })

              (nix-documents-lib.latexDocument {
                src = ./latex;
                name = "xelatex.pdf";
                texEngine = "xelatex";
                texlivePackages = { inherit (pkgs.texlive) fancyhdr; };
              })

              (nix-utils-lib.mergeDerivations {
                name = "examples";
                packageSet = nix-utils-lib.packageSet [
                  self.packages.${system}."graphviz.svg"
                  self.packages.${system}."markdown-pdflatex.pdf"
                ];
              })
            ] ++ (if system == "i686-linux" then [ ] else [
              (nix-documents-lib.plantumlFigure {
                src = ./plantuml;
                name = "plantuml.svg";
              })
            ]))
          ;

          checks = {
            # Check multiple outputs and layouts in Graphviz
            # Check multiple outputs and engines in Markdown
          };
        }
      );
}
