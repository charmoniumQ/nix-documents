{
  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    nix-utils = {
      url = "github:charmoniumQ/nix-utils";
    };
    nix-documents = {
      url = "..";
    };
  };
  outputs = { self, nixpkgs, flake-utils, nix-utils, nix-documents }:
    {
      templates = {
        default = {
          path = ./templates;
          description = "Template for making documents as a Nix Flake";
        };
      };
    } // flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nix-lib = nixpkgs.lib;
          nix-utils-lib = nix-utils.lib.${system};
          nix-documents-lib = nix-documents.lib.${system};
        in
        {
          packages = {
            default = nix-utils-lib.mergeDerivations {
              packageSet = nix-utils-lib.packageSetRec
                (self: [
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
                  })

                  (nix-documents-lib.markdownDocument {
                    src = nix-utils-lib.mergeDerivations {
                      packageSet = {
                        "." = ./markdown-bells-and-whistles;
                      } // nix-utils-lib.packageSet [ self."graphviz.svg" ];
                    };
                    main = "index.md";
                    name = "markdown-xelatex.pdf";
                    pdfEngine = "xelatex";
                    outputFormat = "pdf";
                    date = 1655528400;
                    texlivePackages = nix-documents-lib.pandocTexlivePackages // {
                      inherit (pkgs.texlive) fancyhdr;
                    };
                    nixPackages = [ ];
                  })

                  (nix-documents-lib.markdownDocument {
                    src = nix-utils-lib.mergeDerivations {
                      packageSet = {
                        "." = ./markdown-bells-and-whistles;
                      } // nix-utils-lib.packageSet [ self."graphviz.svg" ];
                    };
                    pdfEngine = "pdflatex";
                    name = "markdown-pdflatex.pdf";
                  })

                  (nix-documents-lib.markdownDocument {
                    src = nix-utils-lib.mergeDerivations {
                      packageSet = {
                        "." = ./markdown-bells-and-whistles;
                      } // nix-utils-lib.packageSet [ self."graphviz.svg" ];
                    };
                    pdfEngine = "lualatex";
                    name = "markdown-lualatex.pdf";
                    texlivePackages = nix-documents-lib.pandocTexlivePackages // {
                      inherit (pkgs.texlive) collection-luatex;
                    };
                  })

                  (nix-documents-lib.markdownDocument {
                    src = nix-utils-lib.mergeDerivations {
                      packageSet = {
                        "." = ./markdown-bells-and-whistles;
                      } // nix-utils-lib.packageSet [ self."graphviz.svg" ];
                    };
                    pdfEngine = "context";
                    name = "markdown-context.pdf";
                    texlivePackages = nix-documents-lib.pandocTexlivePackages // {
                      inherit (pkgs.texlive) scheme-context;
                    };
                  })

                  (nix-documents-lib.latexDocument {
                    src = nix-utils-lib.mergeDerivations {
                      packageSet = {
                        "." = ./latex;
                      } // nix-utils-lib.packageSet [ self."pygment-defs.tex" self."pygment-code.tex" ];
                    };
                    name = "pdflatex.pdf";
                    texEngine = "pdflatex";
                    texlivePackages = { inherit (pkgs.texlive) fancyhdr fancyvrb xcolor; };
                  })

                  (nix-documents-lib.latexDocument {
                    src = nix-utils-lib.mergeDerivations {
                      packageSet = {
                        "." = ./latex;
                      } // nix-utils-lib.packageSet [ self."pygment-defs.tex" self."pygment-code.tex" ];
                    };
                    name = "xelatex.pdf";
                    texEngine = "xelatex";
                    texlivePackages = { inherit (pkgs.texlive) fancyhdr fancyvrb xcolor; };
                  })

                  (nix-documents-lib.latexDocument {
                    src = nix-utils-lib.mergeDerivations {
                      packageSet = {
                        "." = ./latex;
                      } // nix-utils-lib.packageSet [ self."pygment-defs.tex" self."pygment-code.tex" ];
                    };
                    name = "lualatex.pdf";
                    texEngine = "lualatex";
                    texlivePackages = { inherit (pkgs.texlive) fancyhdr fancyvrb xcolor; };
                  })

                  (nix-documents-lib.revealJsPresentation {
                    src = ./reveal-js-presentation;
                  })

                  (nix-documents-lib.pygmentStyleDefs {
                    name = "pygment-defs.tex";
                    formatter = "tex";
                    style = "autumn";
                    arg = "";
                  })

                  (nix-documents-lib.pygmentCode {
                    src = ./pygmentize;
                    name = "pygment-code.tex";
                    main = "index.py";
                    lexer = "auto";
                    filters = [ ];
                    formatter = "tex";
                    options = {
                      style = "autumn";
                      linenos = "True";
                      texcomments = "True";
                      mathescape = "True";
                    };
                  })

                ] ++ (if system == "i686-linux" then [ ] else [
                  # Note that this doesn't work in i686-linux
                  # The JDK for i686-linux is marked as broken ("end of life")
                  (nix-documents-lib.plantumlFigure {
                    src = ./plantuml;
                    name = "plantuml.svg";
                  })
                ]));
            };
          };
        });
}
