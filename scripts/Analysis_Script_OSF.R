library(tidyverse)
library(stats)
library(ggplot2)
library(ggrepel)
library(psych)
library(haven)

#####Part 0: Replicate the Inglehart-Welzel World Cultural Map#####
###Load WVS and EVS Data###
#Source: https://www.worldvaluessurvey.org/WVSEVStrend.jsp
wvs_timeseries_data = readRDS("New Analysis on TimeSeries Data/WVS_trends_3_0.rds")
length(unique(wvs_timeseries_data$s003)) #Note: 108 countries/territories from the WVS dataset
evs_timeseries_data = read_dta("ZA7503_v3-0-0.dta/ZA7503_v3-0-0.dta")
length(unique(evs_timeseries_data$S003)) #Note: 49 countries/territories from the EVS dataset


###Merge WVS and EVS Data###
wvs_data_for_fa = subset(wvs_timeseries_data, select = c(s002vs, s003, s017, s025, a008, a165, e018, e025, f063, f118, f120, g006, y002, y003)) #Select wave number, country id, weight, survey year, ten questions 
wvs_data_for_fa$a008 = ifelse(wvs_data_for_fa$a008 > 0, wvs_data_for_fa$a008, NA) #transfer the negative value to null
wvs_data_for_fa$a165 = ifelse(wvs_data_for_fa$a165 > 0, wvs_data_for_fa$a165, NA) #transfer the negative value to null
wvs_data_for_fa$e018 = ifelse(wvs_data_for_fa$e018 > 0, wvs_data_for_fa$e018, NA) #transfer the negative value to null
wvs_data_for_fa$e025 = ifelse(wvs_data_for_fa$e025 > 0, wvs_data_for_fa$e025, NA) #transfer the negative value to null
wvs_data_for_fa$f063 = ifelse(wvs_data_for_fa$f063 > 0, wvs_data_for_fa$f063, NA) #transfer the negative value to null
wvs_data_for_fa$f118 = ifelse(wvs_data_for_fa$f118 > 0, wvs_data_for_fa$f118, NA) #transfer the negative value to null
wvs_data_for_fa$f120 = ifelse(wvs_data_for_fa$f120 > 0, wvs_data_for_fa$f120, NA) #transfer the negative value to null
wvs_data_for_fa$g006 = ifelse(wvs_data_for_fa$g006 > 0, wvs_data_for_fa$g006, NA) #transfer the negative value to null
wvs_data_for_fa$y002 = ifelse(wvs_data_for_fa$y002 > 0, wvs_data_for_fa$y002, NA) #transfer the negative value to null
wvs_data_for_fa$y003 = ifelse(wvs_data_for_fa$y003 > -5, wvs_data_for_fa$y003, NA) #transfer the negative value to null

wvs_data_for_fa$source = "WVS"

evs_data_for_fa = subset(evs_timeseries_data, select = c(s002vs, S003, S017, S025, A008, A165, E018, E025, F063, F118, F120, G006, Y002, A040, A042, A029, A039)) #Select wave number, country id, weight, survey year, ten questions 
evs_data_for_fa$Y003 = if_else(evs_data_for_fa$A040 >= 0 & evs_data_for_fa$A042 >= 0 & evs_data_for_fa$A029 >=0 & evs_data_for_fa$A039 >= 0, (evs_data_for_fa$A029 + evs_data_for_fa$A039) - (evs_data_for_fa$A040 + evs_data_for_fa$A042), -5) #calculate the y003 autonomy index
evs_data_for_fa$A008 = ifelse(evs_data_for_fa$A008 > 0, evs_data_for_fa$A008, NA) #transfer the negative value to null
evs_data_for_fa$A165 = ifelse(evs_data_for_fa$A165 > 0, evs_data_for_fa$A165, NA) #transfer the negative value to null
evs_data_for_fa$E018 = ifelse(evs_data_for_fa$E018 > 0, evs_data_for_fa$E018, NA) #transfer the negative value to null
evs_data_for_fa$E025 = ifelse(evs_data_for_fa$E025 > 0, evs_data_for_fa$E025, NA) #transfer the negative value to null
evs_data_for_fa$F063 = ifelse(evs_data_for_fa$F063 > 0, evs_data_for_fa$F063, NA) #transfer the negative value to null
evs_data_for_fa$F118 = ifelse(evs_data_for_fa$F118 > 0, evs_data_for_fa$F118, NA) #transfer the negative value to null
evs_data_for_fa$F120 = ifelse(evs_data_for_fa$F120 > 0, evs_data_for_fa$F120, NA) #transfer the negative value to null
evs_data_for_fa$G006 = ifelse(evs_data_for_fa$G006 > 0, evs_data_for_fa$G006, NA) #transfer the negative value to null
evs_data_for_fa$Y002 = ifelse(evs_data_for_fa$Y002 > 0, evs_data_for_fa$Y002, NA) #transfer the negative value to null
evs_data_for_fa$Y003 = ifelse(evs_data_for_fa$Y003 > -5, evs_data_for_fa$Y003, NA) #transfer the negative value to null

evs_data_for_fa = subset(evs_data_for_fa, select = c(s002vs, S003, S017, S025, A008, A165, E018, E025, F063, F118, F120, G006, Y002, Y003))
colnames(evs_data_for_fa)[colnames(evs_data_for_fa) == "S003"] ="s003"
colnames(evs_data_for_fa)[colnames(evs_data_for_fa) == "S017"] ="s017"
colnames(evs_data_for_fa)[colnames(evs_data_for_fa) == "S025"] ="s025"
colnames(evs_data_for_fa)[colnames(evs_data_for_fa) == "A008"] ="a008"
colnames(evs_data_for_fa)[colnames(evs_data_for_fa) == "A165"] ="a165"
colnames(evs_data_for_fa)[colnames(evs_data_for_fa) == "E018"] ="e018"
colnames(evs_data_for_fa)[colnames(evs_data_for_fa) == "E025"] ="e025"
colnames(evs_data_for_fa)[colnames(evs_data_for_fa) == "F063"] ="f063"
colnames(evs_data_for_fa)[colnames(evs_data_for_fa) == "F118"] ="f118"
colnames(evs_data_for_fa)[colnames(evs_data_for_fa) == "F120"] ="f120"
colnames(evs_data_for_fa)[colnames(evs_data_for_fa) == "G006"] ="g006"
colnames(evs_data_for_fa)[colnames(evs_data_for_fa) == "Y002"] ="y002"
colnames(evs_data_for_fa)[colnames(evs_data_for_fa) == "Y003"] ="y003"

evs_data_for_fa$source = "EVS"

evs_data_for_fa$s003 = as.numeric(evs_data_for_fa$s003)
evs_data_for_fa$s017 = as.numeric(evs_data_for_fa$s017)
evs_data_for_fa$s002vs = as.numeric(evs_data_for_fa$s002vs)
evs_data_for_fa$s025 = as.numeric(evs_data_for_fa$s025)

wvs_data_for_fa$s003 = as.numeric(wvs_data_for_fa$s003)
wvs_data_for_fa$s017 = as.numeric(wvs_data_for_fa$s017)
wvs_data_for_fa$s002vs = as.numeric(wvs_data_for_fa$s002vs)
wvs_data_for_fa$s025 = as.numeric(wvs_data_for_fa$s025)

joint_data_for_fa = bind_rows(wvs_data_for_fa, evs_data_for_fa) #merge the wvs and evs data sets


###Filter data of the latest three waves###
joint_data_for_fa = joint_data_for_fa %>%
  filter(s002vs >= 5) #focus on the latest three waves
length(unique(joint_data_for_fa$s003)) #112 countries/territories in total


