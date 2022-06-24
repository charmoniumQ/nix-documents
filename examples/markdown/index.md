---
# https://pandoc.org/MANUAL.html#general-options-1
from: markdown+emoji
# For all inputs, see: https://pandoc.org/MANUAL.html#general-options
# For Markdown variants, see: https://pandoc.org/MANUAL.html#markdown-variants
# For extensions, see: https://pandoc.org/MANUAL.html#extensions
verbosity: INFO
fail-if-warnings: yes

# https://pandoc.org/MANUAL.html#general-writer-options-1
standalone: yes
# template: /path/to/template.tex here
dpi: 300
table-of-contents: no
strip-comments: yes

# https://pandoc.org/MANUAL.html#citation-rendering-1
citeproc: yes
cite-method: citeproc # or natbib or biblatex
# cite-method can be citeproc, natbib, or biblatex. This only affects LaTeX output. If you want to use citeproc to format citations, you should also set ‘citeproc: true’.
bibliography: main.bib
#citation-abbreviations: ab.json
link-citations: yes # in-text citation -> biblio entry
link-bibliography: yes # URLs in biblio
notes-after-punctuation: yes

# https://pandoc.org/MANUAL.html#metadata-variables
title: The document title
author:
- Jane Doe
- John Q. Doe
date: 2022-06-18
subtitle: The document subtitle
lang: en-US
dir: ltr
standalone: yes # setting to yes calls \maketitle
number-sections: yes

# https://pandoc.org/MANUAL.html#variables-for-latex
documentclass: article #scrartcl
hyperrefoptions:
- linktoc=all
- pdfwindowui
- pdfpagemode=FullScreen
indent: yes
pagestyle: plain
papersize: letter
lof: no # list of figures
lot: no # list of tables
thanks: no
toc: no
# toc-depth: 
filecolor: blue
citecolor: blue
urlcolor: blue
toccolor: blue

# HTML and LaTeX options
fontsize: 12
# mainfont: 
# sansfont:
# monofont:
# mathfont:
colorlinks: yes
linkcolor: blue
linestretch: 1.25
margin-left: 1.5in
margin-right: 1.5in
margin-top: 1.5in
margin-bottom: 1.5in

header-includes:
- |
  ```{=latex}
  \usepackage{fancyhdr}
  \pagestyle{fancy}
  \fancyhead[C]{Fancyheader}
  \fancyhead[L,R]{}
  \fancyfoot[L,R]{}
  \fancyfoot[C]{\thepage}
  ```
# include-before: # before body
# include-after: # after body

# https://pandoc.org/MANUAL.html#math-rendering-in-html-1
html-math-method:
  method: katex
# document-css: test.css

---

# Abstract

The text written under a heading "Abstract" is treated specially by the template.

# Introduction

First, note the YAML block header which precedes the Markdown document. This replaces `\author`, `\date`, and others.

- I can cite things in a BibTeX file from the YAML block using the `[@bibtex_key]`: [@collberg]

  - Note that the citation style format can be changed in the compile flags or Nix flake.

  - However, Pandoc also supports [Citation Style Language][CSL] data JSON, which is much cleaner. Note that Zotero can export CSL data.

  - I can even use [CiTO vocabulary] using `[@cito_prop:bibtex_key]`: [@evidence:collberg]

- I can write comments with `<!-- like this -->`: <!-- like this -->

- I can reference a footnote with `blah[^footnote]`: blah[^footnote]

- I can write code with three backticks:

    ```python
    print("code works like this")
    ```
<!--
- Inline equations mode (with tex_math_double_backslash extension)  `\\(\int x^2 \, \mathrm{d}x\\)`: `\\(\int x^2 \, \mathrm{d}x\\)`

- Display equations mode  `\\[\int x^2 \, \mathrm{d}x \\]`: `\\[\int x^2 \, \mathrm{d}x\\]`
-->

- Figures generated from Nix inputs can be included by their derivation's name `![Include a generated figure](graphviz.svg){#fig:label}`:

![Include a generated figure](graphviz.svg){#fig:label width=25%}

  - I can reference images like this `[@fig:label]` or `[Fig. @fig:label]`: [@fig:label] or [Fig. @fig:label]

  - See [pandoc-crossref], which can also reference tables and equations.

- One can use `(@) item` or `(@label) item` to create a numbered list without stating the numbers explicitly, as in traditional Markdown.

  (@) First, ...
  (@label) Second, ...

  - Then one can use `@label` to refer to the number of a specific item: @label

- `[Small caps]{.smallcaps}`: [Small caps]{.smallcaps}

- `[Underline]{.underline}`: [Underline]{.underline}

- \textcolor{red}{red text}

- Raw `\LaTeX`: \LaTeX

- Raw `<button>HTML</button>`: <button>HTML</button>

- Emoji like (with emoji extension) `:smile:`: :smile:

- See the [Pandoc manual] and [pandoc-lua-filters] for more extensions.

Term 1

:   Definition 1

Term 2 with *inline markup*

:   Definition 2

        { some code, part of Definition 2 }

    Third paragraph of definition 2.

I can get a new page with `\newpage`:

\newpage

[^footnote]: This is the text of the footnote.

[pandoc-crossref]: https://lierdakil.github.io/pandoc-crossref/
[CSL]: https://citationstyles.org/
[CiTO vocabulary]: https://sparontologies.github.io/cito/current/cito.html
[pandoc manual]: https://pandoc.org/MANUAL.html
[pandoc-lua-filters]: https://github.com/pandoc/lua-filters

# References

::: {#refs}
:::

Post reference stuff
