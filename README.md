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

[Nix]: https://builtwithnix.org/
[nixpkgs]: https://search.nixos.org/packages

## A note on composition

There are some plugins that let one embed one document in another. For example [pandoc-graphviz] lets one render Graphviz code embedded in a pandoc document. I prefer to do this separately, with a standalone Graphviz file and a pandoc file that just has an image include. Nix makes it easy for one document to depend on another. This is advantages for two reasons:

1. It enables incremental compilation; if the Graphviz code did not change but other parts of the pandoc code did, Graphviz does not need to be invoked.
2. It is more flexible. There may be some other compiler for which there is no pandoc plugin, or there may be some option you need to set on Graphviz that the plugin doesn't support.

[pandoc-graphviz]: https://github.com/Hakuyume/pandoc-filter-graphviz

## markdown-document

This will compile your Markdown document:

```nix
nix-documents.lib.${system}.markdown-document {
  src = ./.;

  # this is the default and can be omitted.
  main = "index.md";

  # This is the default and can be omitted.
  # See Pandoc's options here:
  # https://pandoc.org/MANUAL.html#option--to
  output = "pdf";

  # Choose from this repo, without the .csl:
  # [1]: https://github.com/citation-style-language/styles
  csl-style = "acm-sig-proceedings";
};
```

I based this off of the excellent [pandoc-scholar], which adds extensions to Markdown that make it amenable to academic writing (e.g. citation counting). Writing Markdown has several advantages to writing raw LaTeX:

- The syntax is prettier.
- You don't have to run the compiler multiple times to get the right output.
- Extensions can be written in Haskell or Lua, which are both "nicer" than the TeX language.
- The output is equally pretty, since Pandoc uses ConTeXt, XeTeX, or LaTeX under the hood.
- You can still drop down to raw LaTeX from Markdown, if you must.
- Alternatively, if you have a TikZ

See [tests/markdown/index.md](tests/markdown/index.md) for an example.

[pandoc-scholar]: https://github.com/pandoc-scholar/pandoc-scholar

## latex-document

## revealjs-presentation

## graphviz-figure

## plantuml-figure

## latex-figure

## asymptote-figure