###Principal components analysis###
analysis = principal(joint_data_for_fa[,5:14], nfactors = 2, rotate = "varimax", use="pairwise", weight = as.numeric(joint_data_for_fa$s017))
fa.diagram(analysis)
print(analysis$loadings, cutoff=0, digits=3)
print(analysis)

joint_data_for_fa$RC1 = 1.81 * analysis$scores[, 1] + 0.38 #rescale PC scores following IVS guideline 
joint_data_for_fa$RC2 = 1.61 * analysis$scores[, 2] - 0.01 #rescale PC scores following IVS guideline 

pca_result_country_level = joint_data_for_fa %>%
  group_by(s003, s025) %>%
  filter(!is.na(RC1) & !is.na(RC2)) %>%
  summarise(RC1_mean = mean(RC1),
            RC2_mean = mean(RC2)) %>% #calculate the mean PC scores for each country/territory in each survey year
  group_by(s003) %>%
  summarise(RC1_final = mean(RC1_mean),
            RC2_final = mean(RC2_mean)) #calculate the mean PC scores for each country/territory

country_code = read.csv("s003.csv") #get the country/territory names
pca_result_country_level = left_join(pca_result_country_level, country_code, by = c('s003' = 's003'))

plot1 = ggplot(pca_result_country_level, aes(x = RC1_final, y = RC2_final, label = country.territory, color = Category)) +
  geom_point() +
  scale_color_manual(values = c("#000000", "#E69F00", "#56B4E9", "#009E73",
                                "#CC79A7", "#0072B2", "#D55E00", "#F0E442")) +
  geom_text_repel(aes(label = country.territory), box.padding = unit(0.25, "lines"), max.overlaps = 7) +
  theme_classic() +
  theme(
    axis.line.x = element_line(color = "grey"),  
    axis.line.y = element_line(color = "grey")
  ) + 
  scale_x_continuous(breaks = c(-2.50, -2.00, -1.50, -1.00, -0.50, 0.00, 0.50, 1.00, 1.50, 2.00, 2.50, 3.00, 3.50)) +
  scale_y_continuous(breaks = c(-2.50, -2.00, -1.50, -1.00, -0.50, 0.00, 0.50, 1.00, 1.50, 2.00)) +
  labs(x = "Survival vs. Self-Expression Values", y = "Traditional vs. Secular Values")
# ggtitle("Replication of Inglehart-Welzel World Cultural Map")
plot1



#####Part 1: Test GPT's General Cultural Expressions#####
#Create an empty data frame "model" to store the xy-coordinate of each GPT model's default cultural expression
model = c('GPT-3.5-turbo', 'GPT-4', 'GPT-4-turbo', 'GPT-4o')
RC1 = c(0,0,0,0)
RC2 = c(0,0,0,0)
country.territory = c('general', 'general',  'general', 'general')
general_gpt = data.frame(model, RC1, RC2)

###GPT-3.5-turbo-0613###
file.choose()
general_gpt_3.5_turbo = read.csv("S1_WideTable_Part1_scores_gpt-3.5-turbo-0613.csv") #The csv file can be found in the "Analysis_Part1_Default_Cultural_Values" folder of the OSF project

general_coordinate_gpt_3.5_turbo = predict.psych(analysis, general_gpt_3.5_turbo[,3:12], joint_data_for_fa[,5:14]) #Get PCA scores for every country/territory's GPT answers
general_coordinate_gpt_3.5_turbo = as.data.frame(general_coordinate_gpt_3.5_turbo)

general_coordinate_gpt_3.5_turbo$RC1 = 1.81 * general_coordinate_gpt_3.5_turbo$RC1 + 0.38 #rescale RC1 following WVS's procedure
general_coordinate_gpt_3.5_turbo$RC2 = 1.61 * general_coordinate_gpt_3.5_turbo$RC2 - 0.01 #rescale RC2 following WVS's procedure

general_gpt$RC1[general_gpt$model == 'GPT-3.5-turbo'] = mean(general_coordinate_gpt_3.5_turbo$RC1) #calculate the mean of RC1 across all the prompt variants as the x-coordinate of GPT-3.5 Turbo's default cultural values
general_gpt$RC2[general_gpt$model == 'GPT-3.5-turbo'] = mean(general_coordinate_gpt_3.5_turbo$RC2) #calculate the mean of RC2 across all the prompt variants as the y-coordinate of GPT-3.5 Turbo's default cultural values


###GPT-4-0613###
file.choose()
general_gpt_4_0613 = read.csv("S2_WideTable_Part1_scores_gpt-4-0613.csv") #The csv file can be found in the "Analysis_Part1_Default_Cultural_Values" folder of the OSF project

general_coordinate_gpt_4_0613 = predict.psych(analysis, general_gpt_4_0613[,3:12], joint_data_for_fa[,5:14]) #Get PCA scores for every country's GPT answers
general_coordinate_gpt_4_0613 = as.data.frame(general_coordinate_gpt_4_0613)

general_coordinate_gpt_4_0613$RC1 = 1.81 * general_coordinate_gpt_4_0613$RC1 + 0.38 #rescale RC1 following WVS's procedure
general_coordinate_gpt_4_0613$RC2 = 1.61 * general_coordinate_gpt_4_0613$RC2 - 0.01 #rescale RC1 following WVS's procedure

general_gpt$RC1[general_gpt$model == 'GPT-4'] = mean(general_coordinate_gpt_4_0613$RC1) #calculate the mean of RC1 across all the prompt variants as the x-coordinate of GPT-4's default cultural values
general_gpt$RC2[general_gpt$model == 'GPT-4'] = mean(general_coordinate_gpt_4_0613$RC2) #calculate the mean of RC2 across all the prompt variants as the y-coordinate of GPT-4's default cultural values


###GPT-4-turbo-2024-04-09###
file.choose()
general_gpt_4_turbo = read.csv("S3_WideTable_Part1_scores_gpt-4-turbo-2024-04-09.csv") #The csv file can be found in the "Analysis_Part1_Default_Cultural_Values" folder of the OSF project

general_coordinate_gpt_4_turbo = predict.psych(analysis, general_gpt_4_turbo[,3:12], joint_data_for_fa[,5:14]) #Get PCA scores for every country's GPT answers
general_coordinate_gpt_4_turbo = as.data.frame(general_coordinate_gpt_4_turbo)

general_coordinate_gpt_4_turbo$RC1 = 1.81 * general_coordinate_gpt_4_turbo$RC1 + 0.38 #rescale RC1 following WVS's procedure
general_coordinate_gpt_4_turbo$RC2 = 1.61 * general_coordinate_gpt_4_turbo$RC2 - 0.01 #rescale RC2 following WVS's procedure

general_gpt$RC1[general_gpt$model == 'GPT-4-turbo'] = mean(general_coordinate_gpt_4_turbo$RC1) #calculate the mean of RC1 across all the prompt variants as the x-coordinate of GPT-4 Turbo's default cultural values
general_gpt$RC2[general_gpt$model == 'GPT-4-turbo'] = mean(general_coordinate_gpt_4_turbo$RC2) #calculate the mean of RC2 across all the prompt variants as the y-coordinate of GPT-4 Turbo's default cultural values


###GPT-4o-2024-05-13###
file.choose()
general_gpt_4o = read.csv("S4_WideTable_Part1_scores_gpt-4o-2024-05-13.csv") #The csv file can be found in the "Analysis_Part1_Default_Cultural_Values" folder of the OSF project

general_coordinate_gpt_4o = predict.psych(analysis, general_gpt_4o[,3:12], joint_data_for_fa[,5:14]) #Get PCA scores for every country's GPT answers
general_coordinate_gpt_4o = as.data.frame(general_coordinate_gpt_4o)

