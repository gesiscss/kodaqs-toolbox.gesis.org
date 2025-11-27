library(ymlthis)
library(yaml)
library(rmarkdown)


#' Render single contribution
#'
#' @param contribution_row
#'
#' @return
#' @export
#'
#' @examples
create_output_directory <- function(output_location) {
  investigate_file_or_directory(output_location)
  if (!dir.create(output_location, recursive = TRUE, showWarnings = FALSE)) {
    # Check if the directory creation failed
    if (!file.exists(output_location)) {
      stop(paste("Failed to create the directory:", output_location))
    }
  } else {
    # Directory was created successfully
    logger::log_debug(paste("Directory created successfully at:", output_location))

    # Set permissions to 777
    tryCatch({
      Sys.chmod(output_location, mode = "0777", use_umask = FALSE)
      logger::log_debug(paste("Permissions set to 777 for directory:", output_location))
    }, error = function(e) {
      logger::log_error(paste("Failed to set permissions for directory:", output_location, "Error:", e$message))
    })
  }
}

render_single_contribution <- function(contribution_row, is_docker_rootless = FALSE, doi_mapping = NULL, self_assessment_mapping = NULL) {
  logger::log_debug("Rendering {contribution_row['filename']} from {contribution_row['web_address']}")

  if (is_docker_rootless) {
    host_user_id <- 0
    host_group_id <- 0
    logger::log_debug("Running with user ID 0 and group ID 0, i.e., rootless.")
  } else {
    host_user_id <- system("id -u", intern = TRUE)
    host_group_id <- system("id -g", intern = TRUE)
    logger::log_debug("Running with user ID {host_user_id} and group ID {host_group_id}.")
  }

  RENDER_MATRIX <- list(
    "md" = c(
      "md2md.sh",
      "md2qmd.sh",
      "md2ipynb.sh"
    ),
    "qmd" = c(
      "qmd2md.sh",
      "qmd2qmd.sh",
      "qmd2ipynb.sh"
    ),
    "Rmd" = c(
      "Rmd2md.sh",
      "Rmd2qmd.sh",
      "Rmd2ipynb.sh"
    ),
    "ipynb" = c(
      "ipynb2md.sh",
      "ipynb2qmd.sh",
      "ipynb2ipynb.sh"
    ),
    "docx" = c(
      "docx2md.sh"
    )
  )

  if (is.na(contribution_row["docker_image"])) {
    logger::log_warn("Docker image is NA! Using registry.gitlab.com/quarto-forge/docker/quarto.")
    docker_image <- "registry.gitlab.com/quarto-forge/docker/quarto"
    home_dir_at_docker <- "/tmp"
    render_at_dir <- fs::path(contribution_row["domain"])
    mount_input_file <- stringr::str_interp(
      "--mount type=bind,source=${input_file_path},target=${home_dir_at_docker}/${filename}",
      list(
        input_file_path = fs::path_real(fs::path(contribution_row["tmp_path"], contribution_row["filename"])),
        home_dir_at_docker = home_dir_at_docker,
        filename = contribution_row["filename"]
      )
    )
  } else {
    docker_image <- contribution_row["docker_image"]
    home_dir_at_docker <- "/home/andrew"
    render_at_dir <- fs::path(contribution_row["domain"], contribution_row["slang"])
    mount_input_file <- ""
  }

  file2render <- contribution_row["filename"]
  file2render_extension <- contribution_row["filename_extension"]
  github_https <- contribution_row["https"]
  github_user_name <- contribution_row["user_name"]
  github_repository_name <- contribution_row["repository_name"]

  fs::dir_create(render_at_dir)

  docker_scripts_location <-
    system.file("docker-scripts", package = "andrew", mustWork = TRUE)
  pandoc_filters_location <-
    system.file("pandoc-filters", package = "andrew", mustWork = TRUE)

  output_location <- render_at_dir |>
    fs::path_real()
  output_location_in_container <- "/tmp/andrew"

  logger::log_debug("Location of docker_scripts directory: {docker_scripts_location}")
  logger::log_debug("Location of pandoc_filters directory: {pandoc_filters_location}")
  logger::log_debug("Location of output directory: {output_location}")
  logger::log_debug("Location of output directory inside the container: {output_location_in_container}")

  create_output_directory(output_location)


  sum_docker_return_value <- 0
  for (script in get(file2render_extension, RENDER_MATRIX)) {
    logger::log_debug("Rendering using {script} ...")

    docker_call_template <- 'docker run \\
    --user=${host_user_id}:${host_group_id} \\
    ${mount_input_file} \\
    --mount type=bind,source=${docker_scripts_location},target=${home_dir_at_docker}/_docker-scripts \\
    --env docker_script_root=${home_dir_at_docker}/_docker-scripts \\
    --mount type=bind,source=${pandoc_filters_location},target=${home_dir_at_docker}/_pandoc-filters \\
    --mount type=bind,source=${output_location},target=${output_location_in_container} \\
    --env github_https=${github_https} \\
    --env github_user_name=${github_user_name} \\
    --env github_repository_name=${github_repository_name} \\
    --env file2render=${file2render} \\
    --env docker_image=${docker_image} \\
    --env output_location=${output_location_in_container} \\
    ${docker_image} \\
    /bin/bash -c "${home_dir_at_docker}/_docker-scripts/${script}"'

    docker_call <- stringr::str_interp(
      docker_call_template,
      list(
        host_user_id = host_user_id,
        host_group_id = host_group_id,
        mount_input_file = mount_input_file,
        home_dir_at_docker = home_dir_at_docker,
        docker_scripts_location = docker_scripts_location,
        pandoc_filters_location = pandoc_filters_location,
        output_location = output_location,
        output_location_in_container = output_location_in_container,
        file2render = file2render,
        github_https = github_https,
        github_user_name = github_user_name,
        github_repository_name = github_repository_name,
        docker_image = docker_image,
        script = script
      )
    )
    logger::log_info(docker_call)

    docker_return_value <- system(docker_call)

    logger::log_debug("Rendering markdown complete. Docker returned {docker_return_value}.")
    markdown_files <- list.files(output_location, recursive = TRUE)
    logger::log_debug("Output dir {output_location} contains the files {markdown_files}" )

    sum_docker_return_value <- sum_docker_return_value + docker_return_value
  }

  # Extract filename without extension
  file2render_basename <- tools::file_path_sans_ext(file2render)
  # add the citation.cff data if available
  index_md <- file.path(output_location, file2render_basename, "index.md")
  citation_cff <- file.path(output_location, file2render_basename, "CITATION.cff")
  update_citation_metadata(citation_file = citation_cff, output_file = index_md, doi_mapping = doi_mapping, self_assessment_mapping = self_assessment_mapping)
  
  if (sum_docker_return_value == 0) {
    build_status <- "Built"

    logger::log_debug("Rendering PDF ...")

    docker_pdf_call_template <- 'docker run \\
      --user=${host_user_id}:${host_user_id} \\
      --mount type=bind,source=${docker_scripts_location},target=/home/mambauser/_docker-scripts \\
      --mount type=bind,source=${output_location},target=/home/mambauser/andrew \\
      --env file2render=${file2render} \\
      registry.gitlab.com/quarto-forge/docker/quarto_all \\
      /bin/bash -c "/home/mambauser/_docker-scripts/md2pdf.sh"'

    docker_pdf_call <- stringr::str_interp(
      docker_pdf_call_template,
      list(
        host_user_id = host_user_id,
        docker_scripts_location = docker_scripts_location,
        output_location = output_location,
        output_location_in_container = output_location_in_container,
        file2render = file2render
      )
    )

    docker_return_value <- system(docker_pdf_call)

    logger::log_debug("Rendering PDF completed.")
  } else {
    build_status <- "Unavailable"
    logger::log_debug("Skipping PDF rendering.")
  }

  return(build_status)
}


