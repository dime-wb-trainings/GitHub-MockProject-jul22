# Analysis - R 

#  Load data ----

#Set path of our data using here

ALB_ES_constructed <- read_dta(paste0(data_path,"/Final/firmdata_constructed.dta"))

# Part 1: Summary Statistics ----


# use datasummary_skim to create summary for every variable
summary_stats <- datasummary_skim(ALB_ES_constructed%>% 
                                    select(-c(region, County_code, Municipality_code, id)), 
                               output = "huxtable")

# save to excel 
quick_xlsx(
  summary_stats,
  file = here(
    "Outputs",
    "Tables",
    "summary-stats-1.xlsx"
  )
)

# if we only want those indicators and save it to excel we can use datasummary
# but if we want to create a summary by region we have to make more customazation

# Define the variables you want to summarize
sum_vars <- c("profits_usd_w", "edu_high", "women_workers")

# Calculate summary statistics by region
# Summary statistics by region, output to Excel
ALB_ES_constructed %>%
  group_by(region) %>%
  summarise(across(all_of(sum_vars), list(mean = mean, median = median, sd = sd, min = min, max = max, n = ~sum(!is.na(.))))) %>%
  writexl::write_xlsx(path = here(
    "Outputs",
    "Tables",
    "summary-stats-2.xlsx"
  ))

# Part 2: Balance tables ----

# Balance tables for women managers
datasummary_balance(~women_managers, 
                    data = ALB_ES_constructed %>% 
                      # This mutate is not needed but serves to add the label to the dummy variable, as this 
                      # not always work with labels read from stata
                      mutate(women_managers = factor(women_managers, 
                                                     levels = c(0, 1), 
                                                     labels = c("Less than half", "More than half"))) %>% 
                      select(-c(region, County_code, Municipality_code, id))) 
  
 
  

# Part 3: Regressions ----

# Regression 1: Total profits on college education
reg1 <- lm(profits_usd_w ~ edu_high, data = ALB_ES_constructed )

# Regression 2: controlling for women_managers
reg2 <- lm(profits_usd_w ~ edu_high + women_managers, data = ALB_ES_constructed )

# Regression 3: controlling for women_managers + clustering by Municipality
reg3 <- feols(profits_usd_w ~ edu_high + women_managers | Municipality_code, 
           data = ALB_ES_constructed, 
           se = "iid")

# Exporting regression
reg_table <- huxreg(reg1, reg2, reg3, 
       coefs = c(
         "Higher education" = "edu_high", 
         "Women managers" = "women_managers")) %>%
  add_rows(
    c("Region FE", "No", "No","Yes"),
    after = 5
  )

# Export to Excel
quick_xlsx(reg_table,  file = here(
   "Outputs",
   "Tables",
  "regression-1.xlsx"))

# Graphs
# Total Profits over region with basic horizontal bar graph
ggplot(ALB_ES_constructed, 
       aes(x = factor(region), y = profits_usd_w)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(y = "Average profits (USD)", x = "Region") +
  theme_minimal()

# Profits by 1000s for better scaling

ALB_ES_constructed <- ALB_ES_constructed %>% 
  mutate(profits_t_usd_w = profits_usd_w/1000) %>% 
  # filter profits more than 0 and women_managers not NA 
  filter(profits_t_usd_w>=0 & !is.na(women_managers)) 

# Enhanced bar graph with profits in thousands
profits_region_manager <- ggplot(ALB_ES_constructed %>% 
                                   mutate(women_managers = factor(women_managers, 
                                                                  levels = c(0, 1), 
                                                                  labels = c("Less than half", "More than half")), 
                                           region = factor(region, levels = c("1", "2", "3"),  
                                                           labels = c("North", "Central", "South"))), 
       aes(x = factor(region), y = profits_t_usd_w)) +
  geom_bar(stat = "identity", fill = "lightblue") +
  coord_flip() +
  facet_wrap(~factor(women_managers)) +
  labs(y = "Average profits (1000s USD)", x = "Region") +
  theme_minimal() +
  # adding commans in USDs
  scale_y_continuous(label=comma) +
  # add title
  labs(title = "Profits by proportion of women managers", 
       caption = "Note: Graphs by More than half women managers")


# Two-way kernel density of women workers by women managers
two_way_kernel <- ggplot(ALB_ES_constructed, aes(x = women_workers, fill = factor(women_managers))) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(values = c("blue", "red"), 
                    labels = c("Less than half women managers", "More than half women managers")) +
  labs(title = "Distribution of women workers by proportion of women managers", y = "Density", x = "Share of women workers") +
  theme_minimal() +
  theme(panel.background = element_blank(), plot.background = element_rect(fill = "white"), 
        legend.title=element_blank()) +
  scale_x_continuous(label=percent) 

combined_figure <- ggarrange(profits_region_manager, two_way_kernel,
                    labels = c("A", "B"), 
                    ncol = 1, nrow = 2)

# save plot
ggsave("Figure1.jpg", plot = combined_figure, path = here("Outputs", "Figures"))