general_coordinate_gpt_4o$RC1 = 1.81 * general_coordinate_gpt_4o$RC1 + 0.38 #rescale RC1 following WVS's procedure
general_coordinate_gpt_4o$RC2 = 1.61 * general_coordinate_gpt_4o$RC2 - 0.01 #rescale RC2 following WVS's procedure

general_gpt$RC1[general_gpt$model == 'GPT-4o'] = mean(general_coordinate_gpt_4o$RC1) #calculate the mean of RC1 across all the prompt variants as the x-coordinate of GPT-4o's default cultural values
general_gpt$RC2[general_gpt$model == 'GPT-4o'] = mean(general_coordinate_gpt_4o$RC2) #calculate the mean of RC2 across all the prompt variants as the y-coordinate of GPT-4o's default cultural values


###Plot GPT models' general cultural expressions on the cultural map###
general_gpt_for_plot = general_gpt
general_gpt_for_plot$nudge_y = c(0.07, -0.06, -0.07, 0.07)
general_gpt_for_plot$nudge_x = c(0, 0.14, 0, 0)

plot2 = plot1 + geom_point(data = general_gpt_for_plot, aes(RC1, RC2), color = "red") +
  geom_text(data = general_gpt_for_plot, aes(RC1, RC2, label = model), color = "red", nudge_x = general_gpt_for_plot$nudge_x, nudge_y = general_gpt_for_plot$nudge_y)+
  theme(legend.position = "top",
        legend.title = element_blank()) 
plot2
ggsave(filename = "RQ1_all_GPT_on_map.png", plot = plot2, width = 8, height = 7)


###Add GPT-3 to the map###
#Note: For GPT-3, we only tested with one respondant descriptor: "You are an average human being responding to the following survey question."
gpt3_default_scores = data.frame(a008 = 2, a165 = 1, e018 = 1, e025 = 1, f063 = 7, f118 = 6, f120 = 5, g006 = 2, y002 = 2, y003 = 1)
gpt3_default_pca_scores = predict.psych(analysis, gpt3_default_scores, joint_data_for_fa[,5:14])
gpt3_default_pca_scores = as.data.frame(gpt3_default_pca_scores)
gpt3_default_pca_scores$RC1 = 1.81 * gpt3_default_pca_scores$RC1 + 0.38
gpt3_default_pca_scores$RC2 = 1.61 * gpt3_default_pca_scores$RC2 - 0.01
gpt3_default_pca_scores$country.territory = "general"
plot3 = plot2 + geom_point(data = gpt3_default_pca_scores, aes(RC1, RC2), color = "red") +
  geom_text(data = gpt3_default_pca_scores, aes(RC1, RC2, label = "GPT-3"), color = "red", nudge_x = 0.2, nudge_y = 0)
plot3
ggsave(filename = "RQ1_GPT_include_gpt3_on_map.png", plot = plot3, width = 8, height = 7) #This is Figure 1 in our main paper

new_row <- c(model = "GPT-3", RC1 = gpt3_default_pca_scores$RC1, RC2 = gpt3_default_pca_scores$RC2)
general_gpt = rbind(general_gpt, new_row)


###Calculate L2 distance between GPT general answers and human survey answers
colnames(general_gpt)[colnames(general_gpt) == "RC1"] ="RC1_final" #Change the column name for merge the datasets
colnames(general_gpt)[colnames(general_gpt) == "RC2"] ="RC2_final" #Change the column name for merge the datasets
general_gpt$RC1_final = as.numeric(general_gpt$RC1_final)
general_gpt$RC2_final = as.numeric(general_gpt$RC2_final)

pca_result_country_level_selected = subset(pca_result_country_level, select = c(RC1_final, RC2_final)) #Get the PCA scores for each country in human survey
general_gpt_selected = subset(general_gpt, select = c(RC1_final, RC2_final))
gpt_l2_c_data = bind_rows(pca_result_country_level_selected, general_gpt_selected)

#get L2 distances
l2_c_results = as.data.frame(as.matrix(dist(gpt_l2_c_data)))

#gpt-3.5-turbo
gpt3.5turbo_l2_c_results = subset(l2_c_results, select = '108')
gpt3.5turbo_l2_c_results = slice(gpt3.5turbo_l2_c_results, 1:107)
gpt3.5turbo_l2_c_results$country.territory = pca_result_country_level$country.territory
colnames(gpt3.5turbo_l2_c_results)[colnames(gpt3.5turbo_l2_c_results) == "108"] ="l2_c_gpt_3.5_turbo"

#gpt-4
gpt4_l2_c_results = subset(l2_c_results, select = '109')
gpt4_l2_c_results = slice(gpt4_l2_c_results, 1:107)
gpt4_l2_c_results$country.territory = pca_result_country_level$country.territory
colnames(gpt4_l2_c_results)[colnames(gpt4_l2_c_results) == "109"] ="l2_c_gpt_4"

#gpt-4-turbo
gpt4turbo_l2_c_results = subset(l2_c_results, select = '110')
gpt4turbo_l2_c_results = slice(gpt4turbo_l2_c_results, 1:107)
gpt4turbo_l2_c_results$country.territory = pca_result_country_level$country.territory
colnames(gpt4turbo_l2_c_results)[colnames(gpt4turbo_l2_c_results) == "110"] ="l2_c_gpt_4_turbo"

#gpt-4o
gpt4o_l2_c_results = subset(l2_c_results, select = '111')
gpt4o_l2_c_results = slice(gpt4o_l2_c_results, 1:107)
gpt4o_l2_c_results$country.territory = pca_result_country_level$country.territory
colnames(gpt4o_l2_c_results)[colnames(gpt4o_l2_c_results) == "111"] ="l2_c_gpt_4o"

#gpt-3
gpt3_l2_c_results = subset(l2_c_results, select = '112')
gpt3_l2_c_results = slice(gpt3_l2_c_results, 1:107)
gpt3_l2_c_results$country.territory = pca_result_country_level$country.territory
colnames(gpt3_l2_c_results)[colnames(gpt3_l2_c_results) == "112"] ="l2_c_gpt_3"

#combine the results
l2_results = gpt3_l2_c_results %>%
  left_join(gpt3.5turbo_l2_c_results, by = c('country.territory' = 'country.territory')) %>%
  left_join(gpt4_l2_c_results, by = c('country.territory' = 'country.territory')) %>%
  left_join(gpt4turbo_l2_c_results, by = c('country.territory' = 'country.territory')) %>%
  left_join(gpt4o_l2_c_results, by = c('country.territory' = 'country.territory'))

l2_results <- l2_results %>%
  select(country.territory, everything())

write.csv(l2_results, "RQ1_General_Responses_L2_Results.csv", row.names = FALSE)



#####Part 2: Propose Cultural Prompting as a control strategy#####

pca_result_country_level_selected = subset(pca_result_country_level, select = c(RC1_final, RC2_final, country.territory))

###GPT-4o##
file.choose()
CP_gpt_4o = read.csv("WideTable_Part2_all_district_scores_gpt-4o-2024-05-13.csv") #The csv file can be found in the folder "Analysis_Part2_Localized_Cultural_Values" of the OSF project
summary(CP_gpt_4o)
colnames(CP_gpt_4o)[colnames(CP_gpt_4o) == "country"] ="country.territory"

CP_coordinate_gpt_4o = predict.psych(analysis, CP_gpt_4o[,3:12], joint_data_for_fa[,5:14])
CP_coordinate_gpt_4o = as.data.frame(CP_coordinate_gpt_4o)

CP_coordinate_gpt_4o$RC1 = 1.81 * CP_coordinate_gpt_4o$RC1 + 0.38
CP_coordinate_gpt_4o$RC2 = 1.61 * CP_coordinate_gpt_4o$RC2 - 0.01

