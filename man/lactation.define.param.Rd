% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lactation.calf.model.r
\name{lactation.define.param}
\alias{lactation.define.param}
\title{Define values of the parameters for the Lactation model}
\usage{
lactation.define.param(type = "calf")
}
\arguments{
\item{type}{: for which model version ? "calf" or "machine"}
}
\value{
matrix with parameter values (nominal, binf, bsup)
}
\description{
values from Heather et al. (1983) for different scenarios
}
\examples{
lactation.define.param()
}
