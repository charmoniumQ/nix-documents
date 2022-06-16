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
          nix-documents-lib = nix-documents.lib.${system};
          nix-utils-lib = nix-utils.lib.${system};
          nix-utils-pkgs = nix-utils.packages.${system};
          nix-lib = nixpkgs.lib;
        in
          rec {
            formatter = pkgs.nixpkgs-fmt;

            packages = nix-utils-lib.packageSet [
              (lib.graphvizFigure {
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

              (lib.markdownDocument {
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

                # Choose from https://github.com/citation-style-language/styles
                # without the `.csl`
                # This is the default
                cslStyle = "acm-sig-proceedings";

                # Should be a list of strings
                # This is the default
                pandocArgs = [];

                texlivePackages = {
                  inherit (pkgs.texlive)
                    fancyhdr
                    lastpage
                    # other TeXlive packages here
                    # See https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/tools/typesetting/tex/texlive/pkgs.nix
                    ;
                };

                # Other Nix package inputs
                inputs = [
                  self.packages."graphivz.svg"
                ];

                # See: https://pandoc.org/MANUAL.html#extension-yaml_metadata_block
                # This is the default
                yamlMetadataBlock = true;

                # Cite stuff with [@ciation_key].
                # Make sure to specify `bibliography` in YAML metadata block.
                # See:
                # - https://pandoc.org/MANUAL.html#citations
                # - https://pandoc.org/MANUAL.html#extension-citations
                # - https://github.com/pandoc/lua-filters/tree/master/cito
                # This is the default
                citeproc = true;

                # Write math with \\( x^2 + 4\\)
                # See https://pandoc.org/MANUAL.html#extension-tex_math_double_backslash
                # This is the default
                texMathDoubleBackslash = true;

                # Render all newlines within source as newlines.
                # https://pandoc.org/MANUAL.html#extension-hard_line_breaks
                # This is the default
                hardLineBreaks = false;

                # Renders :smile:
                # See https://pandoc.org/MANUAL.html#extension-emoji
                # This is the default
                emoji = true;

                # Renders footnotes using [^footnote-tag]
                # See https://pandoc.org/MANUAL.html#extension-footnotes
                # This is the default
                footnotes = true;

                # Pass backslash commands to TeX
                # See https://pandoc.org/MANUAL.html#extension-raw_tex
                rawTex = false;

                # Multiline Markdown tables
                # See https://pandoc.org/MANUAL.html#extension-multiline_tables
                multilineTables = true;

                # Write a caption as `Table: This is a caption` immediately after a blank line after a table.
                # See https://pandoc.org/MANUAL.html#extension-table_captions
                tableCaptions = true;

                # Enable ~~strikeout text~~
                # https://pandoc.org/MANUAL.html#extension-strikeout
                strikeout = true;

                # See https://github.com/pandoc/lua-filters/tree/master/abstract-to-meta
                # This is the default
                abstractToMeta = true;

                # Allow \newpage
                # https://github.com/pandoc/lua-filters/tree/master/pagebreak
                # This is the default
                pagebreak = true;

                # Process citations with the CiTO vocabularly, like
                # [@evidence:biblatex_key]
                # https://github.com/pandoc/lua-filters/tree/master/cito
                # This is the default
                cito = true;
              })


              (lib.markdownDocument {
                src = ./markdown;
                pdfEngine = "xelatex";
                name = "markdown-xelatex.pdf";
              })

              # (lib.markdownDocument {
              #   src = ./markdown;
              #   pdfEngine = "lualatex";
              #   name = "markdown-document-lualatex.pdf";
              # })

              (lib.markdownDocument {
                src = ./markdown;
                pdfEngine = "context";
                name = "markdown-context.pdf";
              })

              (lib.latexDocument {
                src = ./latex;
                name = "pdflatex.pdf";
                texEngine = "pdflatex";
                texlivePackages = { inherit (pkgs.texlive) fancyhdr; };
              })

              # (lib.latexDocument {
              #   src = ./latex;
              #   name = "lualatex.pdf";
              #   texEngine = "lualatex";
              #   texlivePackages = { inherit (pkgs.texlive) fancyhdr; };
              # })

              (lib.latexDocument {
                src = ./latex;
                name = "xelatex.pdf";
                texEngine = "xelatex";
                texlivePackages = { inherit (pkgs.texlive) fancyhdr; };
              })

              (nix-utils-lib.mergeDerivations {
                name = "examples";
                packageSet = nix-utils-lib.packageSet [
                  
                ];
              })
            ] ++
            (if system == "i686-linux" then [ ] else [
              (lib.plantumlFigure {
                src = ./plantuml;
                name = "plantuml.svg";
              })
            ]);

            checks = {
              # Check multiple outputs and layouts in Graphviz
              # Check multiple outputs and engines in Markdown
            };
          }
      );
}