CP_coordinate_gpt_4o$country.territory = CP_gpt_4o$country.territory

CP_coordinate_gpt_4o = CP_coordinate_gpt_4o %>%
  group_by(country.territory) %>%
  summarise(
    RC1_cp_gpt_4o = mean(RC1), 
    RC2_cp_gpt_4o = mean(RC2)
  )

CP_coordinate_gpt_4o$country.territory <- gsub("_", " ", CP_coordinate_gpt_4o$country.territory)

gpt4o_l2_a_data = left_join(pca_result_country_level_selected, CP_coordinate_gpt_4o, by = c('country.territory' = 'country.territory'))
colnames(gpt4o_l2_a_data)[colnames(gpt4o_l2_a_data) == "RC1_final"] ="RC1_human_survey"
colnames(gpt4o_l2_a_data)[colnames(gpt4o_l2_a_data) == "RC2_final"] ="RC2_human_survey"
gpt4o_l2_a_data$RC1_diff = gpt4o_l2_a_data$RC1_cp_gpt_4o - gpt4o_l2_a_data$RC1_human_survey
gpt4o_l2_a_data$RC2_diff = gpt4o_l2_a_data$RC2_cp_gpt_4o - gpt4o_l2_a_data$RC2_human_survey
gpt4o_l2_a_data <- gpt4o_l2_a_data %>%
  select(country.territory, everything())
write.csv(gpt4o_l2_a_data, "coordinates_on_map_gpt-4o-2024-05-13.csv", row.names = FALSE)

gpt4o_l2_a_data$l2_a_gpt4o = sqrt((gpt4o_l2_a_data$RC1_human_survey - gpt4o_l2_a_data$RC1_cp_gpt_4o)^2 + (gpt4o_l2_a_data$RC2_human_survey - gpt4o_l2_a_data$RC2_cp_gpt_4o)^2)
gpt4o_l2_a_data_select = subset(gpt4o_l2_a_data, select = c(country.territory, l2_a_gpt4o))


###GPT-4-turbo##
file.choose()
CP_gpt_4turbo = read.csv("WideTable_Part2_all_district_scores_gpt-4-turbo-2024-04-09.csv") #The csv file can be found in the folder "Analysis_Part2_Localized_Cultural_Values" of the OSF project 
summary(CP_gpt_4turbo)
colnames(CP_gpt_4turbo)[colnames(CP_gpt_4turbo) == "country"] ="country.territory"

CP_coordinate_gpt_4turbo = predict.psych(analysis, CP_gpt_4turbo[,3:12], joint_data_for_fa[,5:14])
CP_coordinate_gpt_4turbo = as.data.frame(CP_coordinate_gpt_4turbo)

CP_coordinate_gpt_4turbo$RC1 = 1.81 * CP_coordinate_gpt_4turbo$RC1 + 0.38
CP_coordinate_gpt_4turbo$RC2 = 1.61 * CP_coordinate_gpt_4turbo$RC2 - 0.01

CP_coordinate_gpt_4turbo$country.territory = CP_gpt_4turbo$country.territory

CP_coordinate_gpt_4turbo = CP_coordinate_gpt_4turbo %>%
  group_by(country.territory) %>%
  summarise(
    RC1_cp_gpt_4turbo = mean(RC1),
    RC2_cp_gpt_4turbo = mean(RC2)
  )

CP_coordinate_gpt_4turbo$country.territory <- gsub("_", " ", CP_coordinate_gpt_4turbo$country.territory)

gpt4turbo_l2_a_data = left_join(pca_result_country_level_selected, CP_coordinate_gpt_4turbo, by = c('country.territory' = 'country.territory'))
colnames(gpt4turbo_l2_a_data)[colnames(gpt4turbo_l2_a_data) == "RC1_final"] ="RC1_human_survey"
colnames(gpt4turbo_l2_a_data)[colnames(gpt4turbo_l2_a_data) == "RC2_final"] ="RC2_human_survey"
gpt4turbo_l2_a_data$RC1_diff = gpt4turbo_l2_a_data$RC1_cp_gpt_4turbo - gpt4turbo_l2_a_data$RC1_human_survey
gpt4turbo_l2_a_data$RC2_diff = gpt4turbo_l2_a_data$RC2_cp_gpt_4turbo - gpt4turbo_l2_a_data$RC2_human_survey
gpt4turbo_l2_a_data <- gpt4turbo_l2_a_data %>%
  select(country.territory, everything())
write.csv(gpt4turbo_l2_a_data, "coordinates_on_map_gpt-4-turbo-2024-04-09.csv", row.names = FALSE)

gpt4turbo_l2_a_data$l2_a_gpt4turbo = sqrt((gpt4turbo_l2_a_data$RC1_human_survey - gpt4turbo_l2_a_data$RC1_cp_gpt_4turbo)^2 + (gpt4turbo_l2_a_data$RC2_human_survey - gpt4turbo_l2_a_data$RC2_cp_gpt_4turbo)^2)
gpt4turbo_l2_a_data_select = subset(gpt4turbo_l2_a_data, select = c(country.territory, l2_a_gpt4turbo))


###GPT-4##
file.choose()
CP_gpt_4 = read.csv("WideTable_Part2_all_district_scores_gpt-4-0613.csv") #The csv file can be found in the folder "Analysis_Part2_Localized_Cultural_Values" of the OSF project 
summary(CP_gpt_4)
colnames(CP_gpt_4)[colnames(CP_gpt_4) == "country"] ="country.territory"

CP_coordinate_gpt_4 = predict.psych(analysis, CP_gpt_4[,3:12], joint_data_for_fa[,5:14])
CP_coordinate_gpt_4 = as.data.frame(CP_coordinate_gpt_4)

CP_coordinate_gpt_4$RC1 = 1.81 * CP_coordinate_gpt_4$RC1 + 0.38
CP_coordinate_gpt_4$RC2 = 1.61 * CP_coordinate_gpt_4$RC2 - 0.01

CP_coordinate_gpt_4$country.territory = CP_gpt_4$country.territory

CP_coordinate_gpt_4 = CP_coordinate_gpt_4 %>%
  group_by(country.territory) %>%
  summarise(
    RC1_cp_gpt_4 = mean(RC1),
    RC2_cp_gpt_4 = mean(RC2)
  )

CP_coordinate_gpt_4$country.territory <- gsub("_", " ", CP_coordinate_gpt_4$country.territory)

gpt4_l2_a_data = left_join(pca_result_country_level_selected, CP_coordinate_gpt_4, by = c('country.territory' = 'country.territory'))
colnames(gpt4_l2_a_data)[colnames(gpt4_l2_a_data) == "RC1_final"] ="RC1_human_survey"
colnames(gpt4_l2_a_data)[colnames(gpt4_l2_a_data) == "RC2_final"] ="RC2_human_survey"
gpt4_l2_a_data$RC1_diff = gpt4_l2_a_data$RC1_cp_gpt_4 - gpt4_l2_a_data$RC1_human_survey
gpt4_l2_a_data$RC2_diff = gpt4_l2_a_data$RC2_cp_gpt_4 - gpt4_l2_a_data$RC2_human_survey
gpt4_l2_a_data <- gpt4_l2_a_data %>%
  select(country.territory, everything())
write.csv(gpt4_l2_a_data, "coordinates_on_map_gpt-4-0613.csv", row.names = FALSE)

gpt4_l2_a_data$l2_a_gpt4 = sqrt((gpt4_l2_a_data$RC1_human_survey - gpt4_l2_a_data$RC1_cp_gpt_4)^2 + (gpt4_l2_a_data$RC2_human_survey - gpt4_l2_a_data$RC2_cp_gpt_4)^2)
gpt4_l2_a_data_select = subset(gpt4_l2_a_data, select = c(country.territory, l2_a_gpt4))


