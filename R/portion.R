# ==================================================================== #
# TITLE                                                                #
# Antimicrobial Resistance (AMR) Analysis                              #
#                                                                      #
# AUTHORS                                                              #
# Berends MS (m.s.berends@umcg.nl), Luz CF (c.f.luz@umcg.nl)           #
#                                                                      #
# LICENCE                                                              #
# This program is free software; you can redistribute it and/or modify #
# it under the terms of the GNU General Public License version 2.0,    #
# as published by the Free Software Foundation.                        #
#                                                                      #
# This program is distributed in the hope that it will be useful,      #
# but WITHOUT ANY WARRANTY; without even the implied warranty of       #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
# GNU General Public License for more details.                         #
# ==================================================================== #

#' Calculate resistance of isolates
#'
#' @description These functions can be used to calculate the (co-)resistance of microbial isolates (i.e. percentage S, SI, I, IR or R). All functions can be used in \code{dplyr}s \code{\link[dplyr]{summarise}} and support grouped variables, see \emph{Examples}.
#'
#' \code{portion_R} and \code{portion_IR} can be used to calculate resistance, \code{portion_S} and \code{portion_SI} can be used to calculate susceptibility.\cr
#' @param ab1 vector of antibiotic interpretations, they will be transformed internally with \code{\link{as.rsi}} if needed
#' @param ab2 like \code{ab}, a vector of antibiotic interpretations. Use this to calculate (the lack of) co-resistance: the probability where one of two drugs have a resistant or susceptible result. See Examples.
#' @param minimum minimal amount of available isolates. Any number lower than \code{minimum} will return \code{NA}. The default number of \code{30} isolates is advised by the CLSI as best practice, see Source.
#' @param as_percent logical to indicate whether the output must be returned as percent (text), will else be a double
#' @details \strong{Remember that you should filter your table to let it contain only first isolates!} Use \code{\link{first_isolate}} to determine them in your data set.
#'
#' The old \code{\link{rsi}} function is still available for backwards compatibility but is deprecated.
#' \if{html}{
#'   \cr\cr
#'   To calculate the probability (\emph{p}) of susceptibility of one antibiotic, we use this formula:
#'   \out{<div style="text-align: center">}\figure{mono_therapy.png}\out{</div>}
#'   To calculate the probability (\emph{p}) of susceptibility of more antibiotics (i.e. combination therapy), we need to check whether one of them has a susceptible result (as numerator) and count all cases where all antibiotics were tested (as denominator). \cr
#'   \cr
#'   For two antibiotics:
#'   \out{<div style="text-align: center">}\figure{combi_therapy_2.png}\out{</div>}
#'   \cr
#'   Theoretically for three antibiotics:
#'   \out{<div style="text-align: center">}\figure{combi_therapy_3.png}\out{</div>}
#' }
#' @source \strong{M39 Analysis and Presentation of Cumulative Antimicrobial Susceptibility Test Data, 4th Edition}, 2014, \emph{Clinical and Laboratory Standards Institute (CLSI)}. \url{https://clsi.org/standards/products/microbiology/documents/m39/}.
#' @seealso \code{\link{n_rsi}} to count cases with antimicrobial results.
#' @keywords resistance susceptibility rsi_df rsi antibiotics isolate isolates
#' @return Double or, when \code{as_percent = TRUE}, a character.
#' @rdname portion
#' @name portion
#' @export
#' @examples
#' # Calculate resistance
#' portion_R(septic_patients$amox)
#' portion_IR(septic_patients$amox)
#'
#' # Or susceptibility
#' portion_S(septic_patients$amox)
#' portion_SI(septic_patients$amox)
#'
#' # Since n_rsi counts available isolates (and is used as denominator),
#' # you can calculate back to count e.g. non-susceptible isolates:
#' portion_IR(septic_patients$amox) * n_rsi(septic_patients$amox)
#'
#' library(dplyr)
#' septic_patients %>%
#'   group_by(hospital_id) %>%
#'   summarise(p = portion_S(cipr),
#'             n = n_rsi(cipr)) # n_rsi works like n_distinct in dplyr
#'
#' septic_patients %>%
#'   group_by(hospital_id) %>%
#'   summarise(R = portion_R(cipr, as_percent = TRUE),
#'             I = portion_I(cipr, as_percent = TRUE),
#'             S = portion_S(cipr, as_percent = TRUE),
#'             n = n_rsi(cipr), # works like n_distinct in dplyr
#'             total = n())     # NOT the amount of tested isolates!
#'
#' # Calculate co-resistance between amoxicillin/clav acid and gentamicin,
#' # so we can see that combination therapy does a lot more than mono therapy:
#' portion_S(septic_patients$amcl) # S = 67.3%
#' n_rsi(septic_patients$amcl)     # n = 1570
#'
#' portion_S(septic_patients$gent) # S = 74.0%
#' n_rsi(septic_patients$gent)     # n = 1842
#'
#' with(septic_patients,
#'      portion_S(amcl, gent))     # S = 92.1%
#' with(septic_patients,           # n = 1504
#'      n_rsi(amcl, gent))
#'
#' septic_patients %>%
#'   group_by(hospital_id) %>%
#'   summarise(cipro_p = portion_S(cipr, as_percent = TRUE),
#'             cipro_n = n_rsi(cipr),
#'             genta_p = portion_S(gent, as_percent = TRUE),
#'             genta_n = n_rsi(gent),
#'             combination_p = portion_S(cipr, gent, as_percent = TRUE),
#'             combination_n = n_rsi(cipr, gent))
#'
#' \dontrun{
#'
#' # calculate current empiric combination therapy of Helicobacter gastritis:
#' my_table %>%
#'   filter(first_isolate == TRUE,
#'          genus == "Helicobacter") %>%
#'   summarise(p = portion_S(amox, metr),  # amoxicillin with metronidazole
#'             n = n_rsi(amox, metr))
#' }
portion_R <- function(ab1,
                      ab2 = NULL,
                      minimum = 30,
                      as_percent = FALSE) {
  rsi_calc(type = "R",
           ab1 = ab1,
           ab2 = ab2,
           include_I = FALSE,
           minimum = minimum,
           as_percent = as_percent)
}

