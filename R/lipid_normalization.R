#' Normalize lipid annotation names conservatively
#'
#' @description
#' Detect simple lipid-like names and normalize them to a conservative reporting
#' level. Molecular species such as `Cer(18:1)` are kept as molecular species,
#' while two-chain annotations such as `PC(16:0/18:2)` are collapsed to sum
#' composition. Lipid class-only names are kept out of the core metabolite tier.
#'
#' @param names Character vector of metabolite names.
#'
#' @return A data.frame with original name, normalized name, lipid class,
#'   lipid annotation level, and lipid flag.
#' @export
normalize_lipid_annotation <- function(names) {
  original <- as.character(names)
  normalized <- trimws(original)
  lipid_class <- rep(NA_character_, length(original))
  lipid_level <- rep("not_lipid", length(original))
  is_lipid <- rep(FALSE, length(original))

  for (i in seq_along(original)) {
    value <- normalized[[i]]
    if (is.na(value) || !grepl("^[A-Za-z]+\\(", value)) {
      next
    }

    lipid_class[[i]] <- sub("^([A-Za-z]+)\\(.*$", "\\1", value)
    is_lipid[[i]] <- TRUE
    inside <- sub("^[A-Za-z]+\\((.*)\\)$", "\\1", value)
    chain_matches <- regmatches(inside, gregexpr("[0-9]+:[0-9]+", inside, perl = TRUE))[[1]]

    if (length(chain_matches) >= 2) {
      carbons <- sum(as.numeric(sub(":.*$", "", chain_matches)))
      double_bonds <- sum(as.numeric(sub("^.*:", "", chain_matches)))
      normalized[[i]] <- sprintf("%s(%d:%d)", lipid_class[[i]], carbons, double_bonds)
      lipid_level[[i]] <- "sum_composition"
    } else if (length(chain_matches) == 1) {
      lipid_level[[i]] <- "molecular_species"
    } else {
      normalized[[i]] <- sprintf("%s(class)", lipid_class[[i]])
      lipid_level[[i]] <- "class_only"
    }
  }

  data.frame(
    original_name = original,
    normalized_name = normalized,
    lipid_class = lipid_class,
    lipid_annotation_level = lipid_level,
    is_lipid = is_lipid,
    stringsAsFactors = FALSE
  )
}