#' Render all contributions from database
#'
#' @param all_contributions
#'
#' @return
#' @export
#'
#' @examples
render_contributions <- function(all_contributions, is_docker_rootless = FALSE) {
  
  # Extract DOIs from zettelkasten.json
  current_dir <- getwd()
  zettelkasten_path <- file.path(dirname(current_dir), "demo", "zettelkasten.json")
  doi_mapping <- list()
  zettelkasten_data <- jsonlite::read_json(zettelkasten_path)
  for (category in zettelkasten_data) {
    if (!is.null(category$content_set) && length(category$content_set) > 0) {
      for (content in category$content_set) {
        if (!is.null(content$web_address) && !is.null(content$doi) && 
            content$doi != "#To_be_added" && content$doi != "") {
          web_addr <- gsub("\\.git$", "", content$web_address)
          doi_mapping[[web_addr]] <- content$doi
        }
      }
    }
  }
  
  # Extract self-assessment links
  content_contributions_path <- file.path(dirname(current_dir), "demo", "content-contributions.json")
  self_assessment_mapping <- list()
  contributions_data <- jsonlite::read_json(content_contributions_path)
  for (contribution in contributions_data) {
    if (!is.null(contribution$self_assessment)) {
      web_addr <- gsub("\\.git$", "", contribution$web_address)
      self_assessment_mapping[[web_addr]] <- contribution$self_assessment
    }
  }
  
  all_contributions$status <- all_contributions |>
    apply(1, function(contribution_row) {
      render_single_contribution(contribution_row, is_docker_rootless, doi_mapping, self_assessment_mapping)
    })

  return(all_contributions)
}