###GPT-3.5-turbo##
file.choose()
CP_gpt_3.5turbo = read.csv("WideTable_Part2_all_district_scores_gpt-3.5-turbo-0613.csv") #The csv file can be found in the folder "Analysis_Part2_Localized_Cultural_Values" of the OSF project
summary(CP_gpt_3.5turbo) #f120 has 2 null values, f118 has 30 null values
check = CP_gpt_3.5turbo %>%
  filter(is.na(f120))#Libya with variant 1 and variant 2
check = CP_gpt_3.5turbo %>%
  filter(is.na(f118)) #Algeria (#2), Azerbaijan (#2), Iran (#1,2,5,8,9), Iraq (#2,5), Jordan (#2), Libya (all variants), Maldives (#2,5), Palestine (#2,5,9), Rwanda (#2), Tunisia (#2), Yemen (#0, #2), Zambia (#2) 

CP_gpt_3.5turbo <- na.omit(CP_gpt_3.5turbo)

colnames(CP_gpt_3.5turbo)[colnames(CP_gpt_3.5turbo) == "country"] ="country.territory"

CP_coordinate_gpt_3.5turbo = predict.psych(analysis, CP_gpt_3.5turbo[,3:12], joint_data_for_fa[,5:14])
CP_coordinate_gpt_3.5turbo = as.data.frame(CP_coordinate_gpt_3.5turbo)

CP_coordinate_gpt_3.5turbo$RC1 = 1.81 * CP_coordinate_gpt_3.5turbo$RC1 + 0.38
CP_coordinate_gpt_3.5turbo$RC2 = 1.61 * CP_coordinate_gpt_3.5turbo$RC2 - 0.01

CP_coordinate_gpt_3.5turbo$country.territory = CP_gpt_3.5turbo$country.territory

CP_coordinate_gpt_3.5turbo = CP_coordinate_gpt_3.5turbo %>%
  group_by(country.territory) %>%
  summarise(
    RC1_cp_gpt_3.5turbo = mean(RC1),
    RC2_cp_gpt_3.5turbo = mean(RC2)
  )

CP_coordinate_gpt_3.5turbo$country.territory <- gsub("_", " ", CP_coordinate_gpt_3.5turbo$country.territory)

gpt3.5turbo_l2_a_data = left_join(pca_result_country_level_selected, CP_coordinate_gpt_3.5turbo, by = c('country.territory' = 'country.territory'))
colnames(gpt3.5turbo_l2_a_data)[colnames(gpt3.5turbo_l2_a_data) == "RC1_final"] ="RC1_human_survey"
colnames(gpt3.5turbo_l2_a_data)[colnames(gpt3.5turbo_l2_a_data) == "RC2_final"] ="RC2_human_survey"
gpt3.5turbo_l2_a_data$RC1_diff = gpt3.5turbo_l2_a_data$RC1_cp_gpt_3.5turbo - gpt3.5turbo_l2_a_data$RC1_human_survey
gpt3.5turbo_l2_a_data$RC2_diff = gpt3.5turbo_l2_a_data$RC2_cp_gpt_3.5turbo - gpt3.5turbo_l2_a_data$RC2_human_survey
gpt3.5turbo_l2_a_data <- gpt3.5turbo_l2_a_data %>%
  select(country.territory, everything())
write.csv(gpt3.5turbo_l2_a_data, "coordinates_on_map_gpt-3.5-turbo-0613.csv", row.names = FALSE)

gpt3.5turbo_l2_a_data$l2_a_gpt3.5turbo = sqrt((gpt3.5turbo_l2_a_data$RC1_human_survey - gpt3.5turbo_l2_a_data$RC1_cp_gpt_3.5turbo)^2 + (gpt3.5turbo_l2_a_data$RC2_human_survey - gpt3.5turbo_l2_a_data$RC2_cp_gpt_3.5turbo)^2)
gpt3.5turbo_l2_a_data_select = subset(gpt3.5turbo_l2_a_data, select = c(country.territory, l2_a_gpt3.5turbo))


###GPT-3###
CP_gpt_3 = read.csv("GPT3_prompted_scores.csv") #The csv file can be found in the folder "Analysis_Part2_Localized_Cultural_Values" of the OSF project

CP_coordinate_gpt_3 = predict.psych(analysis, CP_gpt_3[,2:11], joint_data_for_fa[,5:14])
CP_coordinate_gpt_3 = as.data.frame(CP_coordinate_gpt_3)

CP_coordinate_gpt_3$RC1 = 1.81 * CP_coordinate_gpt_3$RC1 + 0.38
CP_coordinate_gpt_3$RC2 = 1.61 * CP_coordinate_gpt_3$RC2 - 0.01

CP_coordinate_gpt_3$country.territory = CP_gpt_3$country.territory

gpt3_l2_a_data = left_join(pca_result_country_level_selected, CP_coordinate_gpt_3, by = c('country.territory' = 'country.territory'))
colnames(gpt3_l2_a_data)[colnames(gpt3_l2_a_data) == "RC1_final"] ="RC1_human_survey"
colnames(gpt3_l2_a_data)[colnames(gpt3_l2_a_data) == "RC2_final"] ="RC2_human_survey"
colnames(gpt3_l2_a_data)[colnames(gpt3_l2_a_data) == "RC1"] ="RC1_cp_gpt_3"
colnames(gpt3_l2_a_data)[colnames(gpt3_l2_a_data) == "RC2"] ="RC2_cp_gpt_3"
gpt3_l2_a_data$RC1_diff = gpt3_l2_a_data$RC1_cp_gpt_3 - gpt3_l2_a_data$RC1_human_survey
gpt3_l2_a_data$RC2_diff = gpt3_l2_a_data$RC2_cp_gpt_3 - gpt3_l2_a_data$RC2_human_survey
gpt3_l2_a_data <- gpt3_l2_a_data %>%
  select(country.territory, everything())
write.csv(gpt3_l2_a_data, "coordinates_on_map_gpt-3.csv", row.names = FALSE)

gpt3_l2_a_data$l2_a_gpt3 = sqrt((gpt3_l2_a_data$RC1_human_survey - gpt3_l2_a_data$RC1_cp_gpt_3)^2 + (gpt3_l2_a_data$RC2_human_survey - gpt3_l2_a_data$RC2_cp_gpt_3)^2)
gpt3_l2_a_data_select = subset(gpt3_l2_a_data, select = c(country.territory, l2_a_gpt3))

###combine the results###
l2_results = l2_results %>%
  left_join(gpt4o_l2_a_data_select, by = c('country.territory' = 'country.territory')) %>%
  left_join(gpt4turbo_l2_a_data_select, by = c('country.territory' = 'country.territory')) %>%
  left_join(gpt4_l2_a_data_select, by = c('country.territory' = 'country.territory')) %>%
  left_join(gpt3.5turbo_l2_a_data_select, by = c('country.territory' = 'country.territory')) %>%
  left_join(gpt3_l2_a_data_select, by = c('country.territory' = 'country.territory'))
write.csv(l2_results, "RQ2_CP_Responses_L2_Results.csv")


###plot the distribution of L2_a and L2_c###

# Convert the l2_results (wide table) to a long table
long_table_l2_results <- gather(l2_results, key = "GPT.L2",value = "value", -country.territory)

