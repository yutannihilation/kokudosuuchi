## Test environments
* local R installation, R 4.0.4
* ubuntu 20.04 (on GitHub Actions CI), R 4.0.4
* win-builder (devel)

## R CMD check results

0 errors | 0 warnings | 1 note

* This is mostly a complete rewrite of the package due to the termination of
  the API ('Kokudo Suucchi API') this package relied on. Though this definitely
  is a breaking change, there's only one package that depends ("Enhances") this
  package and it doesn't use kokudosuuchi package in actual. So, I believe this
  release will cause no major problems.
