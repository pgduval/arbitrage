library(dplyr)
library(reshape)
library(ggplot2)

setwd('/home/itman/scraper/arbitrage')

data = read.csv('./output/data.csv', header=FALSE)
names(data) = c('timestamp', 'usdcad_bid', 'usdcad_ask', 'btccad_bid', 'btccad_ask', 'btcusd_bid', 'btcusd_ask')
data$timestamp = as.POSIXct(strptime(data$timestamp, "%Y-%m-%d %H:%M:%S"))

fee_cad = 0.005
fee_usd = 0.0025

data2 = data %>%
        mutate(spending = btccad_ask + (btccad_ask * fee_cad),
               revenu = (btcusd_bid - (btcusd_bid * fee_usd))*usdcad_bid,
               profit = revenu - spending)

ggplot(data2, aes(x=timestamp, y=profit)) +
 geom_line() + 
 geom_hline(yintercept=0, color='red') + 
 scale_y_continuous(breaks = c(-15, -10,-5, 0, 5, 10, 15))

ret = data2 %>%
      filter(profit>=0) %>%
      summarize(n_trade = n(), 
                sum_profit = sum(profit),
                mean_profit = mean(profit))

ret

data2 %>%
  filter(profit>=0) %>%
  ggplot(aes(x=profit)) + 
  geom_density()

