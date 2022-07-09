# nix-documents

[Nix] is a package manager. There are three reasons this is useful for compiling documents:


1. It is easy to define new packages, even at a fine granularity such as one a package consisting of file. As such, it can be used as a _build system_.
2. It can pull packages from the extensive [nixpkgs] repository.
3. It can installs packages in a sandbox, so they don't pollute your system (like Python's virtualenv or `node_modules`). If two packages call for the same version of a dependency, Nix is able to only install the dependency once (unlike virtualenv).
4. It can build the artifacts that the document depends on. For example, a document might depend on the output of a plotting script or graphviz visualization.

Consider compiling a LaTeX source code from a colleague. LaTeX has no standardized way of specifying the dependent packages, so you have to be prepared for compile errors. One solution is to install a version of LaTeX bundled with gigabytes packages and fonts (e.g. `texlive-full`). Nix is able to:

1. just download the things you need, not gigabytes of `texlive-full`
2. compile documents in a reproducible way
3. work with minimal setup (just installing Nix), even if you require custom packages (e.g. Python-generated graphs)
4. install dependencies to a sandbox without affecting (or requiring) your native LaTeX installation
5. use the same package spec on any Unix system (including Mac OSX)

Also see [this blog post].

[Nix]: https://builtwithnix.org/
[nixpkgs]: https://search.nixos.org/packages
[this blog post]: https://flyx.org/nix-flakes-latex/

## Using this Flake

Install Nix with Nix flakes

```shell
$ # See https://nixos.org/download.html
$ sh <(curl -L https://nixos.org/nix/install) --daemon

$ # See https://nixos.wiki/wiki/Flakes
$ nix-env -iA nixpkgs.nixFlakes
$ echo experimental-features = nix-command flakes >> ~/.config/nix/nix.conf
```

## Compiling your own documents

Run `nix flake init --template github.com:charmoniumQ/nix-documents` in your project directory to start a project template.

Each function is documented in source in [`lib.nix`](lib.nix).

See examples in [`examples-src/flake.nix`](examples-src/flake.nix).

## Generating subfigures

There are some plugins that let one embed one document in another. For example [pandoc-graphviz] lets one render Graphviz code embedded in a pandoc document. I prefer to do this separately, with a standalone Graphviz file and a pandoc file that just has an image include. Nix makes it easy for one document to depend on another. This is advantages for two reasons:

1. It enables incremental compilation; if the Graphviz code did not change but other parts of the pandoc code did, Graphviz does not need to be invoked.
2. It is more flexible. There may be some other compiler for which there is no pandoc plugin, or there may be some option you need to set on Graphviz that the plugin doesn't support.

This can be done by setting the `src` attribute to be a merged source of several packages, e.g.:

```
src = nix-utils-lib.mergeDerivations {
    packageSet = {
        "." = ./document-markdown;
    } // nix-utils-lib.packageSet [ self."figure.svg" ];
};
```

[pandoc-graphviz]: https://github.com/Hakuyume/pandoc-filter-graphviz
