{
  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    nix-utils = {
      # url = "path:/home/sam/box/nix-utils";
      url = "github:charmoniumQ/nix-utils";
    };
  };
  outputs = { self, nixpkgs, flake-utils, nix-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nix-utils-lib = nix-utils.lib.${system};
          nix-utils-pkgs = nix-utils.packages.${system};
          nix-lib = nixpkgs.lib;
          checkUniqueGlob = glob: program: ''
            num_files=0
            for file in ${glob}; do
              if [ $num_files -ne 0 ]; then
                echo "Aborting: ${program} generated more than one ${glob} file"
                exit 1
              fi
              num_files=1
            done
          '';
        in
        rec {
          lib = rec {

            graphvizFigure =
              { src
              , name ? builtins.baseNameOf src
              , main ? "index.dot"
              , outputFormat ? "svg"
              , layoutEngine ? "dot"
              , vars ? { }
              , graphvizArgs ? [ ]
              , inputs ? [ ]
              }:
              pkgs.stdenv.mkDerivation {
                inherit name;
                src = nix-utils-lib.mergeDerivations {
                  packageSet = {
                    "." = nix-utils-lib.srcDerivation { inherit src; };
                  } // nix-utils-lib.packageSet inputs;
                };
                FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ ]; };
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
                     $src/${nix-lib.strings.escapeShellArg main}
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
                    "." = nix-utils-lib.srcDerivation { inherit src; };
                  } // nix-utils-lib.packageSet inputs;
                };
                FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ ]; };
                GRAPHVIZ_DOT = "${pkgs.graphviz}/bin/dot";
                buildPhase = ''
                  tmp=$(mktemp --directory)
                  ${pkgs.plantuml}/bin/plantuml \
                    -t${outputFormat} \
                    -o$tmp \
                    ${nix-lib.strings.escapeShellArgs plantumlArgs} \
                    $src/${nix-lib.strings.escape main}
                  ${checkUniqueGlob "$tmp/*" "plantuml"}
                  mv $tmp/* $out
                '';
                phases = [ "unpackPhase" "buildPhase" ];
              };

            # TODO: User should be able to specify Lua filters, Haskell filters.
            markdownDocument =
              { src ? builtins.baseNameOf src
              , name ? null
              , main ? "index.md"
              , pdfEngine ? "xelatex"
              , outputFormat ? "pdf"
              # date is needed if you want a deterministic document
              , date ? null
              , metadata-files ? []
              , metadata-vars ? {}
              , filters ? [
                "${pkgs.pandoc-lua-filters}/share/pandoc/filters/abstract-to-meta.lua"
                "${pkgs.pandoc-lua-filters}/share/pandoc/filters/pagebreak.lua"
                "${pkgs.pandoc-lua-filters}/share/pandoc/filters/cito.lua"
                "${pkgs.haskellPackages.pandoc-crossref}/bin/pandoc-crossref"
                "citeproc"
              ]
              , texlivePackages ? { }
              # nixPackages will be accessible on the $PATH
              , nixPackages ? [ ]
              # Nix package inputs will be accessible in the source directory by the derivation.name
              , inputs ? [ ]
              }:
              let
                pdfEngineTexlivePackages = rec {
                  context = { inherit (pkgs.texlive) scheme-context; };
                  pdflatex = {
                    inherit (pkgs.texlive)
                      scheme-basic
                      amsfonts
                      amsmath
                      lm
                      unicode-math
                      iftex
                      fancyvrb
                      #longable
                      booktabs
                      graphics
                      hyperref
                      xcolor
                      ulem
                      geometry
                      setspace
                      babel
                      fontspec
                      selnolig
                      upquote
                      microtype
                      parskip
                      bookmark
                      xetex
                      luatex
                      mdwtools # (footnote)
                      svg
                      koma-script
                      etoolbox
                      subfig
                      caption
                      float
                      # Client should add if you need:
                      # bidi
                      # xecjk
                      # mathspec
                      # csquotes
                      # listings
                    ;
                  };
                  xelatex = pdflatex;
                  lualatex = pdflatex;
                };
                pdfEngineNixPackages = {
                  tectonic = [ pkgs.tectonic ];
                };
                toPandocFilterArg = filter:
                  if builtins.isAttrs filter
                  then nix-utils-lib.getAttrOr {
                    json = "--filter=${filter.path}";
                    lua = "--lua-filter=${filter.path}";
                    citeproc = "--citeproc";
                  } filter.type (throw "Unsupported filter type ${filter.type}")
                  else
                    if filter == "citeproc"
                    then "--citeproc"
                    else
                      if nix-lib.strings.hasSuffix ".lua" filter
                      then "--lua-filter=${filter}"
                      else "--filter=${filter}"
                ;
              in
              pkgs.stdenv.mkDerivation {
                inherit name;
                src = nix-utils-lib.mergeDerivations {
                  packageSet = {
                    "." = nix-utils-lib.srcDerivation { inherit src; };
                  } // nix-utils-lib.packageSet inputs;
                };
                buildInputs = (
                  [
                    pkgs.librsvg # requried to including svg images
                    (pkgs.texlive.combine
                      ((
                        nix-utils-lib.getAttrOr
                          pdfEngineTexlivePackages
                          pdfEngine
                          (builtins.throw "Unknown pdfEngine ${pdfEngine}")
                      )
                      // texlivePackages))
                  ]
                  ++ nixPackages
                  ++ (nix-utils-lib.getAttrOr pdfEngineNixPackages pdfEngine [ ])
                );
                FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ ]; };
                buildPhase = ''
                  ${
                    if builtins.isNull date
                    then ""
                    else "export SOURCE_DATE_EPOCH=${builtins.toString date}"}
                  ${nix-lib.strings.escapeShellArgs (builtins.concatLists [
                    [
                      "${pkgs.pandoc}/bin/pandoc"
                      "--pdf-engine=${pdfEngine}"
                      "--to=${outputFormat}"
                      main
                    ]
                    (builtins.map
                      (mfile: "--metadata-file=${mfile}")
                      metadata-files)
                    (nix-lib.attrsets.mapAttrsToList
                      (mvar: mval: "--metadata=${mvar}:${mval}")
                      metadata-vars)
                    (builtins.map toPandocFilterArg filters)
                  ])} --output=$out
                '';
                phases = [ "unpackPhase" "buildPhase" ];
              };
            # TODO: turn on --citeproc selectively
            # Fix the paths in index.md

            latexDocument =
              { src
              , name ? builtins.baseNameOf src
              , texEngine ? "xelatex"
              , main ? "index.tex"
              , texlivePackages ? { }
              , bibliography ? true
              , fullOutput ? false
              , Werror? false
                # Nix packages will be accessible in the source directory by the derivation.name
              , inputs ? [ ]
              }:
              let
                mainStem = nix-lib.strings.removeSuffix ".tex" main;
                allTexlivePackages =
                  { inherit (pkgs.texlive) scheme-basic collection-xetex latexmk; }
                  // (if bibliography
                      then { inherit (pkgs.texlive) collection-bibtexextra; }
                      else { })
                  // texlivePackages;
                latexmkFlagForTexEngine = {
                  "xelatex" = "-pdfxe";
                  "lualatex" = "-pdflua";
                  "pdflatex" = "-pdf";
                };
              in
              pkgs.stdenv.mkDerivation {
                inherit name;
                src = nix-utils-lib.mergeDerivations {
                  packageSet = {
                    "." = nix-utils-lib.srcDerivation { inherit src; };
                  } // nix-utils-lib.packageSet inputs;
                };
                buildInputs = [
                  (pkgs.texlive.combine allTexlivePackages)
                ];
                FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ ]; };
                buildPhase = ''
                  tmp=$(mktemp --directory)
                  set +e
                  latexmk \
                     ${builtins.getAttr texEngine latexmkFlagForTexEngine} \
                     -emulate-aux-dir \
                     -outdir=$tmp \
                     -auxdir=$tmp \
                     ${if Werror then "-Werror" else ""} \
                     ${nix-lib.strings.escape mainStem}
                  latexmk_status=$?
                  set -e
                  if [ $latexmk_status -ne 0 ]; then
                    cat $out/${nix-lib.strings.escape mainStem}.log
                    echo "Aborting: Latexmk failed"
                    exit $latexmk_status
                  fi
                  ${if fullOutput
                    then "mv $tmp/* $out"
                    else "mv $tmp/${nix-lib.strings.escape mainStem}.pdf $out"}
                '';
                phases = [ "unpackPhase" "buildPhase" ];
              };

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
  # TODO: Default name should have correct suffix
  # TODO: Example of using inputs
  # TODO: pygmentsTexFigure
  # TODO: dvi2svg https://dvisvgm.de/
}
