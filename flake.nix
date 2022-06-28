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
                buildPhase = nix-utils-lib.listOfListOfArgs [
                  [
                    "${pkgs.graphviz}/bin/dot"
                    "-K${layoutEngine}"
                    "-T${outputFormat}"
                    (nix-lib.attrsets.mapAttrsToList
                      (name: value: "-G${name}=${value}")
                      vars)
                    graphvizArgs
                    { literal = "-o$out"; }
                    { literal = "$src/${nix-lib.strings.escapeShellArg main}"; }
                  ]
                ];
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
                  ${nix-utils-lib.listOfListOfArgs [
                    [
                      "${pkgs.plantuml}/bin/plantuml"
                      "-t${outputFormat}"
                      plantumlArgs
                      { literal = "-o$tmp"; }
                      { literal = "$src/${nix-lib.strings.escapeShellArg main}"; }
                    ]
                  ]}
                  ${checkUniqueGlob "$tmp/*" "plantuml"}
                  mv $tmp/* $out
                '';
                phases = [ "unpackPhase" "buildPhase" ];
              };

            # See https://pandoc.org/MANUAL.html#creating-a-pdf
            pandocTexlivePackages = {
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
                xurl
                bookmark
                mdwtools# (footnote)
                xetex
                luatex
                svg
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

            # TODO: User should be able to specify Lua filters, Haskell filters.
            markdownDocument =
              { src ? builtins.baseNameOf src
              , name ? null
              , main ? "index.md"
              , pdfEngine ? "xelatex"
              , outputFormat ? "pdf"
                # date is needed if you want a deterministic document
              , date ? null
              , metadata-files ? [ ]
              , metadata-vars ? { }
              , citeproc ? true
              , filters ? [
                  "${pkgs.pandoc-lua-filters}/share/pandoc/filters/abstract-to-meta.lua"
                  "${pkgs.pandoc-lua-filters}/share/pandoc/filters/pagebreak.lua"
                  "${pkgs.pandoc-lua-filters}/share/pandoc/filters/cito.lua"
                  "${pkgs.haskellPackages.pandoc-crossref}/bin/pandoc-crossref"
                ] ++ (if citeproc then [ "citeproc" ] else [ ])
              , csl ? "${self.packages.${system}.citation-style-language-styles}/ieee-with-url.csl"
              , texlivePackages ? pandocTexlivePackages
              , pandocArgs ? [ ]
                # nixPackages will be accessible on the $PATH
              , nixPackages ? [ ]
                # Nix package inputs will be accessible in the source directory by the derivation.name
              , inputs ? [ ]
              }:
              let
                pdfEngineNixPackages = {
                  tectonic = [ pkgs.tectonic ];
                };
                toPandocFilterArg = filter:
                  if builtins.isAttrs filter
                  then
                    nix-utils-lib.getAttrOr
                      {
                        json = "--filter=${filter.path}";
                        lua = "--lua-filter=${filter.path}";
                        citeproc = "--citeproc";
                      }
                      filter.type
                      (builtins.throw "Unsupported filter type ${filter.type}")
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
                    (pkgs.texlive.combine texlivePackages)
                  ]
                  ++ nixPackages
                  ++ (nix-utils-lib.getAttrOr pdfEngineNixPackages pdfEngine [ ])
                );
                FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ ]; };
                buildPhase = ''
                  log=$(mktemp)
                  ${if builtins.isNull date
                    then ""
                    else "export SOURCE_DATE_EPOCH=${builtins.toString date}"}
                  set -x +e
                  ${nix-utils-lib.listOfListOfArgs [[
                    "${pkgs.pandoc}/bin/pandoc"
                    "--pdf-engine=${pdfEngine}"
                    "--to=${outputFormat}"
                    {literal="--output=$out";}
                    main
                    (if citeproc then "--csl=${csl}" else [])
                    (builtins.map
                      (mfile: "--metadata-file=${mfile}")
                      metadata-files)
                    (nix-lib.attrsets.mapAttrsToList
                      (mvar: mval: "--metadata=${mvar}:${mval}")
                      metadata-vars)
                    (builtins.map toPandocFilterArg filters)
                    "--verbose"
                    pandocArgs
                    {literal="2> $log";}
                  ]]}
                  pandoc_success=$?
                  set +x -e
                  if [ $pandoc_success -ne 0 ]; then
                    cat $log
                    exit $pandoc_success
                  fi
                '';
                phases = [ "unpackPhase" "buildPhase" ];
              };

            latexDocument =
              { src
              , name ? builtins.baseNameOf src
              , texEngine ? "xelatex"
              , main ? "index.tex"
              , texlivePackages ? { }
              , bibliography ? true
              , fullOutput ? false
              , Werror ? false
                # Nix packages will be accessible in the source directory by the derivation.name
              , inputs ? [ ]
              }:
              let
                mainStem = nix-lib.strings.removeSuffix ".tex" main;
                latexmkFlagForTexEngine = {
                  "xelatex" = "-pdfxe";
                  "lualatex" = "-pdflua";
                  "pdflatex" = "-pdf";
                };
                texlivePackagesForTexEngine = {
                  "xelatex" = { inherit (pkgs.texlive) latexmk scheme-basic collection-xetex; };
                  "lualatex" = { inherit (pkgs.texlive) latexmk scheme-basic collection-luatex; };
                  "pdflatex" = { inherit (pkgs.texlive) latexmk scheme-basic; };
                };
                allTexlivePackages =
                  (nix-utils-lib.getAttrOr texlivePackagesForTexEngine texEngine (builtins.throw "Unknown texEngine ${texEngine}"))
                  // (
                    if bibliography
                    then { inherit (pkgs.texlive) collection-bibtexextra; }
                    else { }
                  )
                  // texlivePackages;
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
                  ${nix-utils-lib.listOfListOfArgs [
                    [
                      "latexmk"
                      (builtins.getAttr texEngine latexmkFlagForTexEngine)
                      "-emulate-aux-dir"
                      {literal="-outdir=$tmp";}
                      {literal="-auxdir=$tmp";}
                      (if Werror then "-Werror" else [])
                      mainStem
                    ]
                  ]}
                  latexmk_status=$?
                  set -e
                  if [ $latexmk_status -ne 0 ]; then
                    cat $out/${nix-lib.strings.escapeShellArg mainStem}.log
                    echo "Aborting: Latexmk failed"
                    exit $latexmk_status
                  fi
                  ${if fullOutput
                    then "mv $tmp/* $out"
                    else "mv $tmp/${nix-lib.strings.escapeShellArg mainStem}.pdf $out"}
                '';
                phases = [ "unpackPhase" "buildPhase" ];
              };


            pygmentCodeFigure =
              { src
              , name ? builtins.baseNameOf src
              , main ? "index"
                # nix shell nixpkgs#python39Packages.pygments --command pygmentize -L lexer
              , lexer ? "auto"
                # nix shell nixpkgs#python39Packages.pygments --command pygmentize -L filter
              , filters ? [ ]
                # nix shell nixpkgs#python39Packages.pygments --command pygmentize -L formatter
                # Note that formatter options are applied specified directly in the formatter string
                # e.g. "keywordcase:case=upper"
              , formatter ? "tex"
                # nix shell nixpkgs#python39Packages.pygments --command pygmentize -L style
                # Options include stripnl, stripall, tabsize, encoding, outencoding, linenos, style, heading
              , options ? { }
              }:
              pkgs.stdenv.mkDerivation {
                inherit name;
                inherit src;
                buildPhase = nix-utils-lib.listOfListOfArgs [
                  [
                    "${pkgs.python39Packages.pygments}/bin/pygmentize"
                    "${src}/${main}"
                    (if lexer == "auto" then [ "-g" ] else [ "-l" lexer ])
                    [ "-f" formatter ]
                    (builtins.map (filter: "-F ${filter}") filters)
                    (nix-lib.attrsets.mapAttrsToList
                      (option: value: [ "-P" "${option}=${value}" ])
                      options)
                    [ "-o" { literal = "$out"; } ]
                  ]
                ];
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

            (nix-utils-lib.mergeDerivations {
              name = "examples";
              packageSet = nix-utils-lib.packageSetRec (self: [
                (lib.graphvizFigure {
                  src = ./examples-src/graphviz;

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
                  src = ./examples-src/markdown-bells-and-whistles;

                  # This is the default
                  main = "index.md";

                  # $(basename $src).$suffix by default
                  name = "markdown-xelatex.pdf";

                  # This is the default
                  # Currently, I support pdflatex, xelatex, and context
                  pdfEngine = "xelatex";

                  # This is the default
                  # See https://pandoc.org/MANUAL.html#option--to
                  outputFormat = "pdf";

                  # date is needed if you want a deterministic document
                  # specified in seconds since the Unix Epoch
                  date = 1655528400;

                  texlivePackages = lib.pandocTexlivePackages // {
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
                    self."graphviz.svg"
                  ];
                })

                (lib.markdownDocument {
                  src = ./examples-src/markdown-bells-and-whistles;
                  pdfEngine = "pdflatex";
                  name = "markdown-pdflatex.pdf";
                  inputs = [
                    self."graphviz.svg"
                  ];
                })
                /* 
                (lib.markdownDocument {
                  src = ./examples-src/markdown-bells-and-whistles;
                  pdfEngine = "lualatex";
                  name = "markdown-lualatex.pdf";
                  inputs = [
                    self."graphviz.svg"
                  ];
                }) */

                (lib.markdownDocument {
                  src = ./examples-src/markdown-bells-and-whistles;
                  pdfEngine = "context";
                  name = "markdown-context.pdf";
                  texlivePackages = lib.pandocTexlivePackages // {
                    inherit (pkgs.texlive) scheme-context;
                  };
                  inputs = [
                    self."graphviz.svg"
                  ];
                })

                (lib.latexDocument {
                  src = ./examples-src/latex;
                  name = "pdflatex.pdf";
                  texEngine = "pdflatex";
                  texlivePackages = { inherit (pkgs.texlive) fancyhdr; };
                  inputs = [
                    #self."pygment-code.tex"
                  ];
                })
                /* 
                (lib.latexDocument {
                  src = ./examples-src/latex;
                  name = "lualatex.pdf";
                  texEngine = "lualatex";
                  texlivePackages = { inherit (pkgs.texlive) fancyhdr; };
                  inputs = [
                    #self."pygment-code.tex"
                  ];
                }) */

                (lib.latexDocument {
                  src = ./examples-src/latex;
                  name = "xelatex.pdf";
                  texEngine = "xelatex";
                  texlivePackages = { inherit (pkgs.texlive) fancyhdr; };
                })
                /* 
                (lib.pygmentCodeFigure {
                  src = ./examples-src/pygmentize;
                  name = "pygment-code.tex";
                  main = "index.py";
                  lexer = "auto";
                  filters = ["whitespace"];
                  formatter = "tex";
                  options = {
                    style = "zenburn";
                    linenos = "True";
                    texcomments = "True";
                    mathescape = "True";
                  };
                })
                */

              ] ++ (if system == "i686-linux" then [ ] else [
                (lib.plantumlFigure {
                  src = ./examples-src/plantuml;
                  name = "plantuml.svg";
                })
              ]));
            })
          ];

          checks = { } // packages;
        }
      ) // {
      templates = {
        default = {
          path = ./templates;
          description = "Template for making documents as a Nix Flake";
        };
      };
    };

  # TODO: mergeDerivations should support source paths outside the Nix store by converting them to derivations.
  # TODO: packageSet should check for dups.
  # TODO: Use mergeDerivations'
  # TODO: Don't use inputs; client should define `src` as a merge instead.
  # TODO: Default name should have correct suffix
  # TODO: Check that file exists
  # TODO: Type check texLivePackages
  # TODO: dvi2svg https://dvisvgm.de/
  # TODO: Fix fontconfig error
  # Fontconfig error: No writable cache directories
}
