library(tidyverse)
library(stats)
library(ggplot2)
library(ggrepel)
library(psych)
library(haven)

#####Part 0: Replicate the Inglehart-Welzel World Cultural Map#####
###Load WVS and EVS Data###
#Source: https://www.worldvaluessurvey.org/WVSEVStrend.jsp
wvs_timeseries_data = readRDS("../New Analysis on TimeSeries Data:/WVS_trends_3_0.rds")
length(unique(wvs_timeseries_data$s003)) #Note: 108 countries/territories from the WVS dataset
evs_timeseries_data = read_dta("../New Analysis on TimeSeries Data:/ZA7503_v3-0-0.dta 2/ZA7503_v3-0-0.dta")
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

country_code = read.csv("../New Analysis on TimeSeries Data:/s003.csv") #get the country/territory names
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


# Create an empty data frame to store model coordinates
general_gpt <- data.frame(
  model = c(
    "GPT-3.5-turbo",
    "GPT-4",
    "GPT-4-turbo",
    "GPT-4o",
    "GPT-5",
    "GPT-5 Test 2"
  ),
  RC1 = rep(0, 6),
  RC2 = rep(0, 6)
)


###GPT-3.5-turbo-0613###

list.files(
  "/Users/nataliahorst/Desktop/Dissertação 1/Analysis_Part1_Default_Cultural_Values-archive"
)

general_gpt_3.5_turbo = read.csv(
  "/Users/nataliahorst/Desktop/Dissertação 1/Analysis_Part1_Default_Cultural_Values-archive/S1_WideTable_Part1_scores_gpt-3.5-turbo-0613.csv"
)

general_coordinate_gpt_3.5_turbo = predict.psych(analysis, general_gpt_3.5_turbo[,3:12], joint_data_for_fa[,5:14]) #Get PCA scores for every country/territory's GPT answers
general_coordinate_gpt_3.5_turbo = as.data.frame(general_coordinate_gpt_3.5_turbo)

general_coordinate_gpt_3.5_turbo$RC1 = 1.81 * general_coordinate_gpt_3.5_turbo$RC1 + 0.38 #rescale RC1 following WVS's procedure
general_coordinate_gpt_3.5_turbo$RC2 = 1.61 * general_coordinate_gpt_3.5_turbo$RC2 - 0.01 #rescale RC2 following WVS's procedure

general_gpt$RC1[general_gpt$model == 'GPT-3.5-turbo'] = mean(general_coordinate_gpt_3.5_turbo$RC1) #calculate the mean of RC1 across all the prompt variants as the x-coordinate of GPT-3.5 Turbo's default cultural values
general_gpt$RC2[general_gpt$model == 'GPT-3.5-turbo'] = mean(general_coordinate_gpt_3.5_turbo$RC2) #calculate the mean of RC2 across all the prompt variants as the y-coordinate of GPT-3.5 Turbo's default cultural values


###GPT-4-0613###
general_gpt_4_0613 = read.csv(
  "/Users/nataliahorst/Desktop/Dissertação 1/Analysis_Part1_Default_Cultural_Values-archive/S2_WideTable_Part1_scores_gpt-4-0613.csv"
)

general_coordinate_gpt_4_0613 = predict.psych(analysis, general_gpt_4_0613[,3:12], joint_data_for_fa[,5:14]) #Get PCA scores for every country's GPT answers
general_coordinate_gpt_4_0613 = as.data.frame(general_coordinate_gpt_4_0613)

general_coordinate_gpt_4_0613$RC1 = 1.81 * general_coordinate_gpt_4_0613$RC1 + 0.38 #rescale RC1 following WVS's procedure
general_coordinate_gpt_4_0613$RC2 = 1.61 * general_coordinate_gpt_4_0613$RC2 - 0.01 #rescale RC1 following WVS's procedure

general_gpt$RC1[general_gpt$model == 'GPT-4'] = mean(general_coordinate_gpt_4_0613$RC1) #calculate the mean of RC1 across all the prompt variants as the x-coordinate of GPT-4's default cultural values
general_gpt$RC2[general_gpt$model == 'GPT-4'] = mean(general_coordinate_gpt_4_0613$RC2) #calculate the mean of RC2 across all the prompt variants as the y-coordinate of GPT-4's default cultural values


###GPT-4-turbo-2024-04-09###
general_gpt_4_turbo =  read.csv(
  "/Users/nataliahorst/Desktop/Dissertação 1/Analysis_Part1_Default_Cultural_Values-archive/S3_WideTable_Part1_scores_gpt-4-turbo-2024-04-09.csv"
)

general_coordinate_gpt_4_turbo = predict.psych(analysis, general_gpt_4_turbo[,3:12], joint_data_for_fa[,5:14]) #Get PCA scores for every country's GPT answers
general_coordinate_gpt_4_turbo = as.data.frame(general_coordinate_gpt_4_turbo)

