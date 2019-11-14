server <- function(input, output) {
  
  # mathematica logo
  output$logo <- renderUI({
    img(src='logo.png', aligh = 'right', height = '100px')
  })
  
#  county_selection_check <- reactive({
#    validate({
#      if (input$county_selection_type == "fips") {
#        need(nchar(input$county_selection) == 4, 'Please enter a four digit fips Code for your county.')
#      } else if (input$county_selection_type == "name") {
#        need(input$county_selection %in% dat$county, 'Please enter a valid county name.')
#      }
#    })
#  })
#  
#  output$county_selection_message <- renderText({
#    county_selection_check
#  })
  
  options(DT.options = list(dom = "t", ordering = F))

  # error handling checks ------------------------------------------------------
  county_check <- reactive({
    if (input$county_selection_type == "fips") {
      input$county_selection %in% dat$fips
    } else if (input$county_selection_type == "name") {
      input$county_selection %in% dat$county
    }
  })
  
  # reactive values and data frames --------------------------------------------
  county_fips <- reactive({
    req(county_check())
    if (input$county_selection_type == "fips") {
      input$county_selection
    } else if (input$county_selection_type == "name") {
      dat %>% filter(county == input$county_selection) %>% pull(fips)
    }
  })
  
  county_name <- reactive({
    req(county_check())
    if (input$county_selection_type == "name") {
      input$county_selection
    } else if (input$county_selection_type == "fips") {
      dat %>% filter(fips == input$county_selection) %>% pull(county)
    }
  })
  
  county_dat <- reactive({
    dat %>% filter(fips == county_fips())
  })
  
  comp_county_dat <- reactive({
    req(county_check())
    req(input$comparison_county_selection)
    dat %>% filter(county == input$comparison_county_selection)
  })
  
  # creates list of matched counties
  my_matches <- reactive({
    req(county_check())
    find_my_matches(county_fips(), dat, 20)[[2]] 
  })
  

  
  # outcomes data
  outcomes_dat <- reactive({
    req(county_check())
    
    outcomes_dd <- get_dd(dd, "outcome")
    
    outcomes <- outcomes_dd %>% pull(column_name)
    
    # need to add coloring to the vlines
    df <- dat %>% select(fips, state, county, outcomes) %>%
      pivot_longer(cols = outcomes) %>%
      # selected county and matches to selected county
      mutate(type = case_when(
        fips %in% my_matches() ~ "matches",
        fips == county_fips() ~ "selected",
        TRUE ~ "other"
      )) %>%
      # left join data dictionary to get real outcome names
      rename(column_name = name) %>%
      left_join(outcomes_dd, by = "column_name") 
    df
  })
  
  # output ---------------------------------------------------------------------
  ## selected county information -----------------------------------------------
  output$my_county_name <- renderUI({
    req(county_check())
    HTML(paste0("<h3>My Selection<br/></h3>", "<h4>", county_name(), ", ", county_dat()$state, "</h4>"))
  })
  
  
  output$my_county_radar <- renderPlotly({
    req(county_check())
    req(input$comparison_county_selection)
    
    sdoh_dd <- get_dd(dd, "sdoh_score")
    
    sdohs <- sdoh_dd %>% pull(column_name)
    
    my_county_df <- county_dat() %>% select(county, state, sdohs)
    
    if (input$comparison_county_selection == "None") {
      radar_chart(my_county_df, dd)
    } else {
      comp_county_df <- comp_county_dat() %>% select(county, state, sdohs)
      
      radar_chart_overlay(my_county_df, comp_county_df, dd)
    }
  })
  
  output$my_county_demo <- DT::renderDT({
    req(county_check())
    req(input$comparison_county_selection)
    df <- get_table_data(county_dat(), dd, "demographic") 
    
    if (input$comparison_county_selection != "None") {
      comp_df <- get_table_data(comp_county_dat(), dd, "demographic")
      df <- left_join(df, comp_df, by = "name")
    }
    
    df <- df %>%
      rename(`Essential facts` = name)
    
    DT::datatable(df, rownames = FALSE, class = "stripe") %>%
      DT::formatStyle(columns = colnames(df), fontSize = "9pt")
  })
  
  output$my_county_econ_stab <- DT::renderDT({
    req(county_check())
    req(input$comparison_county_selection)
    df <- get_table_data(county_dat(), dd, "used_sdoh_1") 
    
    if (input$comparison_county_selection != "None") {
      comp_df <- get_table_data(comp_county_dat(), dd, "used_sdoh_1")
      df <- left_join(df, comp_df, by = "name")
    }
    
    df <- df %>%
      rename(`Economic Stability` = name)
    
    DT::datatable(df, rownames = FALSE, class = "stripe") %>%
      DT::formatStyle(columns = colnames(df), fontSize = "9pt")
  })
  
  output$my_county_neigh <- DT::renderDT({
    req(county_check())
    req(input$comparison_county_selection)
    df <- get_table_data(county_dat(), dd, "used_sdoh_2") 
    
    if (input$comparison_county_selection != "None") {
      comp_df <- get_table_data(comp_county_dat(), dd, "used_sdoh_2")
      df <- left_join(df, comp_df, by = "name")
    }
    
    df <- df %>%
      rename(`Neighborhood & Physical Environment` = name)
    
    DT::datatable(df, rownames = FALSE, class = "stripe") %>%
      DT::formatStyle(columns = colnames(df), fontSize = "9pt")
  })
  
  output$my_county_edu <- DT::renderDT({
    req(county_check())
    req(input$comparison_county_selection)
    df <- get_table_data(county_dat(), dd, "used_sdoh_3") 
    
    if (input$comparison_county_selection != "None") {
      comp_df <- get_table_data(comp_county_dat(), dd, "used_sdoh_3")
      df <- left_join(df, comp_df, by = "name")
    }
    
    df <- df %>%
      rename(`Education` = name)
    
    DT::datatable(df, rownames = FALSE, class = "stripe") %>%
      DT::formatStyle(columns = colnames(df), fontSize = "9pt")
  })
  
  output$my_county_food <- DT::renderDT({
    req(county_check())
    req(input$comparison_county_selection)
    df <- get_table_data(county_dat(), dd, "used_sdoh_4") 
    
    if (input$comparison_county_selection != "None") {
      comp_df <- get_table_data(comp_county_dat(), dd, "used_sdoh_4")
      df <- left_join(df, comp_df, by = "name")
    }
    
    df <- df %>%
      rename(`Food` = name)
    
    DT::datatable(df, rownames = FALSE, class = "stripe") %>%
      DT::formatStyle(columns = colnames(df), fontSize = "9pt")
  })
  
  output$my_county_community <- DT::renderDT({
    req(county_check())
    req(input$comparison_county_selection)
    df <- get_table_data(county_dat(), dd, "used_sdoh_5") 
    
    if (input$comparison_county_selection != "None") {
      comp_df <- get_table_data(comp_county_dat(), dd, "used_sdoh_5")
      df <- left_join(df, comp_df, by = "name")
    }
    
    df <- df %>%
      rename(`Community` = name)
    
    DT::datatable(df, rownames = FALSE, class = "stripe") %>%
      DT::formatStyle(columns = colnames(df), fontSize = "9pt")
  })
  
  output$my_county_health <- DT::renderDT({
    req(county_check())
    req(input$comparison_county_selection)
    df <- get_table_data(county_dat(), dd, "used_sdoh_6") 
    
    if (input$comparison_county_selection != "None") {
      comp_df <- get_table_data(comp_county_dat(), dd, "used_sdoh_6")
      df <- left_join(df, comp_df, by = "name")
    }
    
    df <- df %>%
      rename(`Health Coverage` = name)
    
    DT::datatable(df, rownames = FALSE, class = "stripe") %>%
      DT::formatStyle(columns = colnames(df), fontSize = "9pt")
  })
  
  
  ## selected comparison county info -------------------------------------------
  output$select_comparison_county <- renderUI({
    req(my_matches())
    comp_counties <- dat %>% filter(fips %in% my_matches()) %>% pull(county)
    selectInput('comparison_county_selection', label = "Select a county to compare:",
                choices = c("None", comp_counties), selected = "None")
  })

  
  output$comp_county_demo <- DT::renderDT({
    req(comp_county_dat())

    # duplicated descriptions for different variables. the .copy column will be dropped once those duplicates are removed
    df <- get_table_data(comp_county_dat(), dd, "demographic") 
    
    DT::datatable(df, rownames = FALSE, colnames = c("Essential facts", ""), class = "stripe") %>%
      DT::formatStyle(columns = colnames(df), fontSize = "9pt")
  })
  
  output$comp_county_econ_stab <- DT::renderDT({
    req(comp_county_dat())
    # duplicated descriptions for different variables. the .copy column will be dropped once those duplicates are removed
    df <- get_table_data(comp_county_dat(), dd, "used_sdoh_1") 
    
    DT::datatable(df, rownames = FALSE, colnames = c("Economic Stability", ""), class = "stripe") %>%
      DT::formatStyle(columns = colnames(df), fontSize = "9pt")
  })
  
  output$comp_county_neigh <- DT::renderDT({
    req(comp_county_dat())
    # duplicated descriptions for different variables. the .copy column will be dropped once those duplicates are removed
    df <- get_table_data(comp_county_dat(), dd, "used_sdoh_2") 
    
    DT::datatable(df, rownames = FALSE, colnames = c("Neighborhood & Physical Environment", ""), class = "stripe") %>%
      DT::formatStyle(columns = colnames(df), fontSize = "9pt")
  })
  
  output$comp_county_edu <- DT::renderDT({
    req(comp_county_dat())
    # duplicated descriptions for different variables. the .copy column will be dropped once those duplicates are removed
    df <- get_table_data(comp_county_dat(), dd, "used_sdoh_3") 
    
    DT::datatable(df, rownames = FALSE, colnames = c("Education", ""), class = "stripe") %>%
      DT::formatStyle(columns = colnames(df), fontSize = "9pt")
  })
  
  output$comp_county_food <- DT::renderDT({
    req(comp_county_dat())
    # duplicated descriptions for different variables. the .copy column will be dropped once those duplicates are removed
    df <- get_table_data(comp_county_dat(), dd, "used_sdoh_4") 
    
    DT::datatable(df, rownames = FALSE, colnames = c("Food", ""), class = "stripe") %>%
      DT::formatStyle(columns = colnames(df), fontSize = "9pt")
  })
  
  output$comp_county_community <- DT::renderDT({
    req(comp_county_dat())
    # duplicated descriptions for different variables. the .copy column will be dropped once those duplicates are removed
    df <- get_table_data(comp_county_dat(), dd, "used_sdoh_5") 
    
    DT::datatable(df, rownames = FALSE, colnames = c("Community", ""), class = "stripe") %>%
      DT::formatStyle(columns = colnames(df), fontSize = "9pt")
  })
  
  output$comp_county_health <- DT::renderDT({
    req(comp_county_dat())
    # duplicated descriptions for different variables. the .copy column will be dropped once those duplicates are removed
    df <- get_table_data(comp_county_dat(), dd, "used_sdoh_6") 
    
    DT::datatable(df, rownames = FALSE, colnames = c("Health Coverage", ""), class = "stripe") %>%
      DT::formatStyle(columns = colnames(df), fontSize = "9pt")
  })
  ## comparison counties info --------------------------------------------------
  output$my_matches_header <- renderUI({
    req(my_matches())
    tagList(
      HTML(paste0("<h3>My Matches<br/></h3><h4>", length(my_matches()), " communities</h4>"))
    )
  })
  
  output$compare_county_radars <- renderPlotly({
    req(county_check())
    
    sdoh_dd <- get_dd(dd, "sdoh_score")
    
    sdohs <- sdoh_dd %>% pull(column_name)
    
    df <- dat %>% select(fips, state, county, sdohs) %>%
      filter(fips %in% my_matches())
    
    grid_radar(df, dd)
  })
  
  output$map_header <- renderUI({
    req(my_matches())
    tagList(
      HTML(paste0("<h3>County Map<br/></h3>"))
    )
  })
  
  output$map <- renderPlotly({
    req(county_check())
    
    st <- dat %>% pull(state) %>% unique()
    state <- state.name[match(st, state.abb)]
    
    df <- find_my_matches(county_fips(), dat, 20)[[1]] %>%
      mutate(county = gsub(" county", "", tolower(county)))
    
    county_map_df <- map_data("county") %>%
      filter(region == tolower(state))
    
    df <- full_join(df, county_map_df, by = c("county" = "subregion"))
    
    df %>%
      group_by(group) %>%
      plot_ly(x = ~long, y = ~lat, color = ~fct_explicit_na(fct_rev(factor(distance))),
              colors = viridis_pal(option="D")(3),
              text = ~county, hoverinfo = 'text') %>%
      add_polygons(line = list(width = 0.4)) %>%
      add_polygons(
        fillcolor = 'transparent',
        line = list(color = 'black', width = 0.5),
        showlegend = FALSE, hoverinfo = 'none'
      ) %>%
      layout(
        xaxis = list(title = "", showgrid = FALSE,
                     zeroline = FALSE, showticklabels = FALSE),
        yaxis = list(title = "", showgrid = FALSE,
                     zeroline = FALSE, showticklabels = FALSE),
        showlegend = FALSE
      )
                     
  })
  
  # dynamic number of density graphs -------------------------------------------
  output$health_outcomes_header <- renderUI({
    req(county_check())
    tagList(
      HTML(paste0("<h3>My Health Outcomes<br/></h3>")),
      selectInput('outcome_sort', label = 'Sort outcomes by', 
                  choices = c('most exceptional' = 'exceptional', 
                              'best' = 'best', 'worst' = 'worst'),
                  selected = 'exceptional')
    )
  })
  
  density_graphs <- eventReactive(input$outcome_sort, {
    req(outcomes_dat())
    
    outcomes_dat() %>%
      group_by(column_name, higher_better) %>%
      nest() %>%
      mutate(rank = unlist(purrr::map2(data, higher_better, rank_outcome))) %>%
      # arrange by rank
      arrange_rank(input$outcome_sort) %>%
      mutate(graphs = purrr::map(data, make_density_graph)) %>%
      pull(graphs)
  })
  
  observeEvent(input$outcome_sort, {
    req(density_graphs())
    
    purrr::iwalk(density_graphs(), ~{
      output_name <- paste0("density_graph", .y)
      output[[output_name]] <- renderPlot(.x)
    })
  })
  
  output$density_graphs_ui <- renderUI({
    req(county_check())
    req(density_graphs())
    
    density_plots_list <- purrr::imap(density_graphs(), ~{
      tagList(
        plotOutput(
          outputId = paste0("density_graph", .y)
        ),
        br()
      )
    })
    tagList(density_plots_list)
  })
  
  
 }