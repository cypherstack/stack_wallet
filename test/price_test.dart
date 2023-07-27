import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:http/http.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/services/price.dart';

import 'price_test.mocks.dart';

@GenerateMocks([Client])
void main() {
  setUp(() async {
    await setUpTestHive();
    await Hive.openBox<dynamic>(DB.boxNamePriceCache);
    await Hive.openBox<dynamic>(DB.boxNamePrefs);
    await DB.instance.put<dynamic>(
        boxName: DB.boxNamePrefs, key: "externalCalls", value: true);
  });

  test("getPricesAnd24hChange fetch", () async {
    final client = MockClient();

    when(client.get(
        Uri.parse(
            "https://api.coingecko.com/api/v3/coins/markets?vs_currency=btc&ids"
            "=monero,bitcoin,litecoin,ecash,epic-cash,zcoin,dogecoin,bitcoin-cash"
            ",namecoin,wownero,ethereum,particl,nano,banano,stellar&order=market_cap_desc&per_page=50"
            "&page=1&sparkline=false"),
        headers: {
          'Content-Type': 'application/json'
        })).thenAnswer((_) async => Response(
        '[{"id":"bitcoin","symbol":"btc","name":"Bitcoin","image":"https://asse'
        'ts.coingecko.com/coins/images/1/large/bitcoin.png?1547033579","curr'
        'ent_price":1.0,"market_cap":19128800,"market_cap_rank":1,"fully_dil'
        'uted_valuation":21000000,"total_volume":1272132,"high_24h":1.0,"low'
        '_24h":1.0,"price_change_24h":0.0,"price_change_percentage_24h":0.0,'
        '"market_cap_change_24h":950.0,"market_cap_change_percentage_24h":0.0'
        '0497,"circulating_supply":19128800.0,"total_supply":21000000.0,"max'
        '_supply":21000000.0,"ath":1.003301,"ath_change_percentage":-0.32896'
        ',"ath_date":"2019-10-15T16:00:56.136Z","atl":0.99895134,"atl_change_'
        'percentage":0.10498,"atl_date":"2019-10-21T00:00:00.000Z","roi":nul'
        'l,"last_updated":"2022-08-22T16:37:59.237Z"},{"id":"dogecoin","symb'
        'ol":"doge","name":"Dogecoin","image":"https://assets.coingecko.com/'
        'coins/images/5/large/dogecoin.png?1547792256","current_price":3.15e'
        '-06,"market_cap":417916,"market_cap_rank":10,"fully_diluted_valuati'
        'on":null,"total_volume":27498,"high_24h":3.26e-06,"low_24h":3.13e-0'
        '6,"price_change_24h":-8.6889947714e-08,"price_change_percentage_24h'
        '":-2.68533,"market_cap_change_24h":-11370.894861206936,"market_cap_c'
        'hange_percentage_24h":-2.64879,"circulating_supply":132670764299.89'
        '4,"total_supply":null,"max_supply":null,"ath":1.264e-05,"ath_change'
        '_percentage":-75.05046,"ath_date":"2021-05-07T23:04:53.026Z","atl":'
        '1.50936e-07,"atl_change_percentage":1989.69346,"atl_date":"2020-12-'
        '17T09:18:05.654Z","roi":null,"last_updated":"2022-08-22T16:38:15.11'
        '3Z"},{"id":"monero","symbol":"xmr","name":"Monero","image":"https:/'
        '/assets.coingecko.com/coins/images/69/large/monero_logo.png?1547033'
        '729","current_price":0.00717236,"market_cap":130002,"market_cap_ran'
        'k":29,"fully_diluted_valuation":null,"total_volume":4901,"high_24h":'
        '0.00731999,"low_24h":0.00707511,"price_change_24h":-5.6133543212467'
        'e-05,"price_change_percentage_24h":-0.77656,"market_cap_change_24h"'
        ':-1007.8447677436197,"market_cap_change_percentage_24h":-0.76929,"c'
        'irculating_supply":18147820.3764146,"total_supply":null,"max_supply'
        '":null,"ath":0.03475393,"ath_change_percentage":-79.32037,"ath_date'
        '":"2018-01-09T00:00:00.000Z","atl":0.00101492,"atl_change_percentag'
        'e":608.13327,"atl_date":"2014-12-18T00:00:00.000Z","roi":null,"las'
        't_updated":"2022-08-22T16:38:26.347Z"},{"id":"zcoin","symbol":"firo'
        '","name":"Firo","image":"https://assets.coingecko.com/coins/images/'
        '479/large/firocoingecko.png?1636537544","current_price":0.0001096,"'
        'market_cap":1252,"market_cap_rank":604,"fully_diluted_valuation":234'
        '9,"total_volume":90.573,"high_24h":0.00011148,"low_24h":0.00010834,'
        '"price_change_24h":-9.87561775002e-07,"price_change_percentage_24h'
        '":-0.89304,"market_cap_change_24h":-10.046635178462793,"market_cap_'
        'change_percentage_24h":-0.79578,"circulating_supply":11411043.83546'
        '97,"total_supply":21400000.0,"max_supply":21400000.0,"ath":0.016162'
        '72,"ath_change_percentage":-99.3208,"ath_date":"2018-04-04T16:04:48.'
        '408Z","atl":4.268e-05,"atl_change_percentage":157.22799,"atl_date":"'
        '2022-05-12T07:28:47.088Z","roi":null,"last_updated":"2022-08-22T16'
        ':38:47.229Z"},{"id":"epic-cash","symbol":"epic","name":"Epic Cash",'
        '"image":"https://assets.coingecko.com/coins/images/9520/large/Epic_C'
        'oin_NO_drop_shadow.png?1620122642","current_price":2.803e-05,"marke'
        't_cap":415.109,"market_cap_rank":953,"fully_diluted_valuation":null'
        ',"total_volume":0.2371557,"high_24h":3.053e-05,"low_24h":2.581e-05'
        ',"price_change_24h":1.9e-06,"price_change_percentage_24h":7.27524,"'
        'market_cap_change_24h":28.26753,"market_cap_change_percentage_24h":'
        '7.30726,"circulating_supply":14808052.0,"total_supply":21000000.0,"'
        'max_supply":null,"ath":0.00013848,"ath_change_percentage":-79.75864'
        ',"ath_date":"2021-12-11T08:39:41.129Z","atl":5.74028e-07,"atl_chang'
        'e_percentage":4783.08078,"atl_date":"2020-03-13T16:55:01.177Z","roi'
        '":null,"last_updated":"2022-08-22T16:38:32.826Z"}]',
        200));

    final priceAPI = PriceAPI(client);
    priceAPI.resetLastCalledToForceNextCallToUpdateCache();

    final price = await priceAPI.getPricesAnd24hChange(baseCurrency: "btc");

    expect(
      price.toString(),
      '{'
      'Coin.bitcoin: [1, 0.0], '
      'Coin.monero: [0.00717236, -0.77656], '
      'Coin.banano: [0, 0.0], '
      'Coin.bitcoincash: [0, 0.0], '
      'Coin.dogecoin: [0.00000315, -2.68533], '
      'Coin.eCash: [0, 0.0], '
      'Coin.epicCash: [0.00002803, 7.27524], '
      'Coin.ethereum: [0, 0.0], '
      'Coin.firo: [0.0001096, -0.89304], '
      'Coin.litecoin: [0, 0.0], '
      'Coin.namecoin: [0, 0.0], '
      'Coin.nano: [0, 0.0], '
      'Coin.particl: [0, 0.0], '
      'Coin.stellar: [0, 0.0], '
      'Coin.wownero: [0, 0.0], '
      'Coin.bitcoinTestNet: [0, 0.0], '
      'Coin.bitcoincashTestnet: [0, 0.0], '
      'Coin.dogecoinTestNet: [0, 0.0], '
      'Coin.firoTestNet: [0, 0.0], '
      'Coin.litecoinTestNet: [0, 0.0], '
      'Coin.stellarTestnet: [0, 0.0]'
      '}',
    );
    verify(client.get(
        Uri.parse(
          "https://api.coingecko.com/api/v3/coins/markets?vs_currency=btc"
          "&ids=monero,bitcoin,litecoin,ecash,epic-cash,zcoin,dogecoin,"
          "bitcoin-cash,namecoin,wownero,ethereum,particl,nano,banano,stellar"
          "&order=market_cap_desc&per_page=50&page=1&sparkline=false",
        ),
        headers: {'Content-Type': 'application/json'})).called(1);

    verifyNoMoreInteractions(client);
  });

  test("cached price fetch", () async {
    final client = MockClient();

    when(client.get(
        Uri.parse(
            "https://api.coingecko.com/api/v3/coins/markets?vs_currency=btc&"
            "ids=monero,bitcoin,litecoin,ecash,epic-cash,zcoin,dogecoin,"
            "bitcoin-cash,namecoin,wownero,ethereum,particl,nano,banano,stellar"
            "&order=market_cap_desc&per_page=50&page=1&sparkline=false"),
        headers: {
          'Content-Type': 'application/json'
        })).thenAnswer((_) async => Response(
        '[{"id":"bitcoin","symbol":"btc","name":"Bitcoin","image":"https://a'
        'ssets.coingecko.com/coins/images/1/large/bitcoin.png?1547033579","c'
        'urrent_price":1.0,"market_cap":19128800,"market_cap_rank":1,"fully_'
        'diluted_valuation":21000000,"total_volume":1272132,"high_24h":1.0,"'
        'low_24h":1.0,"price_change_24h":0.0,"price_change_percentage_24h":0'
        '.0,"market_cap_change_24h":950.0,"market_cap_change_percentage_24h"'
        ':0.00497,"circulating_supply":19128800.0,"total_supply":21000000.0,"'
        'max_supply":21000000.0,"ath":1.003301,"ath_change_percentage":-0.32'
        '896,"ath_date":"2019-10-15T16:00:56.136Z","atl":0.99895134,"atl_cha'
        'nge_percentage":0.10498,"atl_date":"2019-10-21T00:00:00.000Z","roi"'
        ':null,"last_updated":"2022-08-22T16:37:59.237Z"},{"id":"dogecoin","'
        'symbol":"doge","name":"Dogecoin","image":"https://assets.coingecko.'
        'com/coins/images/5/large/dogecoin.png?1547792256","current_price":3'
        '.15e-06,"market_cap":417916,"market_cap_rank":10,"fully_diluted_val'
        'uation":null,"total_volume":27498,"high_24h":3.26e-06,"low_24h":3.1'
        '3e-06,"price_change_24h":-8.6889947714e-08,"price_change_percentage'
        '_24h":-2.68533,"market_cap_change_24h":-11370.894861206936,"market_'
        'cap_change_percentage_24h":-2.64879,"circulating_supply":1326707642'
        '99.894,"total_supply":null,"max_supply":null,"ath":1.264e-05,"ath_c'
        'hange_percentage":-75.05046,"ath_date":"2021-05-07T23:04:53.026Z","'
        'atl":1.50936e-07,"atl_change_percentage":1989.69346,"atl_date":"202'
        '0-12-17T09:18:05.654Z","roi":null,"last_updated":"2022-08-22T16:38:'
        '15.113Z"},{"id":"monero","symbol":"xmr","name":"Monero","image":"ht'
        'tps://assets.coingecko.com/coins/images/69/large/monero_logo.png?15'
        '47033729","current_price":0.00717236,"market_cap":130002,"market_cap'
        '_rank":29,"fully_diluted_valuation":null,"total_volume":4901,"high'
        '_24h":0.00731999,"low_24h":0.00707511,"price_change_24h":-5.613354'
        '3212467e-05,"price_change_percentage_24h":-0.77656,"market_cap_chan'
        'ge_24h":-1007.8447677436197,"market_cap_change_percentage_24h":-0.7'
        '6929,"circulating_supply":18147820.3764146,"total_supply":null,"ma'
        'x_supply":null,"ath":0.03475393,"ath_change_percentage":-79.32037,"'
        'ath_date":"2018-01-09T00:00:00.000Z","atl":0.00101492,"atl_change_'
        'percentage":608.13327,"atl_date":"2014-12-18T00:00:00.000Z","roi":n'
        'ull,"last_updated":"2022-08-22T16:38:26.347Z"},{"id":"zcoin","symbo'
        'l":"firo","name":"Firo","image":"https://assets.coingecko.com/coins'
        '/images/479/large/firocoingecko.png?1636537544","current_price":0.0'
        '001096,"market_cap":1252,"market_cap_rank":604,"fully_diluted_valu'
        'ation":2349,"total_volume":90.573,"high_24h":0.00011148,"low_24h":0'
        '.00010834,"price_change_24h":-9.87561775002e-07,"price_change_perce'
        'ntage_24h":-0.89304,"market_cap_change_24h":-10.046635178462793,"ma'
        'rket_cap_change_percentage_24h":-0.79578,"circulating_supply":11411'
        '043.8354697,"total_supply":21400000.0,"max_supply":21400000.0,"ath"'
        ':0.01616272,"ath_change_percentage":-99.3208,"ath_date":"2018-04-04'
        'T16:04:48.408Z","atl":4.268e-05,"atl_change_percentage":157.22799,'
        '"atl_date":"2022-05-12T07:28:47.088Z","roi":null,"last_updated":"2'
        '022-08-22T16:38:47.229Z"},{"id":"epic-cash","symbol":"epic","name":"'
        'Epic Cash","image":"https://assets.coingecko.com/coins/images/9520/'
        'large/Epic_Coin_NO_drop_shadow.png?1620122642","current_price":2.80'
        '3e-05,"market_cap":415.109,"market_cap_rank":953,"fully_diluted_val'
        'uation":null,"total_volume":0.2371557,"high_24h":3.053e-05,"low_24h'
        '":2.581e-05,"price_change_24h":1.9e-06,"price_change_percentage_24'
        'h":7.27524,"market_cap_change_24h":28.26753,"market_cap_change_perc'
        'entage_24h":7.30726,"circulating_supply":14808052.0,"total_supply":'
        '21000000.0,"max_supply":null,"ath":0.00013848,"ath_change_percentag'
        'e":-79.75864,"ath_date":"2021-12-11T08:39:41.129Z","atl":5.74028e-0'
        '7,"atl_change_percentage":4783.08078,"atl_date":"2020-03-13T16:55:01'
        '.177Z","roi":null,"last_updated":"2022-08-22T16:38:32.826Z"}]',
        200));

    final priceAPI = PriceAPI(client);
    priceAPI.resetLastCalledToForceNextCallToUpdateCache();

    // initial fetch to fill cache
    await priceAPI.getPricesAnd24hChange(baseCurrency: "btc");

    // now this time it should grab from cache instead of http.get
    final cachedPrice =
        await priceAPI.getPricesAnd24hChange(baseCurrency: "btc");

    expect(
      cachedPrice.toString(),
      '{'
      'Coin.bitcoin: [1, 0.0], '
      'Coin.monero: [0.00717236, -0.77656], '
      'Coin.banano: [0, 0.0], Coin.bitcoincash: [0, 0.0], '
      'Coin.dogecoin: [0.00000315, -2.68533], '
      'Coin.eCash: [0, 0.0], '
      'Coin.epicCash: [0.00002803, 7.27524], Coin.ethereum: [0, 0.0], '
      'Coin.firo: [0.0001096, -0.89304], '
      'Coin.litecoin: [0, 0.0], '
      'Coin.namecoin: [0, 0.0], '
      'Coin.nano: [0, 0.0], Coin.particl: [0, 0.0], Coin.stellar: [0, 0.0], '
      'Coin.wownero: [0, 0.0], '
      'Coin.bitcoinTestNet: [0, 0.0], '
      'Coin.bitcoincashTestnet: [0, 0.0], Coin.dogecoinTestNet: [0, 0.0], '
      'Coin.firoTestNet: [0, 0.0], '
      'Coin.litecoinTestNet: [0, 0.0], '
      'Coin.stellarTestnet: [0, 0.0]'
      '}',
    );

    // verify only called once during filling of cache
    verify(client.get(
        Uri.parse(
            "https://api.coingecko.com/api/v3/coins/markets?vs_currency=btc&ids"
            "=monero,bitcoin,litecoin,ecash,epic-cash,zcoin,dogecoin,"
            "bitcoin-cash,namecoin,wownero,ethereum,particl,nano,banano,stellar"
            "&order=market_cap_desc&per_page=50&page=1&sparkline=false"),
        headers: {'Content-Type': 'application/json'})).called(1);

    verifyNoMoreInteractions(client);
  });

  test("response parse failure", () async {
    final client = MockClient();

    when(client.get(
        Uri.parse(
            "https://api.coingecko.com/api/v3/coins/markets?vs_currency=btc"
            "&ids=monero,bitcoin,litecoin,ecash,epic-cash,zcoin,dogecoin,"
            "bitcoin-cash,namecoin,wownero,ethereum,particl,nano,banano,stellar"
            "&order=market_cap_desc&per_page=50&page=1&sparkline=false"),
        headers: {
          'Content-Type': 'application/json'
        })).thenAnswer((_) async => Response(
        '[{"id":"bitcoin","symbol":"btc","name":com/coins/images/1/large/'
        'bitcoin.png?1547033579","current_price":1.0,"market_cap":19128800'
        ',"market_cap_rank":1,"fully_diluted_valuation":21000000,"total_volum'
        'e":1272132,"high_24h":1.0,"low_24h":1.0,"price_change_24h":0.0,"pri'
        'ce_change_percentage_24h":0.0,"market_cap_change_24h":950.0,"market_'
        'cap_change_percentage_24h":0.00497,"circulating_supply":19128800.0,"t'
        'otal_supply":21000000.0,"max_supply":21000000.0,"ath":1.003301,"ath'
        '_change_percentage":-0.32896,"ath_date":"2019-10-15T16:00:56.136Z",'
        '"atl":0.99895134,"atl_change_percentage":0.10498,"atl_date":'
        '"2019-10-21T00:00:00.000Z","roi":null,'
        '"last_updated":"2022-08-22T16:37:59.237Z"},{"id":"dogecoin"'
        ',"symbol":"doge","name":"Dogecoin","image":'
        '"https://assets.coingecko.com/coins/images/5/large/dogecoin.png?1547792256",'
        '"current_price":3.15e-06,"market_cap":417916,"market_cap_rank":10'
        ',"fully_diluted_valuation":null,"total_volume":27498,"high_24h":3'
        '.26e-06,"low_24h":3.13e-06,"price_change_24h":-8.6889947714e-08,"'
        'price_change_percentage_24h":-2.68533,"market_cap_change_24h":-11'
        '370.894861206936,"market_cap_change_percentage_24h":-2.64879,"cir'
        'culating_supply":132670764299.894,"total_supply":null,"max_supply'
        '":null,"ath":1.264e-05,"ath_change_percentage":-75.05046,"ath_date'
        '":"2021-05-07T23:04:53.026Z","atl":1.50936e-07,"atl_change_percen'
        'tage":1989.69346,"atl_date":"2020-12-17T09:18:05.654Z","roi":null,'
        '"last_updated":"2022-08-22T16:38:15.113Z"},{"id":"monero","symbol"'
        ':"xmr","name":"Monero","image":"https://assets.coingecko.com/coins'
        '/images/69/large/monero_logo.png?1547033729","current_price":0.007'
        '17236,"market_cap":130002,"market_cap_rank":29,"fully_diluted_valu'
        'ation":null,"total_volume":4901,"high_24h":0.00731999,"low_24h":0.'
        '00707511,"price_change_24h":-5.6133543212467e-05,"price_change_per'
        'centage_24h":-0.77656,"market_cap_change_24h":-1007.8447677436197'
        ',"market_cap_change_percentage_24h":-0.76929,"circulating_supply":'
        '18147820.3764146,"total_supply":null,"max_supply":null,"ath":0.034'
        '75393,"ath_change_percentage":-79.32037,"ath_date":"2018-01-09T00:'
        '00:00.000Z","atl":0.00101492,"atl_change_percentage":608.13327,"at'
        'l_date":"2014-12-18T00:00:00.000Z","roi":null,"last_updated":"2022'
        '-08-22T16:38:26.347Z"},{"id":"zcoin","symbol":"firo","name":"Firo"'
        ',"image":"https://assets.coingecko.com/coins/images/479/large/firo'
        'coingecko.png?1636537544","current_price":0.0001096,"market_cap":1'
        '252,"market_cap_rank":604,"fully_diluted_valuation":2349,"total_vo'
        'lume":90.573,"high_24h":0.00011148,"low_24h":0.00010834,"price_chang'
        'e_24h":-9.87561775002e-07,"price_change_percentage_24h":-0.89304,'
        '"market_cap_change_24h":-10.046635178462793,"market_cap_change_per'
        'centage_24h":-0.79578,"circulating_supply":11411043.8354697,"tota'
        'l_supply":21400000.0,"max_supply":21400000.0,"ath":0.01616272,"ath'
        '_change_percentage":-99.3208,"ath_date":"2018-04-04T16:04:48.408Z"'
        ',"atl":4.268e-05,"atl_change_percentage":157.22799,"atl_date":"202'
        '2-05-12T07:28:47.088Z","roi":null,"last_updated":"2022-08-22T16:3'
        '8:47.229Z"},{"id":"epic-cash","symbol":"epic","name":"Epic Cash",'
        '"image":"https://assets.coingecko.com/coins/images/9520/large/'
        'Epic_Coin_NO_drop_shadow.png?1620122642","current_price":2.803e-0'
        '5,"market_cap":415.109,"market_cap_rank":953,"fully_diluted_valuat'
        'ion":null,"total_volume":0.2371557,"high_24h":3.053e-05,"low_24h":'
        '2.581e-05,"price_change_24h":1.9e-06,"price_change_percentage_24h"'
        ':7.27524,"market_cap_change_24h":28.26753,"market_cap_change_per'
        'centage_24h":7.30726,"circulating_supply":14808052.0,"total_suppl'
        'y":21000000.0,"max_supply":null,"ath":0.00013848,"ath_change_perce'
        'ntage":-79.75864,"ath_date":"2021-12-11T08:39:41.129Z","atl":5.74'
        '028e-07,"atl_change_percentage":4783.08078,"atl_date":"2020-03-13T'
        '16:55:01.177Z","roi":null,"last_updated":"2022-08-22T16:38:32.826Z"}]',
        200));

    final priceAPI = PriceAPI(client);
    priceAPI.resetLastCalledToForceNextCallToUpdateCache();

    final price = await priceAPI.getPricesAnd24hChange(baseCurrency: "btc");

    expect(
      price.toString(),
      '{'
      'Coin.bitcoin: [0, 0.0], Coin.monero: [0, 0.0], '
      'Coin.banano: [0, 0.0], '
      'Coin.bitcoincash: [0, 0.0], '
      'Coin.dogecoin: [0, 0.0], '
      'Coin.eCash: [0, 0.0], '
      'Coin.epicCash: [0, 0.0], '
      'Coin.ethereum: [0, 0.0], '
      'Coin.firo: [0, 0.0], '
      'Coin.litecoin: [0, 0.0], '
      'Coin.namecoin: [0, 0.0], '
      'Coin.nano: [0, 0.0], '
      'Coin.particl: [0, 0.0], '
      'Coin.stellar: [0, 0.0], '
      'Coin.wownero: [0, 0.0], '
      'Coin.bitcoinTestNet: [0, 0.0], '
      'Coin.bitcoincashTestnet: [0, 0.0], '
      'Coin.dogecoinTestNet: [0, 0.0], '
      'Coin.firoTestNet: [0, 0.0], '
      'Coin.litecoinTestNet: [0, 0.0], '
      'Coin.stellarTestnet: [0, 0.0]'
      '}',
    );
  });

  test("no internet available", () async {
    final client = MockClient();

    when(client.get(
        Uri.parse(
            "https://api.coingecko.com/api/v3/coins/markets?vs_currency=btc"
            "&ids=monero,bitcoin,litecoin,ecash,epic-cash,zcoin,dogecoin,"
            "bitcoin-cash,namecoin,wownero,ethereum,particl,nano,banano,stellar"
            "&order=market_cap_desc&per_page=50&page=1&sparkline=false"),
        headers: {
          'Content-Type': 'application/json'
        })).thenThrow(const SocketException(
        "Failed host lookup: 'api.com' (OS Error: Temporary failure in name resolution, errno = -3)"));

    final priceAPI = PriceAPI(client);
    priceAPI.resetLastCalledToForceNextCallToUpdateCache();

    final price = await priceAPI.getPricesAnd24hChange(baseCurrency: "btc");

    expect(
      price.toString(),
      '{'
      'Coin.bitcoin: [0, 0.0], '
      'Coin.monero: [0, 0.0], '
      'Coin.banano: [0, 0.0], '
      'Coin.bitcoincash: [0, 0.0], '
      'Coin.dogecoin: [0, 0.0], '
      'Coin.eCash: [0, 0.0], '
      'Coin.epicCash: [0, 0.0], '
      'Coin.ethereum: [0, 0.0], '
      'Coin.firo: [0, 0.0], '
      'Coin.litecoin: [0, 0.0], '
      'Coin.namecoin: [0, 0.0], '
      'Coin.nano: [0, 0.0], '
      'Coin.particl: [0, 0.0], '
      'Coin.stellar: [0, 0.0], '
      'Coin.wownero: [0, 0.0], '
      'Coin.bitcoinTestNet: [0, 0.0], '
      'Coin.bitcoincashTestnet: [0, 0.0], '
      'Coin.dogecoinTestNet: [0, 0.0], '
      'Coin.firoTestNet: [0, 0.0], '
      'Coin.litecoinTestNet: [0, 0.0], '
      'Coin.stellarTestnet: [0, 0.0]'
      '}',
    );
  });

  tearDown(() async {
    await tearDownTestHive();
  });
}
