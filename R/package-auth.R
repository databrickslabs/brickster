# internal package functions for authentication

#' Generate/Fetch Databricks Host
#'
#' @description
#' If both `id` and `prefix` are `NULL` function will search for the
#' `DATABRICKS_HOST` environment variable.
#'
#' When defining `id` and `prefix` you do not need to specify the whole URL.
#' E.g. `https://<prefix>.<id>.cloud.databricks.com/` is the form to follow.
#'
#' @param id The workspace string
#' @param prefix workspace prefix
#'
#' @family Databricks Authentication Helpers
#'
#' @return workspace URL
#' @export
db_host <- function(id = NULL, prefix = NULL,env=getOption("db_env")) {
  if (is.null(id) && is.null(prefix)) {
    #host <- Sys.getenv("DATABRICKS_HOST")
    host=db_get_param('dbHost',env)

    if (host == "") {
      stop(format_error(c(
        "`DATABRICKS_HOST` not found in `.Renviron`:",
        "x" = "Need to specify `DATABRICKS_HOST` within `.Renviron` file."
      )))
    }
  } else {
    host <- paste0("https://", prefix, id, ".cloud.databricks.com")
  }

  host
}

#' Fetch Databricks Token
#'
#' @description
#' Token must be specified as an environment variable `DATABRICKS_TOKEN`.
#'
#' Refer to [api authentication docs](https://docs.databricks.com/dev-tools/api/latest/authentication.html)
#'
#' @family Databricks Authentication Helpers
#'
#' @return databricks token
#' @import cli
#' @export
db_token <- function(env=getOption("db_env")) {
  #token <- Sys.getenv("DATABRICKS_TOKEN")
  token=db_get_param('dbToken',env)
  if (token == "") {
    stop(cli::format_error(c(
      "`DATABRICKS_TOKEN` not found in `.Renviron`:",
      "x" = "Need to specify `DATABRICKS_TOKEN` within `.Renviron` file."
    )))
  }

  token
}

#' Fetch Databricks Workspace ID
#'
#' @description
#' Workspace ID, optionally specificied to make connections pane more powerful.
#' Specified as an environment variable `DATABRICKS_WSID`.
#'
#' Refer to [api authentication docs](https://docs.databricks.com/dev-tools/api/latest/authentication.html)
#'
#' @family Databricks Authentication Helpers
#'
#' @return databricks workspace ID
#' @import cli
#' @export
db_wsid <- function(env=getOption("db_env")) {
  #token <- Sys.getenv("DATABRICKS_WSID")
  wsid=db_get_param('dbWsId',env)

  if (wsid == "") {
    stop(cli::format_error(c(
      "`DATABRICKS_WSID` not found in `.Renviron`:",
      "x" = "Need to specify `DATABRICKS_WSID` within `.Renviron` file."
    )))
  }

  wsid
}


#' Read .netrc File
#'
#' @param path path of `.netrc` file, default is `~/.netrc`.
#'
#' @family Databricks Authentication Helpers
#'
#' @return named list of `.netrc` entries
#' @export
db_read_netrc <- function(path = "~/.netrc") {
  # nocov start
  params <- readLines(path, warn = FALSE)
  params <- lapply(strsplit(params, " "), `[`, 2)
  setNames(params, c("machine", "login", "password"))
  # nocov end
}

#' @name auth_params
#' @param host Databricks workspace URL, defaults to calling [db_host()].
#' @param token Databricks workspace token, defaults to calling [db_token()].
#'
NULL



#' Parses .databrickscfg file for parameters related to brickster
#' Uses db_env variable that is set with options(db_env,...)
#' @param lParm name of the parameter to extract from cfg file. Default value is DB workspace ID (dbWsId)
#'
#' @return
#' @export
#'
#' @examples
db_get_param=function(lParm='dbWsId',lEnv=NULL){
  # browser()
  if(is.null(getOption("use_databrickscfg"))){
    #Read .Renviron
    parms=list(dbWsId="DATABRICKS_WSID",
               dbToken="DATABRICKS_TOKEN",
               dbHost="DATABRICKS_HOST")


    lVar=paste0(parms[lParm],ifelse(is.null(lEnv),"",paste0("_",stringr::str_to_upper(lEnv))))

    lVal=Sys.getenv(lVar)
    if(lVal=="") {
      stop(cli::format_error(c(
        paste0("Parameter {.var ",lVar,"} does not exist in {.var .Renviron} file:"),
        "x" = paste0("Need to specify {.var ",lVar,"} within {.var .Renviron} file.")
      )))
    }



  }else{
    # Read .databrickscfg


    lHome=ifelse(Sys.info()[[1]]=="Windows",Sys.getenv("USERPROFILE"),Sys.getenv("HOME"))
    con=base::file(file.path(lHome,".databrickscfg"),"r",blocking=F)
    fileLines=base::readLines(con)
    close(con)
    fileLines=fileLines[stringr::str_trim(fileLines)!=""]

    parms=list(dbWsId="DATABRICKS_WSID",
               dbToken="token",
               dbHost="host")
    lDbEnv=ifelse(is.null(lEnv),"DEFAULT",lEnv)
    # lParm='DATABRICKS_HOST'

    sections=c(base::which(stringr::str_detect(fileLines,'^\\[.{1,}\\]$')),base::length(fileLines))
    envLine=base::which(stringr::str_detect(fileLines[sections],lDbEnv))
    if (purrr::is_empty(envLine)) {
      stop(cli::format_error(c(
        paste0("{.var ",lDbEnv,"} profile not found in `.databrickscfg`:"),
        "x" = paste0("Need to specify {.var ",lDbEnv,"} profile within `.databrickscfg` file.")
      )))
    }

    lLines=fileLines[(sections[envLine]):(sections[envLine+1])]
    prmLine=lLines[which(stringr::str_detect(lLines,parms[[lParm]]))]
    if (purrr::is_empty(prmLine)) {
      stop(cli::format_error(c(
        paste0("Parameter {.var ",parms[lParm],"} does not exist in {.var ",lDbEnv,"} workspace section of `.databrickscfg` file:"),
        "x" = paste0("Need to specify {.var ",parms[lParm],"} within {.var ",lDbEnv,"} workspace section.")
      )))
    }

    lVal=stringr::str_trim((base::strsplit(prmLine,"=")[[1]])[2])
  }
  lVal
}

