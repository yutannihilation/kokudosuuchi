# kokudosuuchi 1.0.0

## Breaking change

* kokudosuuchi drops all functionality related to the 'Kokudo Suuchi' API as the
  API is no longer provided. Instead, a new function `readKSJdata()` is
  implemented to make it ease to read various geospatial data provided by
  'Kokudo Suuchi'.

# kokudosuuchi 0.4.2

* Fix errors due to the breaking change introduced in xml2 v1.2.0 (#6)

# kokudosuuchi 0.4.1

* Fix test errors on CRAN

# kokudosuuchi 0.4.0

* Added a `NEWS.md` file to track changes to the package.

## New Feature

* `getKSJData()` now uses sf.
* `getKSJData()` now translates the codes in the column names of data into human-readable ones.
* `getKSJData()` now accepts paths in addition to URLs to zip files.
* `getKSJData()` now tries to set the correct encoding for character attributes.

## Bug fixes

* Fix misinformation in DESCRIPTION.
* Fix typo in `getKSJURL()`.
* Fix issue with `getKSJData()` when the data contains UTF-8 layer names.
* Fix issue with `getKSJData()` when the data has subdirectory.
* Fix issue with `getKSJData()` on macOS, as `download.file()` won't work well with Kokudo Suuchi API.

# kokudosuuchi 0.3.0 (not released)

# kokudosuuchi 0.2.0

* First CRAN release
