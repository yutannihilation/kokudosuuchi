% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/translateKSJData.R
\name{translateKSJData}
\alias{translateKSJData}
\title{Translate JPGIS2.1 Data}
\usage{
translateKSJData(
  x,
  id = NULL,
  variant = NULL,
  quiet = TRUE,
  translate_colnames = TRUE,
  translate_codelist = TRUE
)
}
\arguments{
\item{x}{A list of \link[sf:sf]{sf} objects.}

\item{id}{An ID of the dataset (e.g. \code{A03}). This can be \code{NULL} if \code{x} is loaded
by \code{\link[=readKSJData]{readKSJData()}}.}

\item{variant}{A type of variant in case the translation cannot be determined only by \code{id}.}

\item{quiet}{If \code{TRUE}, suppress messages.}

\item{translate_colnames}{If \code{TRUE}, translate colnames to human-readable labels.}

\item{translate_codelist}{If \code{TRUE}, translate codes to human-readable labels.}
}
\description{
\code{translateKSJData()} translates colnames and 'codelist'-type of columns to
human-readable labels.
}
