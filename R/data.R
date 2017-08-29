# Suppres notes with R CMD check; see http://stackoverflow.com/a/12429344/5397672
globalVariables("KSJShapeProperty")
globalVariables("KSJPrefCodes")
globalVariables("KSJCodeDescriptionURL")

#' Corresponding Table Of Shapefile Properties
#'
#' @name KSJShapeProperty
#' @format A data.frame with codes and names
#'
#' @source \url{http://nlftp.mlit.go.jp/ksj/gml/shape_property_table.xls}
"KSJShapeProperty"

#' Corresponding Table Of Names And Codes Of Prefectures
#'
#' @name KSJPrefCodes
#' @format A data.frame with prefecture names and codes
#'
#' @source \url{http://nlftp.mlit.go.jp/ksj/gml/codelist/PrefCd.html}
"KSJPrefCodes"

#' Corresponding Table Of Code Descriptions
#'
#' @name KSJCodeDescriptionURL
#' @format A data.frame with codes and URLs of the description pages
#'
#' @source \url{http://nlftp.mlit.go.jp/ksj/index.html}
"KSJCodeDescriptionURL"
