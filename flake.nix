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
      in
      rec {
        lib = rec {

          graphvizFigure =
            { src
            , name ? builtins.baseNameOf src
            , main ? "index.dot"
            , output-format ? "svg"
            }:
            pkgs.stdenv.mkDerivation {
              inherit name;
              inherit src;
              installPhase = ''
                ${pkgs.graphviz}/bin/dot $src/${main} -T${output-format} -o$out
              '';
              phases = [ "unpackPhase" "installPhase" ];
            };

          # TODO: plantuml should just do one figure at a time.
          plantumlFigure =
            { src
            , name ? builtins.baseNameOf src
            , main ? "index.puml"
            , output-format ? "svg"
            }:
            pkgs.stdenv.mkDerivation {
              inherit name;
              inherit src;
              FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ ]; };
              installPhase = ''
                mkdir $out
                tmp=$(mktemp --directory)
                ${pkgs.plantuml}/bin/plantuml $src/${main} -t${output-format} -o$tmp
                mv $tmp/* $out
              '';
              phases = [ "unpackPhase" "installPhase" ];
            };

          # TODO: User should be able to specify Lua filters, Haskell filters.
          # TODO: User should be able to specify template.
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
            , texlivePackages ? { }
            , nixPackages ? [ ]
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
              myPandocArgs =
                ""
                + (if abstractToMeta
                then " --lua-filter=${pandocLuaFiltersPath}/abstract-to-meta.lua"
                else "")
                + (if pagebreak
                then " --lua-filter=${pandocLuaFiltersPath}/pagebreak.lua"
                else "")
                + (if cito
                then " --lua-filter=${pandocLuaFiltersPath}/cito.lua"
                else "")
                + (if pandocCrossref
                then " --filter=${pkgs.haskellPackages.pandoc-crossref}/bin/pandoc-crossref"
                else "")
                + (if citeproc
                then " --citeproc"
                else "")
              ;
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
              # TODO: merge src with inputs here.
              inherit src;
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
              installPhase = ''
                for input in $src/* ${inputs}/*; do
                  cp --recursive $input .
                done
                ${pkgs.pandoc}/bin/pandoc \
                  --from=${pandocMarkdownWithExtensions} \
                  ${myPandocArgs} \
                  --csl=${packages.citation-style-language-styles}/${cslStyle}.csl \
                  --pdf-engine=${pdfEngine} \
                  --to=${outputFormat} \
                  --output=$out \
                  ${builtins.concatStringsSep " " (builtins.map builtins.escapeShellArg pandocArgs)} \
                  ${main}
              '';
              phases = [ "unpackPhase" "installPhase" ];
            }
          ;

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
            packageSet = nix-utils-lib.packageSet [
              (lib.plantumlFigure {
                src = ./tests/plantuml;
                name = "example-plantuml";
              })

              (lib.graphvizFigure {
                src = ./tests/graphviz;
                name = "example-graphviz.svg";
              })

              (lib.markdownDocument {
                src = ./tests/markdown;
                pdfEngine = "pdflatex";
                name = "example-markdown-pdflatex.pdf";
              })

              (lib.markdownDocument {
                src = ./tests/markdown;
                pdfEngine = "xelatex";
                name = "example-markdown-xelatex.pdf";
              })

              # (lib.markdownDocument {
              #   src = ./tests/markdown;
              #   pdfEngine = "lualatex";
              #   name = "example-markdown-document-lualatex.pdf";
              # })

              # (lib.markdownDocument {
              #   src = ./tests/markdown;
              #   pdfEngine = "tectonic";
              #   name = "example-markdown-document-tectonic.pdf";
              # })

              (lib.markdownDocument {
                src = ./tests/markdown;
                pdfEngine = "context";
                name = "example-markdown-context.pdf";
              })
            ];
          })
        ];

        checks = { } // packages;
      }
    );
}
