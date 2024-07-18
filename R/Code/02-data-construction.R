# Construction - R - IMF

# Part 1: Load data ----

#Set path of our data using here

ALB_ES_cleaned <- read_dta(paste0(data_path,"/Intermediate/firmdata_cleaned.dta"))

# Task 1 ------

# Construction Plan Summary:
#   
# Objective: To measure the representation and perception of women 
# in the workplace, alongside firm performance metrics.
# 
# Data Set Creation: A single, comprehensive dataset will be used for analysis.
# 
# Unit of Observation: The unit of observation is the firm, identified by the id (Firm Number).
# 
# Needed variables 
# Location: Region, County_code, Municipality_code
# Firm details: id
# Education: m2_05_t1 m2_05_t2 m2_10_t1 m2_10_t2
# Hiring opinions: m4_20_1 to m4_20_5}
# Financials (2016): m5_12_y2, m5_13_y2, m5_14_y2}

# Task 2 ------

# Standardize financial variables 
# tip:  pivot first

# define exchange rate
exchange_rate <- 110.95

ALB_ES_financial <- ALB_ES_cleaned %>%
  select(id, m5_12_y1, m5_13_y1, m5_14_y1, 
         m5_12_y2, m5_13_y2, m5_14_y2) %>% 
  pivot_longer(cols = starts_with("m5_"), 
               names_to = c(".value", "year"), 
               names_pattern = "^(m5_\\d+)_(y\\d)$") %>% 
  # standardize 
  mutate_at(vars("m5_12", "m5_13", "m5_14"),~./exchange_rate) %>% 
  # create profits 
  mutate(profits_usd = m5_14 - (m5_12 + m5_13)) %>% 
  group_by(id) %>% 
  summarise(profits_usd = sum(profits_usd, na.rm = TRUE))

# Note: In the names_pattern, the ^(m5_\\d+)_ captures the 
#variable part (e.g., m5_12), and (y\\d)$ captures the year suffix (e.g., y1).

# Task 3 -----

# Outliers and winsorize financial variables 

# winsorize function

# Plot boxplots to visually identify outliers
ggplot(ALB_ES_financial, aes(y = profits_usd)) +
  geom_boxplot() 

# Define the function
winsor_function <- function(dataset, var, min = 0.00, max = 0.99){
  var_sym <- sym(var)
  
  percentiles <- quantile(
    dataset %>% pull(!!var_sym), probs = c(min, max), na.rm = TRUE
  )
  
  min_percentile <- percentiles[1]
  max_percentile <- percentiles[2]
  
  dataset %>%
    mutate(
      !!paste0(var, "_w") := case_when(
        is.na(!!var_sym) ~ NA_real_,
        !!var_sym <= min_percentile ~ percentiles[1],
        !!var_sym >= max_percentile ~ percentiles[2],
        TRUE ~ !!var_sym
      )
    )
}

ALB_ES_financial <- winsor_function(ALB_ES_financial, "profits_usd", min = 0.01, max = 0.99)

# plot histograms 

hist(ALB_ES_financial$profits_usd, main="Before Winsorization", xlab="Variable Value")
hist(ALB_ES_financial$profits_usd_w, main="After Winsorization", xlab="Variable Value")

# same ggplot as before 

ggplot(ALB_ES_financial, aes(y = profits_usd_w)) +
  geom_boxplot() 

# Task 4 ----
# Create indicators

ALB_ES_female <- ALB_ES_cleaned %>% 
  # construct share of women workers
  mutate(women_workers = m1_06/m1_04) %>% 
  # Dummy variable if proportion of women managers is more than half
  mutate(women_managers = case_when(m1_13_e1 == 3 | m1_13_e1 == 2 ~ 1, 
                             m1_13_e1 == 1 ~ 0, # Otherwise 0
                             is.na(m1_13_e1) ~ NA)) %>% 
  distinct() %>% 
  select(region:id, women_workers, women_managers)

  # create education variables 
  
  # education variables
  ALB_ES_education <- ALB_ES_cleaned %>% 
    select(id, m2_05_t1, m2_05_t2, m2_10_t1, m2_10_t2) %>% 
    pivot_longer(cols = starts_with("m2"), 
                 names_to = c(".value", "occupation_type"), 
                 names_pattern = "(m2_05|m2_10)_(t\\d)") %>%
    # filter different than 0
    filter(m2_05 != 0) %>%
    # Dummy for higher education
    mutate(edu_high = as.numeric(m2_10 %in% 5:7 & !is.na(m2_10) & m2_05 !=0)) %>% 
    group_by(id) %>% 
    # keep 1 if one of the occupations has the dummy for higher education
    summarise(edu_high = max(edu_high))
  
  # join dataset
  ALB_ES_construction <- ALB_ES_female %>% 
    left_join(ALB_ES_education) %>% 
    left_join(ALB_ES_financial)
  
  # Task 5 ----- 
  # Save dataset 
  write_dta(ALB_ES_construction, path = paste0(data_path, "/Final/firmdata_constructed.dta"))

# Appendix ------
# Build checks 

# Check that all expected regions are present
expected_regions <- unique(ALB_ES_cleaned$region)
assert_that(setequal(unique(ALB_ES_construction$region), expected_regions))

# Check that there is no negative in women_workers 

# Ensure there are no negative values in 'women_workers'
assert_that(all(ALB_ES_construction$women_workers >= 0 | is.na(ALB_ES_construction$women_workers)))

