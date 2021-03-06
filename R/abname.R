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

#' Name of an antibiotic
#'
#' Convert antibiotic codes to a (trivial) antibiotic name or ATC code, or vice versa. This uses the data from \code{\link{antibiotics}}.
#' @param abcode a code or name, like \code{"AMOX"}, \code{"AMCL"} or \code{"J01CA04"}
#' @param from,to type to transform from and to. See \code{\link{antibiotics}} for its column names. WIth \code{from = "guess"} the from will be guessed from \code{"atc"}, \code{"certe"} and \code{"umcg"}. When using \code{to = "atc"}, the ATC code will be searched using \code{\link{as.atc}}.
#' @param textbetween text to put between multiple returned texts
#' @param tolower return output as lower case with function \code{\link{tolower}}.
#' @details \strong{The \code{\link{ab_property}} functions are faster and more concise}, but do not support concatenated strings, like \code{abname("AMCL+GENT"}.
#' @keywords ab antibiotics
#' @source \code{\link{antibiotics}}
#' @export
#' @importFrom dplyr %>% pull
#' @examples
#' abname("AMCL")
#' # "Amoxicillin and beta-lactamase inhibitor"
#'
#' # It is quite flexible at default (having `from = "guess"`)
#' abname(c("amox", "J01CA04", "Trimox", "dispermox", "Amoxil"))
#' # "Amoxicillin" "Amoxicillin" "Amoxicillin" "Amoxicillin" "Amoxicillin"
#'
#' # Multiple antibiotics can be combined with "+".
#' # The second antibiotic will be set to lower case when `tolower` was not set:
#' abname("AMCL+GENT", textbetween = "/")
#' # "amoxicillin and enzyme inhibitor/gentamicin"
#'
#' abname(c("AMCL", "GENT"))
#' # "Amoxicillin and beta-lactamase inhibitor" "Gentamicin"
#'
#' abname("AMCL", to = "trivial_nl")
#' # "Amoxicilline/clavulaanzuur"
#'
#' abname("AMCL", to = "atc")
#' # "J01CR02"
#'
#' # specific codes for University Medical Center Groningen (UMCG):
#' abname("J01CR02", from = "atc", to = "umcg")
#' # "AMCL"
#'
#' # specific codes for Certe:
#' abname("J01CR02", from = "atc", to = "certe")
#' # "amcl"
abname <- function(abcode,
                   from = c("guess", "atc", "certe", "umcg"),
                   to = 'official',
                   textbetween = ' + ',
                   tolower = FALSE) {

  if (length(to) != 1L) {
    stop('`to` must be of length 1', call. = FALSE)
  }

  if (to == "atc") {
    return(as.character(as.atc(abcode)))
  }

  abx <- AMR::antibiotics

  from <- from[1]
  colnames(abx) <- colnames(abx) %>% tolower()
  from <- from %>% tolower()
  to <- to %>% tolower()

  if (!(from %in% colnames(abx) | from == "guess") |
      !to %in% colnames(abx)) {
    stop(paste0('Invalid `from` or `to`. Choose one of ',
                colnames(abx) %>% paste(collapse = ", "), '.'), call. = FALSE)
  }

  abcode <- as.character(abcode)
  abcode.bak <- abcode

  for (i in 1:length(abcode)) {
    if (abcode[i] %like% "[+]") {
      # support for multiple ab's with +
      parts <- trimws(strsplit(abcode[i], split = "+", fixed = TRUE)[[1]])
      ab1 <- abname(parts[1], from = from, to = to)
      ab2 <- abname(parts[2], from = from, to = to)
      if (missing(tolower)) {
        ab2 <- tolower(ab2)
      }
      abcode[i] <- paste0(ab1, textbetween, ab2)
      next
    }
    if (from %in% c("atc", "guess")) {
      if (abcode[i] %in% abx$atc) {
        abcode[i] <- abx[which(abx$atc == abcode[i]),] %>% pull(to) %>% .[1]
        next
      }
    }
    if (from %in% c("certe", "guess")) {
      if (abcode[i] %in% abx$certe) {
        abcode[i] <- abx[which(abx$certe == abcode[i]),] %>% pull(to) %>% .[1]
        next
      }
    }
    if (from %in% c("umcg", "guess")) {
      if (abcode[i] %in% abx$umcg) {
        abcode[i] <- abx[which(abx$umcg == abcode[i]),] %>% pull(to) %>% .[1]
        next
      }
    }
    if (from %in% c("trade_name", "guess")) {
      if (abcode[i] %in% abx$trade_name) {
        abcode[i] <- abx[which(abx$trade_name == abcode[i]),] %>% pull(to) %>% .[1]
        next
      }
      if (sum(abx$trade_name %like% abcode[i]) > 0) {
        abcode[i] <- abx[which(abx$trade_name %like% abcode[i]),] %>% pull(to) %>% .[1]
        next
      }
    }

    if (from != "guess") {
      # when not found, try any `from`
      abcode[i] <- abx[which(abx[,from] == abcode[i]),] %>% pull(to) %>% .[1]
    }

    # when nothing found, try first chars of official name
    # if (is.na(abcode[i])) {
    #   abcode[i] <- antibiotics %>%
    #     filter(official %like% paste0('^', abcode.bak[i])) %>%
    #     pull(to) %>%
    #     .[1]
    #   next
    # }

    if (is.na(abcode[i]) | length(abcode[i] == 0)) {
      abcode[i] <- abcode.bak[i]
      warning('Code "', abcode.bak[i], '" not found in antibiotics list.', call. = FALSE)
    }
  }

  if (tolower == TRUE) {
    abcode <- abcode %>% tolower()
  }

  abcode
}