#' Use CITATION.cff to fill the metadata for the tools
#' This uses the created index.md file
#'
update_citation_metadata <- function(citation_file, output_file, doi_mapping = NULL, self_assessment_mapping = NULL) {

  investigate_file_or_directory(output_file)

  # Initialize variables
  citation_yaml <- NULL
  url_field <- NULL
  url <- "https://kodaqs-toolbox.gesis.org/"  # default fallback
  
  citation_dir <- dirname(citation_file)
  # exact case-sensitive match for CITATION.cff
  if (!file.exists(citation_file) && dir.exists(citation_dir)) {
    # case-insensitive search for citation.cff variations
    all_files <- list.files(citation_dir, full.names = TRUE)
    for (file_path in all_files) {
      filename <- basename(file_path)
      if (tolower(filename) == "citation.cff") {
        citation_file <- file_path
        break
      }
    }
  }

  # Check if the CITATION.cff file exists
  if (file.exists(citation_file)) {
    # Parse the CITATION.cff file
    citation_yaml <- yaml::read_yaml(citation_file)
    if (!is.null(citation_yaml$identifiers)) {
      url_field <- citation_yaml$identifiers[[1]]$value
    }
    url <- ifelse(!is.null(url_field), url_field, "https://kodaqs-toolbox.gesis.org/")
  }

  # Find matching DOI from doi_mapping
  matching_doi <- NULL
  if (!is.null(doi_mapping)) {
    # Parse the output file to get GitHub URL
    output_yaml <- rmarkdown::yaml_front_matter(output_file)
    
    # Get repo URL from github_https, or try to construct from parts
    repo_url <- output_yaml$github_https
    if (is.null(repo_url) && !is.null(output_yaml$github_user_name) && !is.null(output_yaml$github_repository_name)) {
      repo_url <- paste0("https://github.com/", output_yaml$github_user_name, "/", output_yaml$github_repository_name)
    }
    
    if (!is.null(repo_url)) {
      # finding doi
      matching_doi <- doi_mapping[[repo_url]]

      if (is.null(matching_doi)) {
        repo_url_no_git <- gsub("\\.git$", "", repo_url)
        repo_url_with_git <- paste0(gsub("\\.git$", "", repo_url), ".git")
        matching_doi <- doi_mapping[[repo_url_no_git]]
        if (is.null(matching_doi)) {
          matching_doi <- doi_mapping[[repo_url_with_git]]
        }
      }
      
      # partial matching the doi
      if (is.null(matching_doi)) {
        for (url in names(doi_mapping)) {
          clean_url <- gsub("\\.git$", "", url)
          clean_repo <- gsub("\\.git$", "", repo_url)
          if (grepl(basename(clean_repo), clean_url) || grepl(basename(clean_url), clean_repo)) {
            matching_doi <- doi_mapping[[url]]
            break
          }
        }
      }
    }
  }

  # Find matching self-assessment
  matching_self_assessment <- NULL
  if (!is.null(self_assessment_mapping)) {
    # Check the output file to get the URL
    output_yaml <- rmarkdown::yaml_front_matter(output_file)
    repo_url <- output_yaml$github_https
    if (is.null(repo_url)) {
      repo_url <- paste0("https://github.com/", output_yaml$github_user_name, "/", output_yaml$github_repository_name)
    }
    clean_repo_url <- gsub("\\.git$", "", repo_url)
    matching_self_assessment <- self_assessment_mapping[[clean_repo_url]]
  }

  
  if (!file.exists(citation_file) && is.null(matching_doi)) {
    message("No CITATION.cff file found. No changes made to the output file.")
    return()
  }

  # Only create citation metadata if citation file exists
  if (file.exists(citation_file)) {
    citation_list <- list(
      type = "document",
      title = if (!is.null(citation_yaml$title) && citation_yaml$title != "") citation_yaml$title else "Untitled",
      author = lapply(citation_yaml$authors, function(author) {
        if (!is.null(author$name)) {
          # Handle the case where the author has a single "name" field
          list(name = author$name)
        } else if (!is.null(author$`given-names`) && !is.null(author$`family-names`)) {
          # Handle the case where the author has separate "given-names" and "family-names"
          list(name = paste(author$`given-names`, author$`family-names`))
        }
      }),
      issued = if (!is.null(citation_yaml$`date-released`)) citation_yaml$`date-released` else format(Sys.Date(), "%Y-%m-%d"),
      accessed = format(Sys.Date(), "%Y-%m-%d"),  # Use the current date for the access date
      `container-title` = "In F. Kraemer, Y. Peters, A.-K. Stroppe, J. Daikeler, F. Draxler, F. Kreuter, F. Keusch, T. Knopf, L. Mejia Lopez, B. Rammstedt, P. Siegers, H. Silber, J. Sun, C. Wagner, K. Weller, C. Yıldız, S. Jünger, S. Kapidzic, & L. Young (Eds.), KODAQS Toolbox",  # Updated container title
      #publisher = "GESIS – Leibniz Institute for the Social Sciences",
      URL = if (!is.null(citation_yaml$url)) citation_yaml$url else url  # Use URL from citation.cff or fallback to the url variable
    )
    citation_metadata <- list(citation = citation_list)

    # Parse YAML metadata from the output file
    output_yaml <- rmarkdown::yaml_front_matter(output_file)

    # Merge output metadata with the new citation metadata
    merged_yaml <- modifyList(output_yaml, citation_metadata)

    # Convert the merged YAML back to string format
    yaml_str <- yaml::as.yaml(merged_yaml)

    # Read the entire content of the output file
    output_content <- readLines(output_file)

    # Locate the YAML front matter delimiters
    yaml_start <- which(output_content == "---")[1]
    yaml_end <- which(output_content == "---")[2]

    # Extract the body content
    body_content <- if (!is.na(yaml_end)) output_content[(yaml_end + 1):length(output_content)] else output_content

    # Combine the cleaned YAML metadata and the body content
    full_content <- c("---", yaml_str, "---", body_content)
  } else {
    # No citation file, just read the existing content without adding citation metadata
    output_content <- readLines(output_file)
    full_content <- output_content
  }


  # Add self-assessment section (only for HTML)
  if (!is.null(matching_self_assessment)) {
    self_assessment_section <- c(
      "",
      '::: {.content-visible when-format="html"}',
      "",
      '<section id="quiz" class="level2 appendix quiz-section">',
      '<h2 class="anchored quarto-appendix-heading">Self-assessment Quizzes</h2>',
      '<div class="quarto-appendix-contents">',
      paste0('<a target="_blank" rel="noopener noreferrer" href="', matching_self_assessment, '">Click here</a>'),
      '</div>',
      '</section>',
      "",
      ':::',
      ""
    )
    full_content <- c(full_content, self_assessment_section)
  }

  # Add DOI section
  if (!is.null(matching_doi)) {
    doi_section <- c(
      "",
      "## DOI {.appendix .doi-section}",
      "",
      paste0('<div class="csl-entry quarto-appendix-citeas doi-appendix-last">'),
      paste0("[", matching_doi, "](", matching_doi, ")"),
      "</div>"
    )
    full_content <- c(full_content, doi_section)
  }

  # Write the final content back to the output file
  if (!is.null(matching_doi) || file.exists(citation_file) || !is.null(matching_self_assessment)) {
    writeLines(full_content, output_file)

    message("Citation metadata updated and saved to ", output_file)
  }
}


# Enhanced function to check file/directory access and associated diagnostics
investigate_file_or_directory <- function(path) {

  logger::log_debug("\nStep 1: Checking ownership and permissions... {path}\n")
  # Check if the path exists
  if (!file.exists(path)) {
    stop("Path does not exist: ", path)
  }

  permissions <- system(paste("ls -ld", shQuote(path), "| awk '{print $1}'"), intern = TRUE)
  logger::log_debug(paste("permissions for", path, "are:",  permissions))

}





