{
  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    nix-utils = {
      url = "path:/home/sam/box/nix-utils";
      # url = "github:charmoniumQ/nix-utils";
    };
  };
  outputs = { self, nixpkgs, flake-utils, nix-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nix-utils-lib = nix-utils.lib.${system};
        nix-utils-pkgs = nix-utils.packages.${system};
        nix-lib = nixpkgs.lib;
      in
      rec {
        lib = rec {

          graphvizFigure =
            { src
            , name ? builtins.baseNameOf src
            , main ? "index.dot"

              # See https://graphviz.org/docs/outputs/
            , outputFormat ? "svg"

              # See https://graphviz.org/docs/layouts/
            , layoutEngine ? "dot"

            , vars ? { }
            , graphvizArgs ? [ ]

              # Nix packages will be accessible in the source directory by the derivation.name
            , inputs ? [ ]
            }:
            pkgs.stdenv.mkDerivation {
              inherit name;
              src = nix-utils-lib.mergeDerivations {
                packageSet = {
                  "." = [(nix-utils-lib.srcDerivation {inherit src;})] ++ inputs;
                };
              };
              buildPhase = ''
                ${pkgs.graphviz}/bin/dot \
                   -K${layoutEngine} \
                   -T${outputFormat} \
                   ${nix-lib.strings.escapeShellArgs (
                     nix-lib.attrsets.mapAttrsToList
                       (name: value: "-G${name}=${value}")
                       vars)} \
                   ${nix-lib.strings.escapeShellArgs graphvizArgs} \
                   -o$out \
                   $src/${main}
              '';
              phases = [ "unpackPhase" "buildPhase" ];
            };

          plantumlFigure =
            { src
            , name ? builtins.baseNameOf src
            , main ? "index.puml"

            # See https://plantuml.com/command-line
            , outputFormat ? "svg"
            , plantumlArgs ? [ ]

              # Nix packages will be accessible in the source directory by the derivation.name
            , inputs ? [ ]
            }:
            pkgs.stdenv.mkDerivation {
              inherit name;
              src = nix-utils-lib.mergeDerivations {
                packageSet = {
                  "." = [(nix-utils-lib.srcDerivation {inherit src;})] ++ inputs;
                };
              };
              FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ ]; };
              GRAPHVIZ_DOT = "${pkgs.graphviz}/bin/dot";
              buildPhase = ''
                tmp=$(mktemp --directory)
                ${pkgs.plantuml}/bin/plantuml \
                  -t${outputFormat} \
                  -o$tmp \
                  ${nix-lib.strings.escapeShellArgs plantumlArgs} \
                  $src/${main}
                mv $tmp/* $out
              '';
              phases = [ "unpackPhase" "buildPhase" ];
            };

          # TODO: User should be able to specify Lua filters, Haskell filters.
          markdownDocument =
            { src
            , name ? null
            , main ? "index.md"
            , inputs ? nix-utils-pkgs.empty
            , pdfEngine ? "context"
            , outputFormat ? "pdf" # passed to Pandoc
            , cslStyle ? "acm-sig-proceedings" # from CSL styles repo
            , pandocArgs ? [ ]
            , template ? null
            , texlivePackages ? { }
              # nixPackages will be accessible on the $PATH
            , nixPackages ? [ ]
              # Nix package inputs will be accessible in the source directory by the derivation.name
            , inputs ? [ ]
              # Pandoc Markdown extensions:
            , yamlMetadataBlock ? true
            , citeproc ? true
            , texMathDollars ? true
            , rawTex ? true
            , multilineTables ? true
              # pandoc-lua-filters to apply:
            , abstractToMeta ? true
            , pagebreak ? true
            , pandocCrossref ? true
            , cito ? true
            }:
            let
              pandocMarkdownWithExtensions =
                "markdown"
                + (if yamlMetadataBlock then "+yaml_metadata_block" else "")
                + (if citeproc then "+citations" else "")
                + (if texMathDollars then "+tex_math_dollars" else "")
                + (if rawTex then "+raw_tex" else "")
                + (if multilineTables then "+multiline_tables" else "")
              ;
              pandocLuaFiltersPath = "${pkgs.pandoc-lua-filters}/share/pandoc/filters";
              pdfEngineTexlivePackages = {
                context = { inherit (pkgs.texlive) scheme-context; };
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
                lualatex = builtins.throw "Not yet supported";
                # lualatex = {inherit (pkgs.texlive) scheme-basic;};
                tectonic = builtins.throw "Not yet supported";
                # tectonic = {inherit (pkgs.texlive) scheme-basic;};
                latexmk = builtins.throw (
                  "I can't see a reason to use latexmk when Pandoc will take"
                  + " care of running latex multiple times"
                );
                xelatex = { inherit (pkgs.texlive) scheme-small; };
              };
              pdfEngineNixPackages = {
                tectonic = [ pkgs.tectonic ];
              };
            in
            pkgs.stdenv.mkDerivation {
              name = nix-utils-lib.default name (builtins.baseNameOf src);
              src = nix-utils-lib.mergeDerivations {
                packageSet = {
                  "." = [(nix-utils-lib.srcDerivation {inherit src;})] ++ inputs;
                };
              };
              buildInputs = (
                [
                  pkgs.librsvg # requried to including svg images
                  (pkgs.texlive.combine
                    ((
                      nix-utils-lib.getAttrOr
                        pdfEngineTexlivePackages
                        pdfEngine
                        { }
                    )
                    // texlivePackages))
                ]
                ++ nixPackages
                ++ (nix-utils-lib.getAttrOr pdfEngineNixPackages pdfEngine [ ])
              );
              FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ ]; };
              buildPhase = ''
                for input in $src/* ${inputs}/*; do
                  cp --recursive $input .
                done
                ${pkgs.pandoc}/bin/pandoc \
                  --from=${pandocMarkdownWithExtensions} \
                  ${if abstractToMeta then "--lua-filter=${pandocLuaFiltersPath}/abstract-to-meta.lua" else ""} \
                  ${if pagebreak then "--lua-filter=${pandocLuaFiltersPath}/pagebreak.lua" else ""} \
                  ${if cito then "--lua-filter=${pandocLuaFiltersPath}/cito.lua" else ""} \
                  ${if pandocCrossref then "--filter=${pkgs.haskellPackages.pandoc-crossref}/bin/pandoc-crossref" else ""} \
                  ${if citeproc then "--citeproc" else ""} \
                  --csl=${packages.citation-style-language-styles}/${cslStyle}.csl \
                  --pdf-engine=${pdfEngine} \
                  --to=${outputFormat} \
                  --output=$out \
                  ${if builtins.isNull template then "" else "--template=${template}"} \
                  ${nix-lib.strings.escapeShellArgs pandocArgs} \
                  ${main}
              '';
              phases = [ "unpackPhase" "buildPhase" ];
            };

          # TODO: support LuaTeX document
        };

        formatter = pkgs.nixpkgs-fmt;

        packages = nix-utils-lib.packageSet [
          (pkgs.fetchFromGitHub {
            owner = "hakimel";
            repo = "reveal.js";
            rev = "039972c730690af7a83a5cb832056a7cc8b565d7";
            hash = "sha256-X43lsjoLBWmttIKj9Jzut0UP0dZlsue3fYbJ3++ojbU=";
            name = "reveal-js";
          })

          (pkgs.fetchFromGitHub {
            owner = "rajgoel";
            repo = "reveal.js-plugins";
            rev = "a90372093213587e27ac9b17f5d981414934143e";
            hash = "sha256-4wM0VotPmrgrxarocJxYXa/v+wo/8rREwBj/QNZTj08=";
            name = "reveal-js-plugins";
          })

          (pkgs.fetchFromGitHub {
            owner = "citation-style-language";
            repo = "styles";
            rev = "3602c18c16d51ff5e4996c2c7da24ea2cc5e546c";
            hash = "sha256-X+iRAt2Yzp1ePtmHT5UJ4MjwFVMu2gixmw9+zoqPq20=";
            name = "citation-style-language-styles";
          })

          (nix-utils-lib.mergeDerivations {
            name = "examples";
            packageSet = nix-utils-lib.packageSet (
              (if system == "i686-linux" then [ ] else [
                (lib.plantumlFigure {
                  src = ./tests/plantuml;
                  name = "plantuml.svg";
                })
              ]) ++ [
                (lib.graphvizFigure {
                  src = ./tests/graphviz;
                  name = "graphviz.svg";
                  vars = {
                    hello = "world";
                  };
                })

                (lib.markdownDocument {
                  src = ./tests/markdown;
                  pdfEngine = "pdflatex";
                  name = "markdown-pdflatex.pdf";
                })

                (lib.markdownDocument {
                  src = ./tests/markdown;
                  pdfEngine = "xelatex";
                  name = "markdown-xelatex.pdf";
                })

                # (lib.markdownDocument {
                #   src = ./tests/markdown;
                #   pdfEngine = "lualatex";
                #   name = "markdown-document-lualatex.pdf";
                # })

                # (lib.markdownDocument {
                #   src = ./tests/markdown;
                #   pdfEngine = "tectonic";
                #   name = "markdown-document-tectonic.pdf";
                # })

                (lib.markdownDocument {
                  src = ./tests/markdown;
                  pdfEngine = "context";
                  name = "markdown-context.pdf";
                })
              ]
            );
          })
        ];

        checks = { } // packages;
      }
    ) // {
      templates = {
        default = {
          path = ./templates/markdown;
          description = "Template for making documents as a Nix Flake";
        };
      };
    };

  # TODO: Fix fontconfig error
  # Fontconfig error: No writable cache directories
}
