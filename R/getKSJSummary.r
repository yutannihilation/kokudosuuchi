#' getKSJSummary API
#'
#' @seealso \url{http://nlftp.mlit.go.jp/ksj/api/about_api.html}
#' @export
getKSJSummary <- function(appId = "ksjapibeta1", lang = "J", dataformat = 1) {
  query <- list(
    appId = appId,
    lang  = lang,
    dataformat = dataformat
  )

  res <- httr::GET("http://nlftp.mlit.go.jp/ksj/api/1.0b/index.php/app/getKSJSummary.xml",
            query = purrr::compact(query))

  res_text <- httr::content(res, as = "text", encoding = "UTF-8")
  res_list <- xml2::as_list(xml2::read_xml(res_text))

  # Error
  if(res_list$RESULT$STATUS[[1]] %in% c("100", "200")){
    stop(res_list$RESULT$ERROR_MSG[[1]])
  }

  # No result
  if(res_list$RESULT$STATUS[[1]] == "1"){
    warning(res_list$RESULT$ERROR_MSG[[1]])
    return(dplyr::data_frame())
  }

  res_list$KSJ_SUMMARY %>%
    purrr::map(purrr::zip_n) %>%
    purrr::flatten(.) %>%
    dplyr::bind_rows(.)
}
