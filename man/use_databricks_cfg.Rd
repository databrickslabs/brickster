% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/package-auth.R
\name{use_databricks_cfg}
\alias{use_databricks_cfg}
\title{Returns whether or not to use a \code{.databrickscfg} file}
\usage{
use_databricks_cfg()
}
\value{
boolean
}
\description{
Returns whether or not to use a \code{.databrickscfg} file
}
\details{
Indicates \code{.databrickscfg} should be used instead of environment variables when
either the \code{use_databrickscfg} option is set or Posit Workbench managed OAuth credentials are detected.
}
\keyword{internal}
