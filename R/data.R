# Suppres notes with R CMD check; see http://stackoverflow.com/a/12429344/5397672
globalVariables("KSJMetadata_code")
globalVariables("KSJMetadata_code_year_cols")
globalVariables("KSJMetadata_description_url")
globalVariables("KSJMetadata_code_correspondence_tables")
globalVariables("KSJPrefCodes")

#' Corresponding Table Of Shapefile Properties
#'
#' @name KSJMetadata_code
#' @format A data.frame with code and names
#'
#' @source \url{http://nlftp.mlit.go.jp/ksj/index.html}, \url{http://nlftp.mlit.go.jp/ksj/gml/shape_property_table.xls}
"KSJMetadata_code"

#' @rdname KSJMetadata_code
#' @format A list of named character vectors to translate various codes.
#'
#' @source \url{http://nlftp.mlit.go.jp/ksj/index.html}
"KSJMetadata_code_correspondence_tables"

#' @rdname KSJMetadata_code
#' @format A data.frame with regex to extract years.
#'
#' @source \url{http://nlftp.mlit.go.jp/ksj/index.html}
"KSJMetadata_code_year_cols"

#' Corresponding Table Of Identifier Descriptions
#'
#' @name KSJMetadata_description_url
#' @format A data.frame with identifier and URLs of the description pages
#'
#' @source \url{http://nlftp.mlit.go.jp/ksj/index.html}
"KSJMetadata_description_url"

#' Corresponding Table Of Names And Codes Of Prefectures
#'
#' @name KSJPrefCodes
#' @format A data.frame with prefecture names and codes.
#'
#' @source \url{http://nlftp.mlit.go.jp/ksj/gml/codelist/PrefCd.html}
"KSJPrefCodes"

identifier_regex <- "A03|A09|A10|A11|A12|A13|A15|A16|A17|A18|A18s-a|A19|A19s|A20|A20s|A21|A21s|A22|A22-m|A22s|A23|A24|A25|A26|A27|A28|A29|A30a5|A30b|A31|A32|A33|A34|A35a|A35b|A35c|A37|A38|A39|A40|C02|C09|C23|C28|G02|G04-a|G04-c|G04-d|G08|L01|L02|L03-a|L03-b|L03-b-u|L05|N02|N03|N04|N05|N06|N07|N08|N09|N10|N11|P02|P03|P04|P05|P07|P09|P11|P12|P13|P14|P15|P16|P17|P18|P19|P20|P21|P22|P23|P24|P26|P27|P28|P29|P30|P31|P32|P33|P34|S05-a|S05-b|S05-c|S05-d|S10a|S10b|S12|W01|W05|W07|W09"
