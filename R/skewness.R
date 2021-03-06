#' Skewness of the sample
#'
#' @description Skewness is a measure of the asymmetry of the probability distribution of a real-valued random variable about its mean.
#'
#' When negative: the left tail is longer; the mass of the distribution is concentrated on the right of the figure. When positive: the right tail is longer; the mass of the distribution is concentrated on the left of the figure.
#' @param x a vector of values, a \code{matrix} or a \code{data frame}
#' @param na.rm a logical value indicating whether \code{NA} values should be stripped before the computation proceeds.
#' @exportMethod skewness
#' @seealso \code{\link{kurtosis}}
#' @rdname skewness
#' @export
skewness <- function(x, na.rm = FALSE) {
  UseMethod("skewness")
}

#' @exportMethod skewness.default
#' @rdname skewness
#' @export
skewness.default <- function (x, na.rm = FALSE) {
  x <- as.vector(x)
  if (na.rm == TRUE) {
    x <- x[!is.na(x)]
  }
  n <- length(x)
  (base::sum((x - base::mean(x))^3) / n) / (base::sum((x - base::mean(x))^2) / n)^(3/2)
}

#' @exportMethod skewness.matrix
#' @rdname skewness
#' @export
skewness.matrix <- function (x, na.rm = FALSE) {
  base::apply(x, 2, skewness.default, na.rm = na.rm)
}

#' @exportMethod skewness.data.frame
#' @rdname skewness
#' @export
skewness.data.frame <- function (x, na.rm = FALSE) {
  base::sapply(x, skewness.default, na.rm = na.rm)
}
