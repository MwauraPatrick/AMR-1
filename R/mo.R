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

#' Transform to microorganism ID
#'
#' Use this function to determine a valid ID based on a genus (and species). This input can be a full name (like \code{"Staphylococcus aureus"}), an abbreviated name (like \code{"S. aureus"}), or just a genus. You could also \code{\link{select}} a genus and species column, zie Examples.
#' @param x a character vector or a dataframe with one or two columns
#' @param Becker a logical to indicate whether \emph{Staphylococci} should be categorised into Coagulase Negative \emph{Staphylococci} ("CoNS") and Coagulase Positive \emph{Staphylococci} ("CoPS") instead of their own species, according to Karsten Becker \emph{et al.} [1]. This excludes \emph{Staphylococcus aureus} at default, use \code{Becker = "all"} to also categorise \emph{S. aureus} as "CoPS".
#' @param Lancefield a logical to indicate whether beta-haemolytic \emph{Streptococci} should be categorised into Lancefield groups instead of their own species, according to Rebecca C. Lancefield [2]. These \emph{Streptococci} will be categorised in their first group, i.e. \emph{Streptococcus dysgalactiae} will be group C, although officially it was also categorised into groups G and L. Groups D and E will be ignored, since they are \emph{Enterococci}.
#' @rdname as.mo
#' @aliases mo
#' @keywords mo Becker becker Lancefield lancefield guess
#' @details \code{guess_mo} is an alias of \code{as.mo}.
#'
#' Use the \code{\link{mo_property}} functions to get properties based on the returned mo, see Examples.
#'
#' Some exceptions have been built in to get more logical results, based on prevalence of human pathogens. These are:
#' \itemize{
#'   \item{\code{"E. coli"} will return the ID of \emph{Escherichia coli} and not \emph{Entamoeba coli}, although the latter would alphabetically come first}
#'   \item{\code{"H. influenzae"} will return the ID of \emph{Haemophilus influenzae} and not \emph{Haematobacter influenzae}}
#'   \item{Something like \code{"p aer"} will return the ID of \emph{Pseudomonas aeruginosa} and not \emph{Pasteurella aerogenes}}
#'   \item{Something like \code{"stau"} or \code{"staaur"} will return the ID of \emph{Staphylococcus aureus} and not \emph{Staphylococcus auricularis}}
#' }
#' Moreover, this function also supports ID's based on only Gram stain, when the species is not known. \cr
#' For example, \code{"Gram negative rods"} and \code{"GNR"} will both return the ID of a Gram negative rod: \code{GNR}.
#' @source
#' [1] Becker K \emph{et al.} \strong{Coagulase-Negative Staphylococci}. 2014. Clin Microbiol Rev. 27(4): 870–926. \cr
#'     \url{https://dx.doi.org/10.1128/CMR.00109-13} \cr
#' [2] Lancefield RC \strong{A serological differentiation of human and other groups of hemolytic streptococci}. 1933. J Exp Med. 57(4): 571–95. \cr
#'     \url{https://dx.doi.org/10.1084/jem.57.4.571}
#' @export
#' @importFrom dplyr %>% pull left_join
#' @return Character (vector) with class \code{"mo"}. Unknown values will return \code{NA}.
#' @seealso \code{\link{microorganisms}} for the dataframe that is being used to determine ID's.
#' @examples
#' # These examples all return "STAAUR", the ID of S. aureus:
#' as.mo("stau")
#' as.mo("STAU")
#' as.mo("staaur")
#' as.mo("S. aureus")
#' as.mo("S aureus")
#' as.mo("Staphylococcus aureus")
#' as.mo("MRSA") # Methicillin Resistant S. aureus
#' as.mo("VISA") # Vancomycin Intermediate S. aureus
#' as.mo("VRSA") # Vancomycin Resistant S. aureus
#'
#' # guess_mo is an alias of as.mo and works the same
#' guess_mo("S. epidermidis")                 # will remain species: STAEPI
#' guess_mo("S. epidermidis", Becker = TRUE)  # will not remain species: STACNS
#'
#' guess_mo("S. pyogenes")                    # will remain species: STCAGA
#' guess_mo("S. pyogenes", Lancefield = TRUE) # will not remain species: STCGRA
#'
#' # Use mo_* functions to get a specific property based on `mo`
#' Ecoli <- as.mo("E. coli") # returns `ESCCOL`
#' mo_genus(Ecoli)               # returns "Escherichia"
#' mo_gramstain(Ecoli)           # returns "Negative rods"
#'
#' \dontrun{
#' df$mo <- as.mo(df$microorganism_name)
#'
#' # the select function of tidyverse is also supported:
#' library(dplyr)
#' df$mo <- df %>%
#'   select(microorganism_name) %>%
#'   guess_mo()
#'
#' # and can even contain 2 columns, which is convenient for genus/species combinations:
#' df$mo <- df %>%
#'   select(genus, species) %>%
#'   guess_mo()
#'
#' # same result:
#' df <- df %>%
#'   mutate(mo = guess_mo(paste(genus, species)))
#' }
as.mo <- function(x, Becker = FALSE, Lancefield = FALSE) {


  if (NCOL(x) == 2) {
    # support tidyverse selection like: df %>% select(colA, colB)
    # paste these columns together
    x_vector <- vector("character", NROW(x))
    for (i in 1:NROW(x)) {
      x_vector[i] <- paste(pull(x[i,], 1), pull(x[i,], 2), sep = " ")
    }
    x <- x_vector
  } else {
    if (NCOL(x) > 2) {
      stop('`x` can be 2 columns at most', call. = FALSE)
    }

    # support tidyverse selection like: df %>% select(colA)
    if (!is.vector(x)) {
      x <- pull(x, 1)
    }
  }

  MOs <- AMR::microorganisms %>% filter(!mo %like% '^_FAM') # dont search in those
  failures <- character(0)
  x_input <- x

  # only check the uniques, which is way faster
  x <- unique(x)

  x_backup <- x
  # remove dots and other non-text in case of "E. coli" except spaces
  x <- gsub("[^a-zA-Z0-9 ]+", "", x)
  # but spaces before and after should be omitted
  x <- trimws(x, which = "both")
  x_trimmed <- x
  # replace space by regex sign
  x_withspaces <- gsub(" ", ".* ", x, fixed = TRUE)
  x <- gsub(" ", ".*", x, fixed = TRUE)
  # for species
  x_species <- paste(x, 'species')
  # add start en stop regex
  x <- paste0('^', x, '$')
  x_withspaces <- paste0('^', x_withspaces, '$')

  for (i in 1:length(x)) {

    if (Becker == TRUE | Becker == "all") {
      mo <- suppressWarnings(guess_mo(x_backup[i]))
      if (mo %like% '^STA') {
        # See Source. It's this figure:
        # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4187637/figure/F3/
        species <- left_join_microorganisms(mo)$species
        if (species %in% c("arlettae", "auricularis", "capitis",
                           "caprae", "carnosus", "cohnii", "condimenti",
                           "devriesei", "epidermidis", "equorum",
                           "fleurettii", "gallinarum", "haemolyticus",
                           "hominis", "jettensis", "kloosii", "lentus",
                           "lugdunensis", "massiliensis", "microti",
                           "muscae", "nepalensis", "pasteuri", "petrasii",
                           "pettenkoferi", "piscifermentans", "rostri",
                           "saccharolyticus", "saprophyticus", "sciuri",
                           "stepanovicii", "simulans", "succinus",
                           "vitulinus", "warneri", "xylosus")) {
          x[i] <- "STACNS"
          next
        } else if ((Becker == "all"  & species == "aureus")
                   | species %in% c("simiae", "agnetis", "chromogenes",
                                    "delphini", "felis", "lutrae",
                                    "hyicus", "intermedius",
                                    "pseudintermedius", "pseudointermedius",
                                    "schleiferi")) {
          x[i] <- "STACPS"
          next
        }
      }
    }

    if (Lancefield == TRUE) {
      mo <- suppressWarnings(guess_mo(x_backup[i]))
      if (mo %like% '^STC') {
        # See Source
        species <- left_join_microorganisms(mo)$species
        if (species == "pyogenes") {
          x[i] <- "STCGRA"
          next
        }
        if (species == "agalactiae") {
          x[i] <- "STCGRB"
          next
        }
        if (species %in% c("equisimilis", "equi",
                           "zooepidemicus", "dysgalactiae")) {
          x[i] <- "STCGRC"
          next
        }
        if (species == "anginosus") {
          x[i] <- "STCGRF"
          next
        }
        if (species == "sanguis") {
          x[i] <- "STCGRH"
          next
        }
        if (species == "salivarius") {
          x[i] <- "STCGRK"
          next
        }
      }
    }

    if (identical(x_trimmed[i], "")) {
      # empty values
      x[i] <- NA
      failures <- c(failures, x_backup[i])
      next
    }
    if (x_backup[i] %in% AMR::microorganisms$mo) {
      # is already a valid mo
      x[i] <- x_backup[i]
      next
    }
    if (x_trimmed[i] %in% AMR::microorganisms$mo) {
      # is already a valid mo
      x[i] <- x_trimmed[i]
      next
    }

    if (tolower(x[i]) == '^e.*coli$') {
      # avoid detection of Entamoeba coli in case of E. coli
      x[i] <- 'ESCCOL'
      next
    }
    if (tolower(x[i]) == '^h.*influenzae$') {
      # avoid detection of Haematobacter influenzae in case of H. influenzae
      x[i] <- 'HAEINF'
      next
    }
    if (tolower(x[i]) == '^st.*au$'
        | tolower(x[i]) == '^stau$'
        | tolower(x[i]) == '^staaur$') {
      # avoid detection of Staphylococcus auricularis in case of S. aureus
      x[i] <- 'STAAUR'
      next
    }
    if (tolower(x[i]) == '^p.*aer$') {
      # avoid detection of Pasteurella aerogenes in case of Pseudomonas aeruginosa
      x[i] <- 'PSEAER'
      next
    }
    if (tolower(x[i]) %like% 'coagulase negative'
        | tolower(x[i]) %like% 'cns'
        | tolower(x[i]) %like% 'cons') {
      # coerce S. coagulase negative, also as CNS and CoNS
      x[i] <- 'STACNS'
      next
    }

    # translate known trivial names to genus+species
    if (!is.na(x_trimmed[i])) {
      if (toupper(x_trimmed[i]) == 'MRSA'
          | toupper(x_trimmed[i]) == 'VISA'
          | toupper(x_trimmed[i]) == 'VRSA') {
        x[i] <- 'STAAUR'
        next
      }
      if (toupper(x_trimmed[i]) == 'MRSE') {
        x[i] <- 'STAEPI'
        next
      }
      if (toupper(x_trimmed[i]) == 'VRE') {
        x[i] <- 'ENC'
        next
      }
      if (toupper(x_trimmed[i]) == 'MRPA') {
        # multi resistant P. aeruginosa
        x[i] <- 'PSEAER'
        next
      }
      if (toupper(x_trimmed[i]) %in% c('PISP', 'PRSP', 'VISP', 'VRSP')) {
        # peni R, peni I, vanco I, vanco R: S. pneumoniae
        x[i] <- 'STCPNE'
        next
      }
    }

    # try any match keeping spaces
    found <- MOs[which(MOs$fullname %like% x_withspaces[i]),]$mo
    if (length(found) > 0) {
      x[i] <- found[1L]
      next
    }

    # try any match diregarding spaces
    found <- MOs[which(MOs$fullname %like% x[i]),]$mo
    if (length(found) > 0) {
      x[i] <- found[1L]
      next
    }

    # try exact match of only genus, with 'species' attached
    # (this prevents Streptococcus from becoming Peptostreptococcus, since "p" < "s")
    found <- MOs[which(MOs$fullname == x_species[i]),]$mo
    if (length(found) > 0) {
      x[i] <- found[1L]
      next
    }

    # try any match of only genus, with 'species' attached
    found <- MOs[which(MOs$fullname %like% x_species[i]),]$mo
    if (length(found) > 0) {
      x[i] <- found[1L]
      next
    }

    # search for GLIMS code
    found <- AMR::microorganisms.umcg[which(toupper(AMR::microorganisms.umcg$umcg) == toupper(x_trimmed[i])),]$mo
    if (length(found) > 0) {
      x[i] <- found[1L]
      next
    }

    # try splitting of characters and then find ID
    # like esco = E. coli, klpn = K. pneumoniae, stau = S. aureus
    x_split <- x
    x_length <- nchar(x_trimmed[i])
    x_split[i] <- paste0(x_trimmed[i] %>% substr(1, x_length / 2) %>% trimws(),
                         '.* ',
                         x_trimmed[i] %>% substr((x_length / 2) + 1, x_length) %>% trimws())
    found <- MOs[which(MOs$fullname %like% paste0('^', x_split[i])),]$mo
    if (length(found) > 0) {
      x[i] <- found[1L]
      next
    }

    # try any match with text before and after original search string
    # so "negative rods" will be "GNR"
    if (x_trimmed[i] %like% "^Gram") {
      x_trimmed[i] <- gsub("^Gram", "", x_trimmed[i], ignore.case = TRUE)
      # remove leading and trailing spaces again
      x_trimmed[i] <- trimws(x_trimmed[i], which = "both")
    }
    if (!is.na(x_trimmed[i])) {
      found <- MOs[which(MOs$fullname %like% x_trimmed[i]),]$mo
      if (length(found) > 0) {
        x[i] <- found[1L]
        next
      }
    }

    # not found
    x[i] <- NA_character_
    failures <- c(failures, x_backup[i])

  }

  failures <- failures[!failures %in% c(NA, NULL, NaN)]
  if (length(failures) > 0) {
    warning("These values could not be coerced to a valid mo: ",
            paste('"', unique(failures), '"', sep = "", collapse = ', '),
            ".",
            call. = FALSE)
  }

  # left join the found results to the original input values (x_input)
  df_found <- data.frame(input = as.character(unique(x_input)),
                         found = x,
                         stringsAsFactors = FALSE)
  df_input <- data.frame(input = as.character(x_input),
                         stringsAsFactors = FALSE)

  x <- df_input %>%
    left_join(df_found,
              by = "input") %>%
    pull(found)

  class(x) <- "mo"
  attr(x, 'package') <- 'AMR'
  x
}

