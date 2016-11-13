#' Get JPGIS2.1 Data
#'
#' Download and load spatial data from ZIP file downloaded from Kokudo Suuchi service. Note that this function does
#' not use API; directly download ZIP file and load the data by \link[rgdal]{readOGR}.
#'
#' @param zip_url
#'   The URL of the Zip file.
#' @param translate_columns
#'   If \code{TRUE}, try to use human-readable column names.
#'   See \link{KSJShapeProperty} for more information about the corresponding table.
#'
#' @seealso \url{http://nlftp.mlit.go.jp/ksj/api/about_api.html}
#' @examples
#' \dontrun{
#' l <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/W07/W07-09/W07-09_3641-jgd_GML.zip")
#' names(l)
#' str(l, max.level = 1)
#' }
#'
#' @export
getKSJData <- function(zip_url, translate_columns = TRUE) {
  tmp_dir_parent <- tempdir()
  url_hash <- digest::digest(zip_url)
  data_dir <- file.path(tmp_dir_parent, url_hash)

  use_cached <- FALSE
  if(!dir.exists(data_dir)) {
    dir.create(data_dir)
    tmp_file <- tempfile(fileext = "zip")
    utils::download.file(zip_url, destfile = tmp_file)
    utils::unzip(tmp_file, exdir = data_dir)
    unlink(tmp_file)
  } else {
    use_cached <- TRUE
    cat("Using cached data.\n\n")
  }

  # rebase data_dir
  meta_file <- list.files(data_dir, pattern = "KS-META.*\\.xml", recursive = TRUE, full.names = TRUE)
  if (length(meta_file) == 0) stop("The data contains no META file!")
  if (length(meta_file) > 1) stop("The data contains multiple META file!")
  data_dir <- dirname(meta_file)

  # CP932 filenames cannot be handled on non-CP932 systems. Rename them.
  if (!identical(.Platform$OS.type, "CP932") && !use_cached) {
    file_names_cp932 <- list.files(data_dir)
    file_names_utf8 <- iconv(file_names_cp932, from = "CP932", to = "UTF-8")
    file.rename(file.path(data_dir, file_names_cp932),
                file.path(data_dir, file_names_utf8))
  }

  layers <- rgdal::ogrListLayers(data_dir)
  # Workaround for Windows
  Encoding(layers) <- "UTF-8"

  # THIS IS NOT A MISTAKE. I don't understand why though...
  encoding <- if(identical(.Platform$OS.type, "windows")) "UTF-8" else "CP932"
  layers <- sort(layers)
  result <- purrr::map(layers,
                       ~ read_ogr_layer(data_dir, ., encoding = encoding,
                                        translate_columns = translate_columns))
  names(result) <- layers
  result
}

read_ogr_layer <- function(data_dir, layer, encoding, translate_columns = FALSE) {
  l <- rgdal::readOGR(data_dir, layer, encoding = encoding)

  col_codes <- colnames(l@data)
  corresp_table <- KSJShapeProperty[KSJShapeProperty$code %in% col_codes,]
  urls <- sprintf("http://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-%s.html", unique(corresp_table$category))
  message(sprintf("\nDetails about this data may be found at %s\n", paste(urls, collapse = ", ")))

  if (translate_columns) {
    warn_no_corresp_names(col_codes, corresp_table)
    corresp_names <- purrr::set_names(corresp_table$code, corresp_table$name)

    l@data <- dplyr::rename_(l@data, .dots = corresp_names)
  }

  l
}

# For tests on Travis with with_mock(). Warnings are treated as errors there.
warn_no_corresp_names <- function(col_codes, corresp_table) {
  codes_wo_corresp_names <- col_codes[!(col_codes %in% corresp_table$code)]
  if(length(codes_wo_corresp_names) != 0)
    warnings(sprintf("No corresponding names are available for these columns: %s",
                     paste(codes_wo_corresp_names, collapse = ", ")))

}