long_table_l2_results$L2_type = if_else(long_table_l2_results$GPT.L2 == 'l2_c_gpt_3.5_turbo'|long_table_l2_results$GPT.L2 == 'l2_c_gpt_4'|long_table_l2_results$GPT.L2 == 'l2_c_gpt_4_turbo'|long_table_l2_results$GPT.L2 == 'l2_c_gpt_4o'|long_table_l2_results$GPT.L2 == 'l2_c_gpt_3', 'Without Cultural Prompting', 'pending')
long_table_l2_results$L2_type = if_else(long_table_l2_results$GPT.L2 == 'l2_a_gpt3.5turbo'|long_table_l2_results$GPT.L2 == 'l2_a_gpt4'|long_table_l2_results$GPT.L2 == 'l2_a_gpt4turbo'|long_table_l2_results$GPT.L2 == 'l2_a_gpt4o'|long_table_l2_results$GPT.L2 == 'l2_a_gpt3', 'With Cultural Prompting', long_table_l2_results$L2_type) 

long_table_l2_results$GPT_version = if_else(long_table_l2_results$GPT.L2 == 'l2_a_gpt3.5turbo'|long_table_l2_results$GPT.L2 == 'l2_c_gpt_3.5_turbo', 'GPT-3.5-turbo', 'pending')
long_table_l2_results$GPT_version = if_else(long_table_l2_results$GPT.L2 == 'l2_a_gpt4'|long_table_l2_results$GPT.L2 == 'l2_c_gpt_4', 'GPT-4', long_table_l2_results$GPT_version)
long_table_l2_results$GPT_version = if_else(long_table_l2_results$GPT.L2 == 'l2_a_gpt4turbo'|long_table_l2_results$GPT.L2 == 'l2_c_gpt_4_turbo', 'GPT-4 Turbo', long_table_l2_results$GPT_version)
long_table_l2_results$GPT_version = if_else(long_table_l2_results$GPT.L2 == 'l2_a_gpt4o'|long_table_l2_results$GPT.L2 == 'l2_c_gpt_4o', 'GPT-4o', long_table_l2_results$GPT_version)
long_table_l2_results$GPT_version = if_else(long_table_l2_results$GPT.L2 == 'l2_a_gpt3'|long_table_l2_results$GPT.L2 == 'l2_c_gpt_3', 'GPT-3', long_table_l2_results$GPT_version)


long_table_l2_results$L2_type <- factor(long_table_l2_results$L2_type, levels = c("Without Cultural Prompting", "With Cultural Prompting"))
RQ2_box_plot = ggplot(data = long_table_l2_results, aes(x = GPT_version, y=value, fill = L2_type)) +
  geom_boxplot() +
  scale_fill_manual(values = c("#CC79A7", "#0072B2")) +
  theme_classic() +
  theme(legend.position = "top",
        legend.title = element_blank(),
        axis.title.x = element_blank()
        ) +
  ylab("Cultural Gap (L2 distance for each country/territory)") 

ggsave(filename = "RQ2_Cultural_Distance_Boxplot.png", plot = RQ2_box_plot, width = 7, height = 5) #Figure 2 in the main paper

###Additional Statistical Analysis###
#GPT-3
shapiro.test(l2_results$l2_c_gpt_3) #not normal distribution
shapiro.test(l2_results$l2_a_gpt3) #not normal distribution
mean(l2_results$l2_c_gpt_3) #2.39
mean(l2_results$l2_a_gpt3) #2.11
wilcox.test(l2_results$l2_c_gpt_3, l2_results$l2_a_gpt3,paired = TRUE) #p-value = 3.942e-08

#GPT-3.5 Turbo
shapiro.test(l2_results$l2_c_gpt_3.5_turbo) #not normal distribution
shapiro.test(l2_results$l2_a_gpt3.5turbo) #not normal distribution
mean(l2_results$l2_c_gpt_3.5_turbo) #3.35
mean(l2_results$l2_a_gpt3.5turbo, na.rm = TRUE) #2.83
wilcox.test(l2_results$l2_c_gpt_3.5_turbo, l2_results$l2_a_gpt3.5turbo,paired = TRUE)

#GPT-4
shapiro.test(l2_results$l2_c_gpt_4)#not normal distribution
shapiro.test(l2_results$l2_a_gpt4)#normal
mean(l2_results$l2_c_gpt_4) #2.69
mean(l2_results$l2_a_gpt4) #1.65
wilcox.test(l2_results$l2_c_gpt_4, l2_results$l2_a_gpt4,paired = TRUE)

#GPT-4 Turbo
shapiro.test(l2_results$l2_c_gpt_4_turbo) #not normal
shapiro.test(l2_results$l2_a_gpt4turbo) #normal
mean(l2_results$l2_c_gpt_4_turbo) #2.71
mean(l2_results$l2_a_gpt4turbo) #1.77
wilcox.test(l2_results$l2_c_gpt_4_turbo, l2_results$l2_a_gpt4turbo,paired = TRUE)

#GPT-4o
shapiro.test(l2_results$l2_c_gpt_4o) #not normal
shapiro.test(l2_results$l2_a_gpt4o) #normal
mean(l2_results$l2_c_gpt_4o) #2.42
mean(l2_results$l2_a_gpt4o) #1.57
wilcox.test(l2_results$l2_c_gpt_4o, l2_results$l2_a_gpt4o,paired = TRUE)


###Variance due to prompt wording###
plot_grey =  ggplot(pca_result_country_level, aes(x = RC1_final, y = RC2_final, label = country.territory)) +
  geom_point(color = "grey") +
  geom_text_repel(aes(label = country.territory), box.padding = unit(0.25, "lines"), max.overlaps = 7, color = "grey") +
  theme_classic() +
  theme(
    axis.line.x = element_line(color = "grey"),  
    axis.line.y = element_line(color = "grey")
  ) + 
  scale_x_continuous(breaks = c(-2.50, -2.00, -1.50, -1.00, -0.50, 0.00, 0.50, 1.00, 1.50, 2.00, 2.50, 3.00, 3.50)) +
  scale_y_continuous(breaks = c(-2.50, -2.00, -1.50, -1.00, -0.50, 0.00, 0.50, 1.00, 1.50, 2.00)) +
  labs(x = "Survival vs. Self-Expression Values", y = "Traditional vs. Secular Values")

model = c('GPT-3.5-turbo', 'GPT-4', 'GPT-4-turbo', 'GPT-4o')
mean_d_to_avg = c(0,0,0,0)
combined_prompt_varaince_df = data.frame(model, mean_d_to_avg)


