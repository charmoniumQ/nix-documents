# nix-documents

[Nix] is a package manager. There are three reasons this is useful for compiling documents:


1. It is easy to define new packages, even at a fine granularity such as one a package consisting of file. As such, it can be used as a _build system_.
2. It can pull packages from the extensive [nixpkgs] repository.
3. It can installs packages in a sandbox, so they don't pollute your system (like Python's virtualenv or `node_modules`). If two packages call for the same version of a dependency, Nix is able to only install the dependency once (unlike virtualenv).

Consider compiling a LaTeX source code from a colleague. LaTeX has no standardized way of specifying the dependent packages, so you have to be prepared for compile errors. One solution is to install a version of LaTeX bundled with gigabytes packages and fonts (e.g. `texlive-full`). Nix is able to:

1. just download the things you need, not gigabytes of `texlive-full`
2. compile documents in a reproducible way
3. work with minimal setup (just installing Nix and Nix flakes), even if you require custom packages (e.g. Python-generated graphs)
4. install dependencies to a sandbox without affecting (or requiring) your native LaTeX installation
5. use the same package spec on any Unix system (including Mac OSX)

Also see [this blog post].

[Nix]: https://builtwithnix.org/
[nixpkgs]: https://search.nixos.org/packages
[this blog post]: https://flyx.org/nix-flakes-latex/

## Installing Nix

Install Nix with Nix flakes

```shell
$ # See https://nixos.org/download.html
$ sh <(curl -L https://nixos.org/nix/install) --daemon

$ # See https://nixos.wiki/wiki/Flakes
$ nix-env -iA nixpkgs.nixFlakes
$ echo experimental-features = nix-command flakes >> ~/.config/nix/nix.conf
```

Once this is done, initialize a new project with:

```shell
$ # To start a new flake,
$ nix flake init --template github.com:charmoniumQ/nix-documents
```

## Generating subfigures

There are some plugins that let one embed one document in another. For example [pandoc-graphviz] lets one render Graphviz code embedded in a pandoc document. I prefer to do this separately, with a standalone Graphviz file and a pandoc file that just has an image include. Nix makes it easy for one document to depend on another. This is advantages for two reasons:

1. It enables incremental compilation; if the Graphviz code did not change but other parts of the pandoc code did, Graphviz does not need to be invoked.
2. It is more flexible. There may be some other compiler for which there is no pandoc plugin, or there may be some option you need to set on Graphviz that the plugin doesn't support.

These packages support an `inputs` parameter, which should be a list of derivations (e.g. other documents or figures from this flake). Those will be compiled and placed in the source-tree under their derivation name. Make sure the name includes the `.svg` or whatever suffix.

[pandoc-graphviz]: https://github.com/Hakuyume/pandoc-filter-graphviz

<!-- TODO: Show flake.nix composition -->

## markdown-document

I based this off of the excellent [pandoc-scholar], which adds extensions to Markdown that make it amenable to academic writing (e.g. citation counting). Writing Markdown has several advantages to writing raw LaTeX:

1. The syntax is prettier.
2. You don't have to run the compiler multiple times to get the right output.
3. Extensions can be written in Haskell or Lua, which are both "nicer" than the TeX language.
4. The output is equally pretty, since Pandoc uses ConTeXt, XeTeX, LuaTeX, or pdfLaTeX under the hood.
5. You can still drop down to raw LaTeX from Markdown, if you must: either using LaTeX to generate a figure or embedding LaTeX commands in Markdown.
6. You can output to more formats, including docx, EPUB, ODT, HTML, and others.

See [examples-src/markdown-bells-and-whistles/index.md] for an example which compiles to [examples/markdown-xelatex.pdf] or [examples/markdown-context.pdf].

[examples-src/markdown-bells-and-whistles/index.md]: examples-src/markdown-bells-and-whistles/index.md
[examples/markdown-xelatex.pdf]: examples/markdown-xelatex.pdf
[pandoc-scholar]: https://github.com/pandoc-scholar/pandoc-scholar

## latex-document

The relationship between the pdfLaTeX, LuaLaTex, XeLaTeX [[1], [2]]. If you are unsure, just use XeLaTeX.

[1]: https://tex.stackexchange.com/questions/36/differences-between-luatex-context-and-xetex
[2]: https://www.overleaf.com/learn/latex/Articles/The_TeX_family_tree%3A_LaTeX%2C_pdfTeX%2C_XeTeX%2C_LuaTeX_and_ConTeXt

To use a TeXlive package, find its name in [CTAN] and in check that it exists in [Nix TeXlive]. Then add it to `texlivePackages`

[Nix TeXlive]: https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/tools/typesetting/tex/texlive/pkgs.nix
[CTAN]: https://ctan.org/

## graphviz-figure

See [examples-src/graphviz/index.dot] for an example which compiles to [examples/graphviz.svg].

[examples-src/graphviz/index.dot]: examples-src/graphviz/index.dot
[examples/graphviz.svg]: examples/graphviz.svg

## plantuml-figure

See [examples-src/plantuml/index.puml] for an example which compiles to [examples/plantuml.svg].

[examples-src/plantuml/index.puml]: examples-src/plantuml/index.puml
[examples/plantuml.svg]: examples/plantuml.svg

## revealjs-presentation

## pygments-listing
