% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/package-auth.R
\name{default_config_profile}
\alias{default_config_profile}
\title{Returns the default config profile}
\usage{
default_config_profile()
}
\value{
profile name
}
\description{
Returns the default config profile
}
\details{
Returns the config profile first looking at \code{DATABRICKS_CONFIG_PROFILE}
and then the \code{db_profile} option.
}
\keyword{internal}
