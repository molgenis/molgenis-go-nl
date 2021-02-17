#'////////////////////////////////////////////////////////////////////////////
#' FILE: pubmed_update.R
#' AUTHOR: David Ruvolo
#' CREATED: 2021-01-27
#' MODIFIED: 2021-01-27
#' PURPOSE: update publication history
#' STATUS: in.progress
#' PACKAGES: see below
#' COMMENTS: Na
#'////////////////////////////////////////////////////////////////////////////

# pkgs
suppressPackageStartupMessages(library(dplyr))

# for testing
source("R/pubmed_utils.R")
Sys.setenv("MOLGENIS_TOKEN" = "2v0s7OGZWIqYMHyub4vZjkvDTYP2RSxi")

httr::set_config(httr::config(http_version = 0))

# define molgenis API endpoints
molgenis <- list(
    host = "https://go-nl-acc.gcc.rug.nl",
    token = Sys.getenv("MOLGENIS_TOKEN")
)

#'////////////////////////////////////////////////////////////////////////////

#' ~ 1 ~
#' Run Queries
#' fetch Pubmed API queries and publications entity from Molgenis

# start msg
cli::cli_alert_info("Importing reference datasets from Molgenis Host")

#' ~ 1a ~
# fetch API queries
queries_response <- httr::GET(
    url = paste0(molgenis$host, "/api/v1/publications_queries"),
    httr::add_headers(
        `x-molgenis-token` = molgenis$token
    )
)

# process queries responses
if (queries_response$status_code == 200) {
    cli::cli_alert_success("Imported Pubmed API queries entity")
    queries <- httr::content(
        x = queries_response,
        as = "text",
        encoding = "UTF-8"
    ) %>%
    jsonlite::fromJSON(.) %>%
        `[[`("items") %>%
        select(-href)
} else {
    cli::cli_alert_danger("Failed to import Pubmed API queries entity")
    queries <- NA
}

#' ~ 1b ~
#' Fetch Publications Data
pubs_response <- httr::GET(
    url = paste0(molgenis$host, "/api/v1/publications_records"),
    httr::add_headers(
        `x-molgenis-token` = molgenis$token
    )
)

# process response
if (pubs_response$status_code == 200) {
    cli::cli_alert_success("Imported publications records entity")
    data <- httr::content(pubs_response, "text", encoding = "UTF-8") %>%
        jsonlite::fromJSON(.) %>%
        `[[`("items")

    if (is.null(data)) {
        data <- data %>% select(-href)
    }
} else {
    cli::cli_alert_danger("Failed to import publication records entity")
    data <- NA
}

#'//////////////////////////////////////

#' ~ 2 ~
#' Query Publications Data

# Init object to write api results into
api <- list()

#' ~ 2a ~
# Run queries to identify new publications
cli::cli_alert_info("Processing publication queries:")
if (NROW(queries$query) > 1) {
    cli::cli_alert_info("Binding multiple queries into an array")
    api$ids <- unlist(
        lapply(
            X = queries$query,
            FUN = function(x) {
                pubmed$get_ids(query = x)
            }
        )
    )
} else {
    cli::cli_alert_info("Fetching IDs using one query")
    api$ids <- pubmed$get_ids(queries$query)
}

#' ~ 2b ~
# remove existing IDs from api ID query list
cli::cli_alert_info("Removing existing IDs using reference data: ")
api$ids <- api$ids[!api$ids %in% data$uid]

#' ~ 2c ~
# fetch publication metadata (if there are new Ids)
if (length(api$ids) > 0) {
    cli::cli_alert_info("Total IDs to query: {.val {length(api$ids)}}")
    cli::cli_alert_info("Pulling Metadata for new IDs: ")
    result <- pubmed$get_metadata(
        ids = api$ids,
        delay = sample(runif(50, 0.75, 2), length(api$ids))
    )

    # prepare publications dataset
    pubs <- pubmed$build_df(data = result)
    cli::cli_alert_info(
        "Processed data dims: {.val {paste0(dim(pubs), collapse = ', ')}}"
    )

    main <- dplyr::bind_rows(data, pubs) %>% arrange(uid)

    # save data
    cli::cli_alert_info("Importing data into molgenis")
    readr::write_csv(main, "data/publications_records.csv")

    # import
    resp <- httr::POST(
        url = paste0(molgenis$host, "/plugin/importwizard/importFile/"),
        body = list(
            file = httr::upload_file("data/publications_records.csv")
        ),
        httr::add_headers(
            `x-molgenis-token` = molgenis$token
        )
    )

    # process response
    if (resp$status_code == 201) {
        cli::cli_alert_success("Successfully imported!")
    } else {
        cli::cli_alert_danger("Failed to import publications data")
    }

} else {
    cli::cli_alert_info("Publication records are up to date")
}