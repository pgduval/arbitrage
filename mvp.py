import requests
import lxml.etree as etree
import csv
import os
import datetime


def get_forex_feed(symbol="USDCAD"):
    r = requests.get('https://rates.fxcm.com/RatesXML')
    treeobj = etree.fromstring(r.content)
    rate = treeobj.find(".//*[@Symbol='{}']".format(symbol))
    bid = float(rate.find(".//Bid").text)
    ask = float(rate.find(".//Ask").text)
    return bid, ask


def get_quad_feed():
    r = requests.get("https://api.quadrigacx.com/v2/ticker?book=btc_cad")
    rjson = r.json()
    bid = float(rjson['bid'])
    ask = float(rjson['ask'])
    return bid, ask


def get_krak_feed():
    params = {'pair': 'XXBTZUSD'}
    r = requests.get("https://api.kraken.com/0/public/Ticker", params=params)
    rjson = r.json()
    bid = float(rjson['result']['XXBTZUSD']['b'][0])
    ask = float(rjson['result']['XXBTZUSD']['a'][0])
    return bid, ask


def write_list_to_csv(data):
    with open(OUTPUT_FILE, "a") as f:
        writer = csv.writer(f)
        writer.writerow(data)


def arbitrage(fb, qa, kb):

    # qa = quad_ask
    # kb = krak_bid
    # fb = forex_bid

    # I buy a bitcoin at the ask of Quad
    spending = qa + (qa * 0.005)
    qa_fees = (qa * 0.005)
    # I sell it at the bid of Kraken
    revenu = kb - (kb * 0.0026)
    kr_fees = (kb * 0.0026)

    # Revenus are in US so i convert them back to CAD
    revenu_cad = revenu * fb

    profit = revenu_cad - spending
    nofee = (kb * fb) - qa
    print("\n --- Arbitrage Results --")
    print("Spending QA : {} + {} = {}".format(qa, qa_fees, spending))
    print("Revenu Kraken : {} - {} = {}".format(kb * fb, kr_fees * fb, revenu_cad))
    print("Profit: {} - {} = {}".format(revenu_cad, spending, profit))
    print("No fees Profit: {} - {} = {}".format((kb * fb), qa, nofee))
    print("-------")


try:
    DIR_PATH = os.path.dirname(os.path.realpath(__file__))
except:
    DIR_PATH = '/home/elmaster/scraper/bitcoin/arbitrage/'

OUTPUT_FILE = os.path.join(DIR_PATH, 'output', 'data.csv')

forex_bid, forex_ask = get_forex_feed()
quad_bid, quad_ask = get_quad_feed()
krak_bid, krak_ask = get_krak_feed()

timestamp = datetime.datetime.now()

write_list_to_csv([timestamp, forex_bid, forex_ask, quad_bid, quad_ask, krak_bid, krak_ask])
