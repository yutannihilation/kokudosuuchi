## Test environments
* local Windows install, R 3.3.2
* win-builder, R-devel
* ubuntu 14.04 (on travis-ci), R 3.3.2

## R CMD check results
There were no ERRORs or WARNINGs.

## Resubmission
This is second resubmission. In this version I have:

* Put the URL in the Description in angle brackets

* Manually confirmed that the URLs marked as "(possibly) invalid URLs" in NOTE
are valid and accessible via Web browsers. These errors seem to occur only when
accessed by libcurl.