general_coordinate_gpt_4_turbo$RC1 = 1.81 * general_coordinate_gpt_4_turbo$RC1 + 0.38 #rescale RC1 following WVS's procedure
general_coordinate_gpt_4_turbo$RC2 = 1.61 * general_coordinate_gpt_4_turbo$RC2 - 0.01 #rescale RC2 following WVS's procedure

general_gpt$RC1[general_gpt$model == 'GPT-4-turbo'] = mean(general_coordinate_gpt_4_turbo$RC1) #calculate the mean of RC1 across all the prompt variants as the x-coordinate of GPT-4 Turbo's default cultural values
general_gpt$RC2[general_gpt$model == 'GPT-4-turbo'] = mean(general_coordinate_gpt_4_turbo$RC2) #calculate the mean of RC2 across all the prompt variants as the y-coordinate of GPT-4 Turbo's default cultural values


###GPT-4o-2024-05-13###
general_gpt_4o =  read.csv("/Users/nataliahorst/Desktop/Dissertação 1/Analysis_Part1_Default_Cultural_Values-archive/S4_WideTable_Part1_scores_gpt-4o-2024-05-13.csv"
)

general_coordinate_gpt_4o = predict.psych(analysis, general_gpt_4o[,3:12], joint_data_for_fa[,5:14]) #Get PCA scores for every country's GPT answers
general_coordinate_gpt_4o = as.data.frame(general_coordinate_gpt_4o)

general_coordinate_gpt_4o$RC1 = 1.81 * general_coordinate_gpt_4o$RC1 + 0.38 #rescale RC1 following WVS's procedure
general_coordinate_gpt_4o$RC2 = 1.61 * general_coordinate_gpt_4o$RC2 - 0.01 #rescale RC2 following WVS's procedure

general_gpt$RC1[general_gpt$model == 'GPT-4o'] = mean(general_coordinate_gpt_4o$RC1) #calculate the mean of RC1 across all the prompt variants as the x-coordinate of GPT-4o's default cultural values
general_gpt$RC2[general_gpt$model == 'GPT-4o'] = mean(general_coordinate_gpt_4o$RC2) #calculate the mean of RC2 across all the prompt variants as the y-coordinate of GPT-4o's default cultural values



###GPT-5###

general_gpt_5 = read.csv("/Users/nataliahorst/Desktop/Dissertação 1/Analysis_Part1_Default_Cultural_Values-archive/WideTable_Part1_scores_gpt-5.csv")

general_coordinate_gpt_5 = predict.psych(analysis, general_gpt_5[,3:12], joint_data_for_fa[,5:14]) #Get PCA scores for every country's GPT answers
general_coordinate_gpt_5 = as.data.frame(general_coordinate_gpt_5)

general_coordinate_gpt_5$RC1 = 1.81 * general_coordinate_gpt_5$RC1 + 0.38 #rescale RC1 following WVS's procedure
general_coordinate_gpt_5$RC2 = 1.61 * general_coordinate_gpt_5$RC2 - 0.01 #rescale RC2 following WVS's procedure

general_gpt$RC1[general_gpt$model == 'GPT-5'] = mean(general_coordinate_gpt_5$RC1) #calculate the mean of RC1 across all the prompt variants as the x-coordinate of GPT-5's default cultural values
general_gpt$RC2[general_gpt$model == 'GPT-5'] = mean(general_coordinate_gpt_5$RC2) #calculate the mean of RC2 across all the prompt variants as the y-coordinate of GPT-5's default cultural values


###GPT-5 Test 2###

general_gpt_5_test_2 = read.csv("/Users/nataliahorst/Desktop/Dissertação 1/Analysis_Part1_Default_Cultural_Values-archive/ultuma_tentativa.csv")

general_coordinate_gpt_5_test_2 = predict.psych(analysis, general_gpt_5_test_2[,3:12], joint_data_for_fa[,5:14]) #Get PCA scores for every country's GPT answers
general_coordinate_gpt_5_test_2 = as.data.frame(general_coordinate_gpt_5_test_2)

general_coordinate_gpt_5_test_2$RC1 = 1.81 * general_coordinate_gpt_5_test_2$RC1 + 0.38 #rescale RC1 following WVS's procedure
general_coordinate_gpt_5_test_2$RC2 = 1.61 * general_coordinate_gpt_5_test_2$RC2 - 0.01 #rescale RC2 following WVS's procedure

general_gpt$RC1[general_gpt$model == 'GPT-5 Test 2'] = mean(general_coordinate_gpt_5_test_2$RC1) #calculate the mean of RC1 across all the prompt variants as the x-coordinate of GPT-5 Test 2's default cultural values
general_gpt$RC2[general_gpt$model == 'GPT-5 Test 2'] = mean(general_coordinate_gpt_5_test_2$RC2) #calculate the mean of RC2 across all the prompt variants as the y-coordinate of GPT-5 Test 2's default cultural values









