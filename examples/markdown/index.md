---
# Fields described at:
# https://pandoc.org/MANUAL.html
title: A Test
author: Samuel Grayson
standalone: yes # call \maketitle
colorlinks: yes
number-sections: yes
header-includes: |
- |
  ```{=latex}
\usepackage{fancyhdr}
\pagestyle{fancy}
\fancyhead[L,C]{}
\fancyhead[R]{\textbf{The performance of new graduates}}
\fancyfoot[L]{From: K. Grant}
\fancyfoot[C]{To: Dean A. Smith}
\fancyfoot[R]{\thepage}
\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\footrulewidth}{2pt}
  ```

# bib settings
bibliography: main.bib
citeproc: yes
link-citations: yes # in-text citation -> biblio entry
link-bibliography: yes # URLs in biblio
---

# Abstract

The text written under a heading "Abstract" is treated specially by the template.

# Introduction

First, note the YAML block header which precedes the Markdown document. This replaces `\author`, `\date`, and others.

I can cite things in a BibTeX file from the YAML block using the `[@bibtex_key]`: [@collberg2016repeatability]

Note that the citation style format can be changed in the compile flags or Nix flake.

However, Pandoc also supports [Citation Style Language][CSL] data JSON, which is much cleaner. Note that Zotero can export CSL data.

[CSL]: https://citationstyles.org/

I can even use [CiTO vocabulary] using `[@cito_prop:bibtex_key]`: [@evidence:collberg2016repeatability]

[CiTO vocabulary]: https://sparontologies.github.io/cito/current/cito.html

I can write comments with `<!-- like this -->`: <!-- like this -->

I can reference a footnote with `blah[^footnote]`: blah[^footnote]

So long as you define it like this `[^footnote]: This is the text of the footnote.`.

[^footnote]: This is the text of the footnote.

I can write code with three backticks:

    ```python
    print("code works like this")
    ```

```python
print("code works like this")
```

Of course, I can get equations with dollar signs `\\(\int x^2 \, \mathrm{d}x\\)`: \\(\int x^2 \, \mathrm{d}x\\)

Same with `\\[\int x^2 \, \mathrm{d}x \\]`:

\\[\int x^2 \, \mathrm{d}x\\]

I can reference images like this `[@fig:label]` or `[Fig. @fig:label]`: [@fig:label] or [Fig. @fig:label]

As long as you define it like `![Caption goes here](Wikipedia-logo-v2.png){#fig:label}`:

![Caption goes here](Wikipedia-logo-v2.png){#fig:label}

![Include a generated figure](graphviz.svg)

See [pandoc-crossref], which can also reference tables and equations.

[pandoc-crossref]: https://lierdakil.github.io/pandoc-crossref/

One can use `(@) item` or `(@label) item` to create a numbered list without stating the numbers explicitly, as in traditional Markdown.

(@) First, ...
(@) Second, ...
(@this-one) Third, ...

Then one can use `(@label)` (@this-one) to refer to the number of a specific item.

- `[Small caps]{.smallcaps}`: [Small caps]{.smallcaps}
- `[Underline]{.underline}`: [Underline]{.underline}
- `[Colored]{.color="red"}`: [Colored]{.color="red"}

See the [Pandoc manual] and [pandoc-lua-filters] for more extensions.

[pandoc manual]: https://pandoc.org/MANUAL.html
[pandoc-lua-filters]: https://github.com/pandoc/lua-filters

I can get a new page with `\newpage`:

\newpage

And I like to put the `# Citations` header at the end of the document:

# Citations