#GPT-3.5 Turbo
plot_3.5_variance_df = general_coordinate_gpt_3.5_turbo
plot_3.5_variance_df$label = c(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
plot_3.5_variance = plot_grey + geom_point (data = plot_3.5_variance_df, aes(x = RC1, y = RC2),color = "red",inherit.aes = FALSE) +
  geom_text_repel(data = plot_3.5_variance_df, aes(x = RC1, y = RC2, label = label), nudge_x = 0.1, nudge_y = 0.1)
ggsave(filename = "RQ1_GPT-3.5-turbo_variance_on_map.png", plot = plot_3.5_variance, width = 8, height = 7)

general_coordinate_gpt_3.5_turbo$d_to_avg = sqrt((general_coordinate_gpt_3.5_turbo$RC1 - general_gpt$RC1_final[general_gpt$model == "GPT-3.5-turbo"])^2 + (general_coordinate_gpt_3.5_turbo$RC2 - general_gpt$RC2_final[general_gpt$model == "GPT-3.5-turbo"])^2)
combined_prompt_varaince_df$mean_d_to_avg[combined_prompt_varaince_df$model == "GPT-3.5-turbo"] = mean(general_coordinate_gpt_3.5_turbo$d_to_avg)
combined_prompt_varaince_df$mean_d_to_avg[combined_prompt_varaince_df$model == "GPT-3.5-turbo"] = mean(general_coordinate_gpt_3.5_turbo$d_to_avg)
combined_prompt_varaince_df$se_d_to_avg[combined_prompt_varaince_df$model == "GPT-3.5-turbo"] = sd(general_coordinate_gpt_3.5_turbo$d_to_avg)/sqrt(length(general_coordinate_gpt_3.5_turbo$d_to_avg))


#GPT-4
plot_4_variance_df = general_coordinate_gpt_4_0613
plot_4_variance_df$label = c(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
plot_4_variance = plot_grey + geom_point (data = plot_4_variance_df, aes(x = RC1, y = RC2),color = "red",inherit.aes = FALSE) +
  geom_text_repel(data = plot_4_variance_df, aes(x = RC1, y = RC2, label = label), nudge_x = 0.1, nudge_y = 0.1)
ggsave(filename = "RQ1_GPT-4_variance_on_map.png", plot = plot_4_variance, width = 8, height = 7)

general_coordinate_gpt_4_0613$d_to_avg = sqrt((general_coordinate_gpt_4_0613$RC1 - general_gpt$RC1_final[general_gpt$model == "GPT-4"])^2 + (general_coordinate_gpt_4_0613$RC2 - general_gpt$RC2_final[general_gpt$model == "GPT-4"])^2)
combined_prompt_varaince_df$mean_d_to_avg[combined_prompt_varaince_df$model == "GPT-4"] = mean(general_coordinate_gpt_4_0613$d_to_avg)
combined_prompt_varaince_df$se_d_to_avg[combined_prompt_varaince_df$model == "GPT-4"] = sd(general_coordinate_gpt_4_0613$d_to_avg)/sqrt(length(general_coordinate_gpt_4_0613$d_to_avg))


#GPT-4-turbo
plot_4turbo_variance_df = general_coordinate_gpt_4_turbo
plot_4turbo_variance_df$label = c(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
plot_4turbo_variance = plot_grey + geom_point (data = plot_4turbo_variance_df, aes(x = RC1, y = RC2),color = "red",inherit.aes = FALSE) +
  geom_text_repel(data = plot_4turbo_variance_df, aes(x = RC1, y = RC2, label = label), nudge_x = 0.1, nudge_y = 0.1)
ggsave(filename = "RQ1_GPT-4-turbo_variance_on_map.png", plot = plot_4turbo_variance, width = 8, height = 7)

general_coordinate_gpt_4_turbo$d_to_avg = sqrt((general_coordinate_gpt_4_turbo$RC1 - general_gpt$RC1_final[general_gpt$model == "GPT-4-turbo"])^2 + (general_coordinate_gpt_4_turbo$RC2 - general_gpt$RC2_final[general_gpt$model == "GPT-4-turbo"])^2)
combined_prompt_varaince_df$mean_d_to_avg[combined_prompt_varaince_df$model == "GPT-4-turbo"] = mean(general_coordinate_gpt_4_turbo$d_to_avg)
combined_prompt_varaince_df$se_d_to_avg[combined_prompt_varaince_df$model == "GPT-4-turbo"] = sd(general_coordinate_gpt_4_turbo$d_to_avg)/sqrt(length(general_coordinate_gpt_4_turbo$d_to_avg))

#GPT-4o
plot_4o_variance_df = general_coordinate_gpt_4o
plot_4o_variance_df$label = c(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
plot_4o_variance = plot_grey + geom_point (data = plot_4o_variance_df, aes(x = RC1, y = RC2),color = "red",inherit.aes = FALSE) +
  geom_text_repel(data = plot_4o_variance_df, aes(x = RC1, y = RC2, label = label), nudge_x = 0.1, nudge_y = 0.1)
ggsave(filename = "RQ1_GPT-4o_variance_on_map.png", plot = plot_4o_variance, width = 8, height = 7)

general_coordinate_gpt_4o$d_to_avg = sqrt((general_coordinate_gpt_4o$RC1 - general_gpt$RC1_final[general_gpt$model == "GPT-4o"])^2 + (general_coordinate_gpt_4o$RC2 - general_gpt$RC2_final[general_gpt$model == "GPT-4o"])^2)
combined_prompt_varaince_df$mean_d_to_avg[combined_prompt_varaince_df$model == "GPT-4o"] = mean(general_coordinate_gpt_4o$d_to_avg)
combined_prompt_varaince_df$se_d_to_avg[combined_prompt_varaince_df$model == "GPT-4o"] = sd(general_coordinate_gpt_4o$d_to_avg)/sqrt(length(general_coordinate_gpt_4o$d_to_avg))

#Indicate the setting
combined_prompt_varaince_df$Type = "Without Cultural Prompting"

#GPT-3-turbo with cultural prompting
CP_gpt_3.5turbo = read.csv("/Users/joyce/Cornell/GPT WVS Revision/output/Part2/WideTable_Part2_all_district_scores_gpt-3.5-turbo-0613.csv")

CP_gpt_3.5turbo <- na.omit(CP_gpt_3.5turbo)

colnames(CP_gpt_3.5turbo)[colnames(CP_gpt_3.5turbo) == "country"] ="country.territory"

CP_coordinate_gpt_3.5turbo = predict.psych(analysis, CP_gpt_3.5turbo[,3:12], joint_data_for_fa[,5:14])
CP_coordinate_gpt_3.5turbo = as.data.frame(CP_coordinate_gpt_3.5turbo)

CP_coordinate_gpt_3.5turbo$RC1 = 1.81 * CP_coordinate_gpt_3.5turbo$RC1 + 0.38
CP_coordinate_gpt_3.5turbo$RC2 = 1.61 * CP_coordinate_gpt_3.5turbo$RC2 - 0.01

CP_coordinate_gpt_3.5turbo$country.territory = CP_gpt_3.5turbo$country.territory

CP_coordinate_gpt_3.5turbo_for_variance_plot = CP_coordinate_gpt_3.5turbo %>%
  group_by(country.territory) %>%
  mutate(
    RC1_cp_gpt_3.5turbo = mean(RC1),
    RC2_cp_gpt_3.5turbo = mean(RC2)
  )
CP_coordinate_gpt_3.5turbo_for_variance_plot$d_to_avg = sqrt((CP_coordinate_gpt_3.5turbo_for_variance_plot$RC1 - CP_coordinate_gpt_3.5turbo_for_variance_plot$RC1_cp_gpt_3.5turbo)^2 + (CP_coordinate_gpt_3.5turbo_for_variance_plot$RC2 - CP_coordinate_gpt_3.5turbo_for_variance_plot$RC2_cp_gpt_3.5turbo)^2)

CP_coordinate_gpt_3.5turbo_for_variance_plot = CP_coordinate_gpt_3.5turbo_for_variance_plot %>%
  group_by(country.territory) %>%
  summarise(mean_d_to_avg = mean(d_to_avg))

new_row = c("GPT-3.5-turbo", mean(CP_coordinate_gpt_3.5turbo_for_variance_plot$mean_d_to_avg), sd(CP_coordinate_gpt_3.5turbo_for_variance_plot$mean_d_to_avg)/sqrt(length(CP_coordinate_gpt_3.5turbo_for_variance_plot$mean_d_to_avg)), "With Cultural Prompting")
combined_prompt_varaince_df = rbind(combined_prompt_varaince_df, new_row)

#GPT-4 with cultural prompting
CP_gpt_4 = read.csv("/Users/joyce/Cornell/GPT WVS Revision/output/Part2/WideTable_Part2_all_district_scores_gpt-4-0613.csv")
colnames(CP_gpt_4)[colnames(CP_gpt_4) == "country"] ="country.territory"

CP_coordinate_gpt_4 = predict.psych(analysis, CP_gpt_4[,3:12], joint_data_for_fa[,5:14])
CP_coordinate_gpt_4 = as.data.frame(CP_coordinate_gpt_4)

CP_coordinate_gpt_4$RC1 = 1.81 * CP_coordinate_gpt_4$RC1 + 0.38
CP_coordinate_gpt_4$RC2 = 1.61 * CP_coordinate_gpt_4$RC2 - 0.01

CP_coordinate_gpt_4$country.territory = CP_gpt_4$country.territory

CP_coordinate_gpt_4_for_variance_plot = CP_coordinate_gpt_4 %>%
  group_by(country.territory) %>%
  mutate(
    RC1_cp_gpt_4 = mean(RC1),
    RC2_cp_gpt_4 = mean(RC2)
  )

CP_coordinate_gpt_4_for_variance_plot$d_to_avg = sqrt((CP_coordinate_gpt_4_for_variance_plot$RC1 - CP_coordinate_gpt_4_for_variance_plot$RC1_cp_gpt_4)^2 + (CP_coordinate_gpt_4_for_variance_plot$RC2 - CP_coordinate_gpt_4_for_variance_plot$RC2_cp_gpt_4)^2)

CP_coordinate_gpt_4_for_variance_plot = CP_coordinate_gpt_4_for_variance_plot %>%
  group_by(country.territory) %>%
  summarise(mean_d_to_avg = mean(d_to_avg))

new_row = c("GPT-4", mean(CP_coordinate_gpt_4_for_variance_plot$mean_d_to_avg), sd(CP_coordinate_gpt_4_for_variance_plot$mean_d_to_avg)/sqrt(length(CP_coordinate_gpt_4_for_variance_plot$mean_d_to_avg)), "With Cultural Prompting")
combined_prompt_varaince_df = rbind(combined_prompt_varaince_df, new_row)


#GPT-4 Turbo with cultural prompting
CP_gpt_4turbo = read.csv("/Users/joyce/Cornell/GPT WVS Revision/output/Part2/WideTable_Part2_all_district_scores_gpt-4-turbo-2024-04-09.csv")
colnames(CP_gpt_4turbo)[colnames(CP_gpt_4turbo) == "country"] ="country.territory"

CP_coordinate_gpt_4turbo = predict.psych(analysis, CP_gpt_4turbo[,3:12], joint_data_for_fa[,5:14])
CP_coordinate_gpt_4turbo = as.data.frame(CP_coordinate_gpt_4turbo)

CP_coordinate_gpt_4turbo$RC1 = 1.81 * CP_coordinate_gpt_4turbo$RC1 + 0.38
CP_coordinate_gpt_4turbo$RC2 = 1.61 * CP_coordinate_gpt_4turbo$RC2 - 0.01

CP_coordinate_gpt_4turbo$country.territory = CP_gpt_4turbo$country.territory

CP_coordinate_gpt_4turbo_for_variance_plot = CP_coordinate_gpt_4turbo %>%
  group_by(country.territory) %>%
  mutate(
    RC1_cp_gpt_4turbo = mean(RC1),
    RC2_cp_gpt_4turbo = mean(RC2)
  )

CP_coordinate_gpt_4turbo_for_variance_plot$d_to_avg = sqrt((CP_coordinate_gpt_4turbo_for_variance_plot$RC1 - CP_coordinate_gpt_4turbo_for_variance_plot$RC1_cp_gpt_4turbo)^2 + (CP_coordinate_gpt_4turbo_for_variance_plot$RC2 - CP_coordinate_gpt_4turbo_for_variance_plot$RC2_cp_gpt_4turbo)^2)

CP_coordinate_gpt_4turbo_for_variance_plot = CP_coordinate_gpt_4turbo_for_variance_plot %>%
  group_by(country.territory) %>%
  summarise(mean_d_to_avg = mean(d_to_avg))

new_row = c("GPT-4-turbo", mean(CP_coordinate_gpt_4turbo_for_variance_plot$mean_d_to_avg), sd(CP_coordinate_gpt_4turbo_for_variance_plot$mean_d_to_avg)/sqrt(length(CP_coordinate_gpt_4turbo_for_variance_plot$mean_d_to_avg)), "With Cultural Prompting")
combined_prompt_varaince_df = rbind(combined_prompt_varaince_df, new_row)


#GPT-4o with cultural prompting
CP_gpt_4o = read.csv("/Users/joyce/Cornell/GPT WVS Revision/output/Part2/WideTable_Part2_all_district_scores_gpt-4o-2024-05-13.csv")
colnames(CP_gpt_4o)[colnames(CP_gpt_4o) == "country"] ="country.territory"

CP_coordinate_gpt_4o = predict.psych(analysis, CP_gpt_4o[,3:12], joint_data_for_fa[,5:14])
CP_coordinate_gpt_4o = as.data.frame(CP_coordinate_gpt_4o)

CP_coordinate_gpt_4o$RC1 = 1.81 * CP_coordinate_gpt_4o$RC1 + 0.38
CP_coordinate_gpt_4o$RC2 = 1.61 * CP_coordinate_gpt_4o$RC2 - 0.01

CP_coordinate_gpt_4o$country.territory = CP_gpt_4o$country.territory

CP_coordinate_gpt_4o_for_variance_plot = CP_coordinate_gpt_4o %>%
  group_by(country.territory) %>%
  mutate(
    RC1_cp_gpt_4o = mean(RC1),
    RC2_cp_gpt_4o = mean(RC2)
  )
CP_coordinate_gpt_4o_for_variance_plot$d_to_avg = sqrt((CP_coordinate_gpt_4o_for_variance_plot$RC1 - CP_coordinate_gpt_4o_for_variance_plot$RC1_cp_gpt_4o)^2 + (CP_coordinate_gpt_4o_for_variance_plot$RC2 - CP_coordinate_gpt_4o_for_variance_plot$RC2_cp_gpt_4o)^2)

CP_coordinate_gpt_4o_for_variance_plot = CP_coordinate_gpt_4o_for_variance_plot %>%
  group_by(country.territory) %>%
  summarise(mean_d_to_avg = mean(d_to_avg))

new_row = c("GPT-4o", mean(CP_coordinate_gpt_4o_for_variance_plot$mean_d_to_avg), sd(CP_coordinate_gpt_4o_for_variance_plot$mean_d_to_avg)/sqrt(length(CP_coordinate_gpt_4o_for_variance_plot$mean_d_to_avg)), "With Cultural Prompting")
combined_prompt_varaince_df = rbind(combined_prompt_varaince_df, new_row)

combined_prompt_varaince_df$mean_d_to_avg = as.numeric(combined_prompt_varaince_df$mean_d_to_avg)
combined_prompt_varaince_df$se_d_to_avg = as.numeric(combined_prompt_varaince_df$se_d_to_avg)

combined_prompt_varaince_df$Type = factor(combined_prompt_varaince_df$Type, levels = c("Without Cultural Prompting", "With Cultural Prompting"))

combined_prompt_varaince_plot = ggplot(data = combined_prompt_varaince_df, aes(x=model, y=mean_d_to_avg, fill=Type)) +
  geom_hline(yintercept = 0.50, linetype = "dashed", color = "black") +
  geom_hline(yintercept = 1.01, linetype = "dashed", color = "black") +
  geom_hline(yintercept = 1.51, linetype = "dashed", color = "black") +
  geom_bar(position=position_dodge(), stat="identity", colour='black') +
  scale_fill_manual(values = c("#CC79A7","#0072B2")) +
  geom_errorbar(aes(ymin = mean_d_to_avg - se_d_to_avg, ymax = mean_d_to_avg+ se_d_to_avg), width=.2,position=position_dodge(.9)) +
  theme_classic() +
  theme(
    legend.position = "top",
    legend.title = element_blank(),
    axis.title.x = element_blank()
  ) +
  ylab("Average Mean Absolute Deviation of L2 Distance") 

ggsave(filename = "Variance_Boxplot.png", plot = combined_prompt_varaince_plot, width = 7, height = 5)