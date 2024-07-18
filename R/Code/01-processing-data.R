# Processing - R - IMF

# Part 1: Load data ----

#Set path of our data using here
ALB_ES_2017_raw <- read_dta(paste0(data_path, "/Raw/ALB_ES_2017.dta"))

# Part 2: Ensure propoer ID variable ----

# Check for duplicates
duplicates <- ALB_ES_2017_raw %>% 
  count(id, sort = TRUE) %>% 
  filter(n > 1)

# there are two duplicates and the only difference is unique_key 
ALB_ES_2017_raw %>% 
  filter(id %in% duplicates$id) 
  
  ALB_ES_2017_cleaned <- ALB_ES_2017_raw %>% 
    # remove this variable as the id is unique we don't need it. 
    select(-unique_key) %>% 
    # remove duplicates
    distinct() 

# Part 3a: Make sure data is stored in correct format and have labels ----
  
  ALB_ES_2017_cleaned <- ALB_ES_2017_cleaned %>%
    # Rename 'Region' to 'region_str'
    rename(region_str = Region) %>%
    # Convert 'region_str' to a factor with predefined levels and labels
    mutate(region = factor(region_str, levels = c("North", "Central", "South"), labels = c("1", "2", "3"))) %>%
    # Convert numbers stored as strings to numeric
    mutate(across(c(County_code, Municipality_code, m1_02), ~as.numeric(as.character(.)))) %>%
    # Drop the original 'region_str' column
    select(-region_str) %>%
    # Move `region` to be the first column
    select(region, everything())
  
# Part 3b: missing values ----
  
  # Assuming you've determined these variables already, recode -888 and -999 to NA and you want to bulk recode
    ALB_ES_2017_cleaned <- ALB_ES_2017_cleaned %>%
    mutate(across(where(is.numeric), ~na_if(.x, -888))) %>%
    mutate(across(where(is.numeric), ~na_if(.x, -999)))
  
# Part 4: Save data ----
  
  # Save the cleaned data
  write_dta(ALB_ES_2017_cleaned, path = paste0(data_path, "/Intermediate/firmdata_cleaned.dta"))
  
# Part 5: Importance of tidyness ----
  
  # a: working with untidy
  
  # Keep only relevant variables
  ALB_ES_2017_selected <- ALB_ES_2017_raw %>% 
    select(id, m2_05_t1, m2_05_t2, m2_10_t1, m2_10_t2)
  
  # Create dummies and calculate share
  ALB_ES_2017_untidy <- ALB_ES_2017_selected %>% 
    mutate(
    # Dummy for higher education
           edu_1 = as.numeric(m2_10_t1 %in% 4:7),
           edu_2 = as.numeric(m2_10_t2 %in% 4:7),
    # Dummy if hire exists   
           tot_1 = as.numeric(!is.na(m2_10_t1)),
           tot_2 = as.numeric(!is.na(m2_10_t2))) %>%
    # sum across rows
    rowwise() %>%
    mutate(
    edu = sum(edu_1, edu_2, na.rm = TRUE),
    tot = sum(tot_1, tot_2, na.rm = TRUE)
    ) %>% 
    ungroup()

  # Calculate the share of new hires with higher education
  edu_count <- sum(ALB_ES_2017_untidy$edu, na.rm = TRUE)
  tot_count <- sum(ALB_ES_2017_untidy$tot, na.rm = TRUE)
  share <- edu_count / tot_count
  
  print(paste("Share of new hires with higher education:", share))

   # b: working with tidy data 
  
  ALB_ES_2017_tidy <- ALB_ES_2017_selected  %>% 
    # reshape 
    pivot_longer(cols = starts_with("m2"), 
                 names_to = c(".value", "occupation_type"), 
                 names_pattern = "(m2_05|m2_10)_(t\\d)") %>%
    # filter different than 0
    filter(m2_05 != 0) %>%
    # Dummy for higher education
    mutate(edu = as.numeric(m2_10 %in% 4:7 & !is.na(m2_10)))
  
  # Calculate share
  share <- mean(ALB_ES_2017_tidy$edu, na.rm = TRUE)
  print(paste("Share of new hires with higher education:", share))

