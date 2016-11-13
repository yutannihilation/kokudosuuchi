## Test environments
* local Windows install, R 3.3.2
* win-builder, R-devel
* ubuntu 14.04 (on travis-ci), R 3.3.2

## R CMD check results

0 errors | 0 warnings | 0 notes

For the URLs marked as "(possibly) invalid URLs" in NOTE, I manually confirmed they
are valid and accessible via Web browsers. These errors seem to occur only when
accessed by libcurl.

## Resubmission

After the first release, several issues about character encodings have been reported.
This release fixes these issue and add an exmerimental function.
