# kokudosuuchi 0.3.0

* Added a `NEWS.md` file to track changes to the package.

## New Feature

* `getKSJData()` now translates column codes to human-redable names.

## Bug fixes

* Fix misinformation in DESCRIPTION.
* Fix typo in `getKSJURL()`.
* Fix issue with `getKSJData()` when the data contains UTF-8 layer names.
* Fix issue with `getKSJData()` when the data has subdirectory.
* Fix issue with `getKSJData()` on macOS, as `download.file()` won't work well with Kokudo Suuchi API.

# kokudosuuchi 0.2.0

* First CRAN release
