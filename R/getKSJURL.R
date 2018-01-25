#' getKSJURL API
#'
#' Get the URLs of the data via Kokudo Suuchi API.
#'
#' @param identifier Data identifier. (e.g. \code{"N02"})
#' @param prefCode Prefecture code. You can easily get the codes by using \code{\link{choose_prefecture_code}}.
#'        This is valid only when \code{areaType} is \code{3}.
#' @param meshCode Mesh code. This is valid only when \code{areaType} is \code{4}.
#' @param metroArea Metro-area code. This is valid only when \code{areaType} is \code{2}.
#' @param fiscalyear Fiscal year. (e.g. \code{"2014"}, \code{"2014,2015"}, \code{"2005-2015"}, \code{"2000,2005-2015"})
#' @param appId Application ID. Currently, no per-user appId is provided. \code{"ksjapibeta1"} is the only choice.
#' @param lang Language. Currently \code{J} (Japanese) is the only choice.
#' @param dataformat Data format. Currently \code{1} (JPGIS2.1) is the only choice.
#'
#' @examples
#' \dontrun{
#' getKSJURL("W05", prefCode = c(27, 28))
#' getKSJURL("W05", prefCode = choose_prefecture_code())
#' }
#'
#' @seealso \url{http://nlftp.mlit.go.jp/ksj/api/about_api.html}
#' @export
getKSJURL <- function(identifier, prefCode = NULL, meshCode = NULL, metroArea = NULL, fiscalyear = NULL,
                      appId = "ksjapibeta1", lang = "J", dataformat = 1) {

  query <- list(
    appId = appId,
    lang  = lang,
    dataformat = dataformat,
    identifier = identifier,
    prefCode = as_param(prefCode),
    meshCode = as_param(meshCode),
    metroArea = as_param(metroArea),
    fiscalyear = as_param(fiscalyear)
  )
  res <- httr::GET("http://nlftp.mlit.go.jp/ksj/api/1.0b/index.php/app/getKSJURL.xml",
                   query = purrr::compact(query))

  res_text <- httr::content(res, as = "text", encoding = "UTF-8")
  # xml2 >= 1.2.0 includes the root node
  res_list <- xml2::as_list(xml2::read_xml(res_text))$KSJ_URL_INF

  # Error
  if(res_list$RESULT$STATUS[[1]] %in% c("100", "200")){
    stop(res_list$RESULT$ERROR_MSG[[1]])
  }

  # No result
  if(res_list$RESULT$STATUS[[1]] == "1"){
    warning(res_list$RESULT$ERROR_MSG[[1]])
    return(dplyr::data_frame())
  }

  res_list$KSJ_URL %>%
    purrr::map(purrr::flatten) %>%
    unname() %>%
    dplyr::bind_rows()
}
