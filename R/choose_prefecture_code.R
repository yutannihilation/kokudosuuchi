#' Choose Prefecture Codes Interactively
#'
#' Display a popup window with prefectures checkboxes, and return the codes of checked prefectures.
#'
#' @export
choose_prefecture_code <- function() {
  shiny::runApp(
    shiny::shinyApp(
      shiny::fluidPage(
        "Pref Code Chooser",
        shiny::checkboxGroupInput(
          inputId = "prefecture",
          label = "Check prefectures",
          choices = purrr::set_names(KSJPrefCodes$prefCode, KSJPrefCodes$prefName),
          inline = TRUE,
          width = '400px'
        ),
        shiny::actionButton("done", "Done")
      ),
      function(input, output) {
        shiny::observe({
          input$done
          if (input$done > 0)
            shiny::stopApp(shiny::isolate(input$prefecture))
        })
      }
    )
  )
}
