# nix-documents

[Nix](https://builtwithnix.org/) is a package manager. There are three reasons this is useful for compiling documents:

1. It is easy to define new packages, even at a fine granularity such as one a package consisting of file. As such, it can be used as a _build system_.
2. It can pull packages from the extensive [nixpkgs](https://search.nixos.org/packages) repository.
3. It can installs packages in a sandbox, so they don't pollute your system (like Python's virtualenv or `node_modules`). If two packages call for the same version of a dependency, Nix is able to only install the dependency once (unlike virtualenv).

LaTeX has no standardized way of specifying the dependent packages, so building LaTeX documents on a fresh machine is a pain. The usual solution is to install a version of LaTeX bundled with gigabytes packages and fonts (e.g. `texlive-full`). Nix is able to:

- just download the things you need, not gigabytes of `texlive-full`
- compile documents in a reproducible way
- work with minimal setup (just installing Nix and Nix flakes), even if you require custom packages
- install dependencies to a sandbox without affecting your native LaTeX installation
- use the same package spec on any Unix system (including Mac OSX)

## My take on pandoc-scholar

I prefer to author scientific documents in Markdown rather than LaTeX, because the syntax is better. See [tests/markdown/index.md](tests/markdown/index.md) for details