#' @rdname as.mo
#' @export
is.mo <- function(x) {
  # bactid for older releases
  # remove when is.bactid will be removed
  identical(class(x), "mo") | identical(class(x), "bactid")
}

#' @rdname as.mo
#' @export
guess_mo <- as.mo

#' @exportMethod print.mo
#' @export
#' @noRd
print.mo <- function(x, ...) {
  cat("Class 'mo'\n")
  print.default(as.character(x), quote = FALSE)
}

#' @exportMethod as.data.frame.mo
#' @export
#' @noRd
as.data.frame.mo <- function (x, ...) {
  # same as as.data.frame.character but with removed stringsAsFactors
  nm <- paste(deparse(substitute(x), width.cutoff = 500L),
              collapse = " ")
  if (!"nm" %in% names(list(...))) {
    as.data.frame.vector(x, ..., nm = nm)
  } else {
    as.data.frame.vector(x, ...)
  }
}

#' @exportMethod pull.mo
#' @export
#' @importFrom dplyr pull
#' @noRd
pull.mo <- function(.data, ...) {
  pull(as.data.frame(.data), ...)
}

#' @exportMethod print.bactid
#' @export
#' @noRd
print.bactid <- function(x, ...) {
  cat("Class 'bactid'\n")
  print.default(as.character(x), quote = FALSE)
}

#' @exportMethod as.data.frame.bactid
#' @export
#' @noRd
as.data.frame.bactid <- function (x, ...) {
  # same as as.data.frame.character but with removed stringsAsFactors
  nm <- paste(deparse(substitute(x), width.cutoff = 500L),
              collapse = " ")
  if (!"nm" %in% names(list(...))) {
    as.data.frame.vector(x, ..., nm = nm)
  } else {
    as.data.frame.vector(x, ...)
  }
}

#' @exportMethod pull.bactid
#' @export
#' @importFrom dplyr pull
#' @noRd
pull.bactid <- function(.data, ...) {
  pull(as.data.frame(.data), ...)
}