#####Part 1: Test GPT's General Cultural Expressions#####
#Create an empty data frame "model" to store the xy-coordinate of each GPT model's default cultural expression
model = c('GPT-3.5-turbo', 'GPT-4', 'GPT-4-turbo', 'GPT-4o')
RC1 = c(0,0,0,0)
RC2 = c(0,0,0,0)
country.territory = c('general', 'general',  'general', 'general')
general_gpt = data.frame(model, RC1, RC2)

###GPT-3.5-turbo-0613###

general_gpt_3.5_turbo = read.csv(file.choose())

general_coordinate_gpt_3.5_turbo = predict.psych(analysis, general_gpt_3.5_turbo[,3:12], joint_data_for_fa[,5:14]) #Get PCA scores for every country/territory's GPT answers
general_coordinate_gpt_3.5_turbo = as.data.frame(general_coordinate_gpt_3.5_turbo)

general_coordinate_gpt_3.5_turbo$RC1 = 1.81 * general_coordinate_gpt_3.5_turbo$RC1 + 0.38 #rescale RC1 following WVS's procedure
general_coordinate_gpt_3.5_turbo$RC2 = 1.61 * general_coordinate_gpt_3.5_turbo$RC2 - 0.01 #rescale RC2 following WVS's procedure

general_gpt$RC1[general_gpt$model == 'GPT-3.5-turbo'] = mean(general_coordinate_gpt_3.5_turbo$RC1) #calculate the mean of RC1 across all the prompt variants as the x-coordinate of GPT-3.5 Turbo's default cultural values
general_gpt$RC2[general_gpt$model == 'GPT-3.5-turbo'] = mean(general_coordinate_gpt_3.5_turbo$RC2) #calculate the mean of RC2 across all the prompt variants as the y-coordinate of GPT-3.5 Turbo's default cultural values


###GPT-4-0613###
file.choose()
general_gpt_4_0613 = read.csv("../Analysis_Part1_Default_Cultural_Values-archive/S2_WideTable_Part1_scores_gpt-4-0613.csv")

general_coordinate_gpt_4_0613 = predict.psych(analysis, general_gpt_4_0613[,3:12], joint_data_for_fa[,5:14]) #Get PCA scores for every country's GPT answers
general_coordinate_gpt_4_0613 = as.data.frame(general_coordinate_gpt_4_0613)

general_coordinate_gpt_4_0613$RC1 = 1.81 * general_coordinate_gpt_4_0613$RC1 + 0.38 #rescale RC1 following WVS's procedure
general_coordinate_gpt_4_0613$RC2 = 1.61 * general_coordinate_gpt_4_0613$RC2 - 0.01 #rescale RC1 following WVS's procedure

general_gpt$RC1[general_gpt$model == 'GPT-4'] = mean(general_coordinate_gpt_4_0613$RC1) #calculate the mean of RC1 across all the prompt variants as the x-coordinate of GPT-4's default cultural values
general_gpt$RC2[general_gpt$model == 'GPT-4'] = mean(general_coordinate_gpt_4_0613$RC2) #calculate the mean of RC2 across all the prompt variants as the y-coordinate of GPT-4's default cultural values


###GPT-4-turbo-2024-04-09###
general_gpt_4_turbo = read.csv("../Analysis_Part1_Default_Cultural_Values-archive/S3_WideTable_Part1_scores_gpt-4-turbo-2024-04-09.csv")

general_coordinate_gpt_4_turbo = predict.psych(analysis, general_gpt_4_turbo[,3:12], joint_data_for_fa[,5:14]) #Get PCA scores for every country's GPT answers
general_coordinate_gpt_4_turbo = as.data.frame(general_coordinate_gpt_4_turbo)

general_coordinate_gpt_4_turbo$RC1 = 1.81 * general_coordinate_gpt_4_turbo$RC1 + 0.38 #rescale RC1 following WVS's procedure
general_coordinate_gpt_4_turbo$RC2 = 1.61 * general_coordinate_gpt_4_turbo$RC2 - 0.01 #rescale RC2 following WVS's procedure

general_gpt$RC1[general_gpt$model == 'GPT-4-turbo'] = mean(general_coordinate_gpt_4_turbo$RC1) #calculate the mean of RC1 across all the prompt variants as the x-coordinate of GPT-4 Turbo's default cultural values
general_gpt$RC2[general_gpt$model == 'GPT-4-turbo'] = mean(general_coordinate_gpt_4_turbo$RC2) #calculate the mean of RC2 across all the prompt variants as the y-coordinate of GPT-4 Turbo's default cultural values


###GPT-4o-2024-05-13###
general_gpt_4o = read.csv("../Analysis_Part1_Default_Cultural_Values-archive/S4_WideTable_Part1_scores_gpt-4o-2024-05-13.csv")

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



