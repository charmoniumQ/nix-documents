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
    flake-utils.lib.eachDefaultSystem (system:
      let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
        nix-utils-lib = nix-utils.lib.${system};
        nix-utils-pkgs = nix-utils.packages.${system};
      in rec {
        lib = rec {

          graphviz-document =
            {src, name ? null, main ? "index.dot", output-format ? "svg" }:
            pkgs.stdenv.mkDerivation {
              name = nix-utils-lib.default name (builtins.baseNameOf src);
              inherit src;
              installPhase = ''
                ${pkgs.graphviz}/bin/dot $src/${main} -T${output-format} -o$out
              '';
            };

          plantuml-documents = 
            {src, name ? null, output-format ? "svg" }:
            pkgs.stdenv.mkDerivation {
              name = nix-utils-lib.default name (builtins.baseNameOf src);
              inherit src;
              installPhase = ''
                mkdir $out
                ${pkgs.plantuml}/bin/plantuml $src -t${output-format} -o$out
              '';
            };

          markdown-document =
            { src
            , name ? null
            , main ? "index.md"
            , inputs ? nix-utils-pkgs.empty
            , pdf-engine ? "context"
            , output-format ? "pdf" # passed to Pandoc
            , csl-style ? "acm-sig-proceedings" # from CSL styles repo
            # Pandoc Markdown extensions:
            , yaml-metadata-block ? true
            , citeproc ? true
            , tex-math-dollars ? true
            , raw-tex ? true
            , multiline-tables ? true
            # pandoc-lua-filters to apply:
            , abstract-to-meta ? true
            , pagebreak ? true
            , pandoc-crossref ? true
            , cito ? true
            , texlive-packages ? {}
            , nix-packages ? []
            }:
            let
              pandoc-markdown-with-extensions = 
                "markdown"
                + (if yaml-metadata-block then "+yaml_metadata_block" else "")
                + (if citeproc then "+citations" else "")
                + (if tex-math-dollars then "+tex_math_dollars" else "")
                + (if raw-tex then "+raw_tex" else "")
                + (if multiline-tables then "+multiline_tables" else "")
              ;
              pandoc-lua-filters-path = "${pkgs.pandoc-lua-filters}/share/pandoc/filters";
              pandoc-filters = 
                ""
                + (if abstract-to-meta
                   then " --lua-filter=${pandoc-lua-filters-path}/abstract-to-meta.lua"
                   else "")
                + (if pagebreak
                   then " --lua-filter=${pandoc-lua-filters-path}/pagebreak.lua"
                   else "")
                + (if cito
                   then " --lua-filter=${pandoc-lua-filters-path}/cito.lua"
                   else "")
                + (if pandoc-crossref
                   then " --filter=${pkgs.haskellPackages.pandoc-crossref}/bin/pandoc-crossref"
                   else "")
                + (if citeproc
                   then " --citeproc"
                   else "")
              ;
              pdf-engine-texlive-packages = {
                context = {inherit (pkgs.texlive) scheme-context;};
                pdflatex = {
                  inherit (pkgs.texlive)
                    scheme-basic
                    xcolor
                    xkeyval
                    titlesec
                    microtype
                    booktabs
                    etoolbox
                    mdwtools
                    svg
                    koma-script
                    trimspaces
                    transparent
                    pgf
                    fancyvrb
                    subfig
                    caption
                    float
                  ;
                };
                lualatex = {inherit (pkgs.texlive) scheme-basic;};
                tectonic = {inherit (pkgs.texlive) scheme-basic;};
                latexmk = builtins.throw (
                  "I can't see a reason to use latexmk when Pandoc will take"
                  + " care of running latex multiple times");
                xelatex = {inherit (pkgs.texlive) scheme-small;};
              };
              pdf-engine-nix-packages = {
                tectonic = [pkgs.tectonic];
              };
            in
            pkgs.stdenv.mkDerivation {
              name = nix-utils-lib.default name (builtins.baseNameOf src);
              # TODO: merge src with inputs here.
              inherit src;
              buildInputs = (
                [
                  pkgs.librsvg # requried to including svg images
                  (pkgs.texlive.combine
                    ((
                      nix-utils-lib.getAttrOr
                        pdf-engine-texlive-packages
                        pdf-engine {})
                    // texlive-packages))
                ]
                ++ nix-packages
                ++ (nix-utils-lib.getAttrOr pdf-engine-nix-packages pdf-engine [])
              );
              FONTCONFIG_FILE = pkgs.makeFontsConf {fontDirectories = []; };
              installPhase = ''
                for input in $src/* ${inputs}/*; do
                  cp --recursive $input .
                done
                ${pkgs.pandoc}/bin/pandoc \
                  --from=${pandoc-markdown-with-extensions} \
                  ${pandoc-filters} \
                  --csl=${packages.citation-style-language-styles}/${csl-style}.csl \
                  --pdf-engine=${pdf-engine} \
                  --to=${output-format} \
                  --output=$out \
                  ${main}
              '';
            }
          ;
        };

        formatter = pkgs.nixpkgs-fmt;

        packages = {

          revealjs = nix-utils-lib.raw-derivation {
            src = pkgs.fetchFromGitHub {
              owner = "hakimel";
              repo = "reveal.js";
              rev = "039972c730690af7a83a5cb832056a7cc8b565d7";
              hash = "sha256-X+iRAt2Yzp1ePtmHT5UJ4MjwFVMu2gixmw9+zoqPq20=";
            };
          };

          revealjs-plugins = nix-utils-lib.raw-derivation {
            src = pkgs.fetchFromGitHub {
              owner = "rajgoel";
              repo = "reveal.js-plugins";
              rev = "a90372093213587e27ac9b17f5d981414934143e";
              hash = "sha256-4wM0VotPmrgrxarocJxYXa/v+wo/8rREwBj/QNZTj08=";
            };
          };

          citation-style-language-styles = nix-utils-lib.raw-derivation {
            src = pkgs.fetchFromGitHub {
              owner = "citation-style-language";
              repo = "styles";
              rev = "3602c18c16d51ff5e4996c2c7da24ea2cc5e546c";
              hash = "sha256-X+iRAt2Yzp1ePtmHT5UJ4MjwFVMu2gixmw9+zoqPq20=";
            };
          };
        };

        checks = {
          plantuml-documents = nix-utils-lib.exists-in-derivation {
            deriv = lib.plantuml-documents {
              src = ./tests/plantuml;
            };
            paths = ["index.svg"];
          };
          graphviz-document = lib.graphviz-document {
            src = ./tests/graphviz;
          };
          markdown-document-pdflatex = lib.markdown-document {
            src = ./tests/markdown;
            pdf-engine = "pdflatex";
            name = "markdown-document-pdflatex";
          };
          markdown-document-xelatex = lib.markdown-document {
            src = ./tests/markdown;
            pdf-engine = "xelatex";
            name = "markdown-document-xelatex";
          };
          # markdown-document-lualatex = lib.markdown-document {
          #   src = ./tests/markdown;
          #   pdf-engine = "lualatex";
          #   name = "markdown-document-lualatex";
          # };
          # markdown-document-tectonic = lib.markdown-document {
          #   src = ./tests/markdown;
          #   pdf-engine = "tectonic";
          #   name = "markdown-document-tectonic";
          # };
          markdown-document-context = lib.markdown-document {
            src = ./tests/markdown;
            pdf-engine = "context";
            name = "markdown-document-context";
          };
        } // packages;
      }
    );
}