#' @rdname portion
#' @export
portion_IR <- function(ab1,
                       ab2 = NULL,
                       minimum = 30,
                       as_percent = FALSE) {
  rsi_calc(type = "R",
           ab1 = ab1,
           ab2 = ab2,
           include_I = TRUE,
           minimum = minimum,
           as_percent = as_percent)
}

#' @rdname portion
#' @export
portion_I <- function(ab1,
                      minimum = 30,
                      as_percent = FALSE) {
  rsi_calc(type = "I",
           ab1 = ab1,
           ab2 = NULL,
           include_I = FALSE,
           minimum = minimum,
           as_percent = as_percent)
}

#' @rdname portion
#' @export
portion_SI <- function(ab1,
                       ab2 = NULL,
                       minimum = 30,
                       as_percent = FALSE) {
  rsi_calc(type = "S",
           ab1 = ab1,
           ab2 = ab2,
           include_I = TRUE,
           minimum = minimum,
           as_percent = as_percent)
}

#' @rdname portion
#' @export
portion_S <- function(ab1,
                      ab2 = NULL,
                      minimum = 30,
                      as_percent = FALSE) {
  rsi_calc(type = "S",
           ab1 = ab1,
           ab2 = ab2,
           include_I = FALSE,
           minimum = minimum,
           as_percent = as_percent)
}

rsi_calc <- function(type,
                     ab1,
                     ab2,
                     include_I,
                     minimum,
                     as_percent) {

  if (NCOL(ab1) > 1) {
    stop('`ab1` must be a vector of antimicrobial interpretations', call. = FALSE)
  }
  if (!is.logical(include_I)) {
    stop('`include_I` must be logical', call. = FALSE)
  }
  if (!is.numeric(minimum)) {
    stop('`minimum` must be numeric', call. = FALSE)
  }
  if (!is.logical(as_percent)) {
    stop('`as_percent` must be logical', call. = FALSE)
  }

  print_warning <- FALSE
  if (!is.rsi(ab1)) {
    ab1 <- as.rsi(ab1)
    print_warning <- TRUE
  }
  if (!is.null(ab2)) {
    # ab_name <- paste(deparse(substitute(ab1)), "and", deparse(substitute(ab2)))
    if (NCOL(ab2) > 1) {
      stop('`ab2` must be a vector of antimicrobial interpretations', call. = FALSE)
    }
    if (!is.rsi(ab2)) {
      ab2 <- as.rsi(ab2)
      print_warning <- TRUE
    }
    x <- apply(X = data.frame(ab1 = as.integer(ab1),
                              ab2 = as.integer(ab2)),
               MARGIN = 1,
               FUN = min)
  } else {
    x <- ab1
    # ab_name <- deparse(substitute(ab1))
  }

  if (print_warning == TRUE) {
    warning("Increase speed by transforming to class `rsi` on beforehand: df %>% mutate_at(vars(col10:col20), as.rsi)")
  }

  total <- length(x) - sum(is.na(x))
  if (total < minimum) {
    return(NA)
  }

  if (type == "S") {
    found <- .Call(`_AMR_rsi_calc_S`, x, include_I)
  } else if (type == "I") {
    found <- .Call(`_AMR_rsi_calc_I`, x)
  } else if (type == "R") {
    found <- .Call(`_AMR_rsi_calc_R`, x, include_I)
  } else {
    stop("invalid type")
  }

  if (as_percent == TRUE) {
    percent(found / total, force_zero = TRUE)
  } else {
    found / total
  }
}