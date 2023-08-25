pkgs: nix-lib: nix-utils-lib:
rec {
  lib = rec {
    /*
      I based this off of the excellent [pandoc-scholar], which adds extensions for academic writing:

      - citation counting
      - figure numbering
      - figure captions
      - math-mode
      - support for an abstract
      - citation processing and bibliography generation
      - citation typing ontology [CiTO] annotations

      [CiTO]: https://sparontologies.github.io/cito/current/cito.html

      Writing Markdown has several advantages to writing raw LaTeX:

      - The syntax is prettier.
      - You don't have to run the compiler multiple times to get the right output.
      - Extensions can be written in Haskell or Lua, which are both "nicer" than the TeX language.
      - The output is equally pretty, since Pandoc uses ConTeXt, XeTeX, LuaTeX, or pdfLaTeX under the hood.
      - You can still drop down to raw LaTeX from Markdown, if you must: either using LaTeX to generate a figure or embedding LaTeX commands in Markdown.
      - You can output to more formats, including docx, EPUB, ODT, HTML, and others.

      See [examples-src/markdown-bells-and-whistles/index.md] for an example which compiles to [examples/markdown-xelatex.pdf] or [examples/markdown-context.pdf].

      src: the directory of compile-time sources.
      main: the main file to compile.
      name: the name of the resulting derivation. I suggest using the filename with extension.
      pdfEngine: see [pandoc pdfengines]. Currently only pdflatex, xelatex, lualatex, and context are supported.
      outputFormat: See [pandoc output formats].
      date: set the date in seconds since the start of 1970 in UTC. This is needed to make the document reproducible. See [pandoc reproducibile builds].
      metadata-files: List of YAML metadata files. See [pandoc metadata files].
      metadata-vars: attrset (dict) of metadata variables. See [pandoc metadata variables].
      citeproc: whether to run Pandoc's citation processor. See [pandoc citeproc].
      csl: a Citation Style Language template for formatting bibliographies. See [CSL style repo] and the citation-style-language-styles package in this repo.
      filters: a list of either strings (like "my_filter.lua") or attrs (like {"lua" = "my_filter.lua"}). For strings, the type of filter is inferred by the filename. See [pandoc filters] and [pandoc lua filters].
      texlivePackages: an attrset (dict) of package names to texlive packages. Search for your package on [CTAN], find the "in TeXLive as" field, search for that package in [Nix TeXlive], and if that exists, include pkgs.texlive.$package.
      pandocArgs: list of strings passed directly to pandoc.
      nixPackages: Nix packages to load in the build sandbox.

      [pandoc pdfengines]: https://pandoc.org/MANUAL.html#option--pdf-engine
      [pandoc ouput formats]: https://pandoc.org/MANUAL.html#option--to
      [pandoc reproducible builds]: https://pandoc.org/MANUAL.html#reproducible-builds
      [pandoc metadata files]: https://pandoc.org/MANUAL.html#option--metadata-file
      [pandoc metadata vars]: https://pandoc.org/MANUAL.html#option--metadata
      [pandoc citeproc]: https://pandoc.org/MANUAL.html#citation-rendering
      [pandoc filters]: https://pandoc.org/MANUAL.html#option--filter
      [pandoc lua filters]: https://pandoc.org/MANUAL.html#option--lua-filter
      [CTAN]: https://ctan.org/search?phrase=
      [Nix TeXlive]: https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/tools/typesetting/tex/texlive/tlpdb.nix
    */
    markdownDocument =
      { src
      , main ? "index.md"
      , name ? "${builtins.baseNameOf src}.${outputFormat}"
      , pdfEngine ? "xelatex"
      , outputFormat ? "pdf"
      , date ? null
      , metadata-files ? [ ]
      , metadata-vars ? { }
      , citeproc ? true
      , csl ? "${packages.citation-style-language-styles}/ieee-with-url.csl"
      , filters ? [
          "${pkgs.pandoc-lua-filters}/share/pandoc/filters/abstract-to-meta.lua"
          "${pkgs.pandoc-lua-filters}/share/pandoc/filters/pagebreak.lua"
          "${pkgs.pandoc-lua-filters}/share/pandoc/filters/cito.lua"
          "${pkgs.haskellPackages.pandoc-crossref}/bin/pandoc-crossref"
        ] ++ (if citeproc then [ "citeproc" ] else [ ])
      , texlivePackages ? pandocTexlivePackages
      , pandocArgs ? [ ]
        # nixPackages will be accessible on the $PATH
      , nixPackages ? [ ]
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
      pkgs.stdenvNoCC.mkDerivation {
        inherit name;
        inherit src;
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
          HOME=$(mktemp --directory)
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

    /*
      Runs latexmk on the document (reruns LaTeX engine until convergence).

      src: the directory containing all compile-time LaTeX source.
      main: the main file to compile.
      name: the name of the resulting derivation. I suggest using the filename with extension.
      texEngine: pdflatex, xelatex, or lualatex  (see [1], [2]). If you are unsure, just use XeLaTeX.
      bibliography: whether to add bibliographic packages
      fullOutput: whether to output a whole directory containing .log, .aux, and others or just a file containg the PDF.
      Werror: should LaTeX treat warnings as errors.
      texlivePackages: an attrset (dict) of package names to texlive packages. See [CTAN] and [Nix TeXlive] for package names.

      See [examples/xelatex.pdf], [examples/lualatex.pdf], and [examples/pdflatex.pdf].

      [1]: https://tex.stackexchange.com/questions/36/differences-between-luatex-context-and-xetex
      [2]: https://www.overleaf.com/learn/latex/Articles/The_TeX_family_tree%3A_LaTeX%2C_pdfTeX%2C_XeTeX%2C_LuaTeX_and_ConTeXt
      [CTAN]: https://ctan.org/
      [Nix TeXlive]: https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/tools/typesetting/tex/texlive/pkgs.nix
    */
    latexDocument =
      { src
      , main ? "index.tex"
      , name ? "${builtins.baseNameOf src}.pdf"
      , texEngine ? "xelatex"
      , texlivePackages ? { }
      , bibliography ? true
      , fullOutput ? false
      , Werror ? false
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
      pkgs.stdenvNoCC.mkDerivation {
        inherit name;
        inherit src;
        buildInputs = [
          (pkgs.texlive.combine allTexlivePackages)
        ];
        FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ ]; };
        buildPhase = ''
          tmp=$(mktemp --directory)
          HOME=$(mktemp --directory)
          set +e -x
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
          set -e +x
          if [ $latexmk_status -ne 0 ]; then
          cat $tmp/${nix-lib.strings.escapeShellArg mainStem}.log
          echo "Aborting: Latexmk failed"
          exit $latexmk_status
          fi
          ${if fullOutput
          then "mv $tmp/* $out"
          else "mv $tmp/${nix-lib.strings.escapeShellArg mainStem}.pdf $out"}
        '';
        phases = [ "unpackPhase" "buildPhase" ];
      };

    /*
      Outputs a directory containing HTML and assets for a reveal.js presentation.

      src: the directory containing HTML files and user-supplied assets. See <https://github.com/hakimel/reveal.js/blob/master/demo.html> for example.
      main: the main file to compile.
      name: the name of the resulting derivation, which contains a directory.
    */
    revealJsPresentation =
      { src
      , main ? "index.html"
      , name ? "${builtins.baseNameOf src}"
      }:
      nix-utils-lib.mergeDerivations {
        inherit name;
        packageSet = {
          "." = src;
          "dist" = packages.reveal-js;
          "plugin" = packages.reveal-js-default-plugins;
          "rajgoel-plugin" = packages.reveal-js-rajgoel-plugins;
        };
      };

    /*
      [Pygments] is a code-highlighting processor.

      Note, for the special case of embedding highlighted source in a LaTeX document, pygments can output LaTeX source (instead of an image). This sets your code in LaTeX fonts and allows you to use LaTeX math-mode in the source code. To do this, you will need to include the "style defs" in the preamble of your LaTeX document. See [examples-src/latex/index.tex] which compiles to [examples/xelatex.pdf] for an example. This has a number advantages over running the minted LaTeX package:
      
      - It doesn't have rerun `pygmentize` if the code didn't change (so it's faster)
      - It can generate SVG outputs for other document types (e.g. HTML).
      - You don't need to enable `-shell-escape`, which is insecure
      - You don't need to depend on other programs installed on the system

      src: the directory containing all compile-time source.
      main: the main file to highlight.
      name: the name of the resulting derivation. I suggest using the filename with extension.
      lexer: lexer for the source language. See [pygments lexers].
      filters: a list of string filters. See [pygments filters]
      formatter: the output formatter determines the output type. See [pygments formatters]
      options: an attrset (dict) of options for the formatter. See [pygments formatters]
      pygmetnArgs: arguments passed directly to pygmentize. See [pygments commandline].

      [Pygments]: https://pygments.org/
      [pygments lexers]: https://pygments.org/docs/lexers/
      [pygments filters]: https://pygments.org/docs/filters/
      [pygments formatters]: https://pygments.org/docs/formatters/
      [pygments commandline]: https://pygments.org/docs/cmdline/
    */
    pygmentCode =
      { src
      , name ? "${builtins.baseNameOf src}.${formatter}"
      , main ? "index"
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
      , pygmentArgs ? [ ]
      }:
      pkgs.stdenvNoCC.mkDerivation {
        inherit name;
        inherit src;
        buildPhase = nix-utils-lib.listOfListOfArgs [
          [ "set" "-x" ]
          [
            "${pkgs.python39Packages.pygments}/bin/pygmentize"
            "${src}/${main}"
            (if lexer == "auto" then [ "-g" ] else [ "-l" lexer ])
            [ "-f" formatter ]
            (builtins.map (filter: [ "-F" filter ]) filters)
            (nix-lib.attrsets.mapAttrsToList
              (option: value: [ "-P" "${option}=${value}" ])
              options)
            pygmentArgs
            [ "-o" { literal = "$out"; } ]
          ]
          [ "set" "+x" ]
        ];
        phases = [ "unpackPhase" "buildPhase" ];
      };

    /*
      If you use the Pygments HTML or LaTeX formatter, you need to include "style definitions" in your document.

      arg: a string passed directly to the formatter. See `get_style_defs()` for your formatter.
      style: see [pygment styles].

      See pygmentCode for other options.

      [pygment styles]: https://pygments.org/styles/
    */
    pygmentStyleDefs =
      { name
      , formatter ? "tex"
      , style ? "default"
      , arg ? ""
      , pygmentArgs ? [ ]
      , options ? { }
      }:
      pkgs.runCommand
        name
        { }
        (nix-utils-lib.listOfListOfArgs [
          [
            "${pkgs.python39Packages.pygments}/bin/pygmentize"
            [ "-S" style ]
            [ "-f" formatter ]
            (if arg == "" then [ ] else [ "-a" arg ])
            (nix-lib.attrsets.mapAttrsToList
              (option: value: [ "-P" "${option}=${value}" ])
              options)
            pygmentArgs
            { literal = "> $out"; }
          ]
        ])
    ;

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

    /*
      [graphviz] is a tool for generating directed and undirected graphs.

      src: directory containing compile-time source.
      main: name of the main file.
      name: the name of the resulting derivation. I suggest using the filename with extension.
      outputFormat: See [graphviz output formats].
      layoutEngine: See [graphviz layout engines].
      vars: attrset (dict) of variables passed to graphviz. See [graphviz variables].
      graphvizArgs: list of strings passed to the [graphviz commandline].

      [graphviz]: https://www.graphviz.org/documentation/
      [graphviz output formats]: https://www.graphviz.org/docs/outputs/
      [grpahviz layout engines]: https://www.graphviz.org/docs/layouts/
      [graphviz variables]: https://www.graphviz.org/doc/info/command.html#-G
      [graphviz commandline]: https://www.graphviz.org/doc/info/command.html
    */
    graphvizFigure =
      { src
      , main ? "index.dot"
      , name ? "${builtins.baseNameOf src}.${outputFormat}"
      , outputFormat ? "svg"
      , layoutEngine ? "dot"
      , vars ? { }
      , graphvizArgs ? [ ]
      }:
      pkgs.stdenvNoCC.mkDerivation {
        inherit name;
        inherit src;
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

    /*
      [plantuml] is a frontend to graphviz customized for UML diagrams.

      src: directory containing compile-time source. This derivation only supports outputting a single figure.
      main: name of the main file.
      name: the name of the resulting derivation. I suggest using the filename with extension.
      outputFormat: output format for figure. See [plantuml commandline].
      plantumlArgs: list of strings passed to plantuml. See [plantuml commandline].

      [plantuml]: https://plantuml.com/
      [plantuml commandline]: https://plantuml.com/command-line
    */
    plantumlFigure =
      { src
      , main ? "index.puml"
      , name ? "${builtins.baseNameOf src}.${outputFormat}"
      , outputFormat ? "svg"
      , plantumlArgs ? [ ]
      }:
      pkgs.stdenvNoCC.mkDerivation {
        inherit name;
        inherit src;
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
          mv $tmp/* $out
        '';
        phases = [ "unpackPhase" "buildPhase" ];
      };
  };

  packages = nix-utils-lib.packageSet [

    /*
      reveal.js is a presentation framework for JavaScript.
    */
    (nix-utils-lib.selectInDerivation {
      deriv = pkgs.fetchFromGitHub {
        owner = "hakimel";
        repo = "reveal.js";
        rev = "039972c730690af7a83a5cb832056a7cc8b565d7";
        hash = "sha256-X43lsjoLBWmttIKj9Jzut0UP0dZlsue3fYbJ3++ojbU=";
      };
      path = "dist";
      name = "reveal-js";
    })

    (nix-utils-lib.selectInDerivation {
      deriv = pkgs.fetchFromGitHub {
        owner = "hakimel";
        repo = "reveal.js";
        rev = "039972c730690af7a83a5cb832056a7cc8b565d7";
        hash = "sha256-X43lsjoLBWmttIKj9Jzut0UP0dZlsue3fYbJ3++ojbU=";
      };
      path = "plugin";
      name = "reveal-js-default-plugins";
    })

    (pkgs.fetchFromGitHub {
      name = "reveal-js-rajgoel-plugins";
      owner = "rajgoel";
      repo = "reveal.js-plugins";
      rev = "a90372093213587e27ac9b17f5d981414934143e";
      hash = "sha256-4wM0VotPmrgrxarocJxYXa/v+wo/8rREwBj/QNZTj08=";
    })

    /*
      Citaion Style Language [CSL] specifies how the bibliography entries should look.

      [This repo] contains common CSL styles.

      [CSL]: https://citationstyles.org/
      [This repo]: https://github.com/citation-style-language/styles
    */
    (pkgs.fetchFromGitHub {
      name = "citation-style-language-styles";
      owner = "citation-style-language";
      repo = "styles";
      rev = "3602c18c16d51ff5e4996c2c7da24ea2cc5e546c";
      hash = "sha256-X+iRAt2Yzp1ePtmHT5UJ4MjwFVMu2gixmw9+zoqPq20=";
    })
  ];
}
