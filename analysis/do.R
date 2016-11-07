library(dplyr)
library(reshape)
library(ggplot2)

setwd('/home/itman/scraper/arbitrage')

data = read.csv('./output/data.csv', header=FALSE)
names(data) = c('timestamp', 'usdcad_bid', 'usdcad_ask', 'btccad_bid', 'btccad_ask', 'btcusd_bid', 'btcusd_ask')
data$timestamp = as.POSIXct(strptime(data$timestamp, "%Y-%m-%d %H:%M:%S"), origin="1970-01-01")

fee_cad = 0.005
fee_usd = 0.0025

data2 = data %>%
        mutate(spending_gross = btccad_ask,
               spending_fees = (btccad_ask * fee_cad),
               spending_net = spending_gross + spending_fees,
               revenu_gross = btcusd_bid * usdcad_bid,
               revenu_fees = (btcusd_bid * fee_usd)*usdcad_bid,
               revenu_net = revenu_gross - revenu_fees,
               profit = revenu_net - spending_net) %>%
        arrange(timestamp)


# Reverse trade
# 1 - Take USD and buy BTC at the btcusd_ask
# 2 - Sell this bitcoin at the btccad_bid
data3 = data %>%
        mutate(spending_gross = btcusd_ask * usdcad_bid,
               spending_fees = (btcusd_ask * fee_usd) * usdcad_bid,
               spending_net = spending_gross + spending_fees,
               revenu_gross = btccad_bid,
               revenu_fees = (btccad_bid * fee_cad),
               revenu_net = revenu_gross - revenu_fees,
               profit = revenu_net - spending_net) %>%
        arrange(timestamp)

cadtousd = melt(data2, id=c('timestamp'))
cadtousd$type = 'cad_to_usd'
usdtocad = melt(data3, id=c('timestamp'))
usdtocad$type = 'usd_to_cad'

graphdata = rbind(cadtousd, usdtocad)
# graphdata = filter(graphdata, variable %in% c('spending_gross', 'spending_net', 'revenu_gross', 'revenu_net'))
graphdata = filter(graphdata, variable %in% c('spending_net', 'revenu_net'))

ggplot(graphdata, aes(x=timestamp, y=value, color=variable)) +
 geom_line() +
 facet_grid(. ~ type) +
 theme_bw() +
 theme(legend.position="bottom", 
       axis.text.x = element_text(angle = 90, hjust = 1))



ret = data2 %>%
      filter(profit>=0) %>%
      summarize(n_trade = n(), 
                sum_profit = sum(profit),
                mean_profit = mean(profit))

ret

ggplot(data2, aes(x=timestamp, y=profit)) +
 geom_line()  +
 geom_hline(yintercept=0)



data2 %>%
  filter(profit>=0) %>%
  ggplot(aes(x=profit)) + 
  geom_density()



head(data3)
ltime = list()
flag = 0
for (i in 1:nrow(data2)){
    if (data2$profit[i] > 0 & flag == 0) {
        flag = 1
        start = data2$timestamp[i]
    } 
    if (data2$profit[i] < 0 & flag == 1) {
        end = data2$timestamp[i]
        ltime[[length(ltime)+1]] = list(start, end)
        flag = 0
    }
}

lduration = list()
for (i in 1:length(ltime)){
    val = ltime[[i]]
    lduration[length(lduration)+1] = difftime(val[[2]], val[[1]], units='min')
}

dduration = do.call(rbind.data.frame, lduration)
names(dduration) = c('time')

plot(hist(dduration$time))
summary(dduration$time)
