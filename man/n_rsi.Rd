% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/n_rsi.R
\name{n_rsi}
\alias{n_rsi}
\title{Count cases with antimicrobial results}
\usage{
n_rsi(...)
}
\arguments{
\item{...}{one or more vectors (or columns) with antibiotic interpretations. They will be transformed internally with \code{\link{as.rsi}} if needed. Use multiple columns to calculate (the lack of) co-resistance: the probability where one of two drugs have a resistant or susceptible result. See Examples.}
}
\description{
This counts all cases where antimicrobial interpretations are available. The way it can be used is equal to \code{\link{n_distinct}}. Its function is equal to \code{count_S(...) + count_IR(...)}.
}
\examples{
library(dplyr)

septic_patients \%>\%
  group_by(hospital_id) \%>\%
  summarise(cipro_p = portion_S(cipr, as_percent = TRUE),
            cipro_n = n_rsi(cipr),
            genta_p = portion_S(gent, as_percent = TRUE),
            genta_n = n_rsi(gent),
            combination_p = portion_S(cipr, gent, as_percent = TRUE),
            combination_n = n_rsi(cipr, gent))
}
\seealso{
\code{\link[AMR]{count}_*} to count resistant and susceptibile isolates per interpretation type.\cr
\code{\link{portion}_*} to calculate microbial resistance and susceptibility.
}
