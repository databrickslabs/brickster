dataContainer=setRefClass("dataContainer",
                               fields=list(
                                 clusters="data.frame"
                                 )
                             )



dataContainer$methods(
  initialise=function(){
    .self$lastTimestamp=as.numeric(Sys.time())
    .self$clusters=NULL
  },

  getData=function(fldName){
    return(.self$field[fldName])
  }



)

#' Data Container for connection objects
#'
#' @field lastTimestamp POSIXct.
#'
#' @return
# @export
#'
#' @examples
data_container=dataContainer$new()

