//股價查詢服務（Yahoo Finance）
import 'dart:convert';
import 'package:http/http.dart' as http;

class StockPriceService {

  //查詢單一股票現價
  static Future<double?> fetchPrice(String symbol) async {
    //台股代碼加上 .TW，例如 2330 → 2330.TW
    final ticker = '${symbol}.TW';
    final url = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/$ticker'
      '?interval=1d&range=1d',
    );

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0' //Yahoo 需要這個不然會擋
      });

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final result = data['chart']['result'];
      if (result == null || result.isEmpty) return null;

      //取最新收盤價
      final meta = result[0]['meta'];
      final price = meta['regularMarketPrice'];
      return (price as num).toDouble();

    } catch (e) {
      return null; //失敗就回傳null，不讓App崩潰
    }
  }

  //批次查詢多檔股票（庫存頁面用）
  static Future<Map<String, double>> fetchPrices(
    List<String> symbols,
  ) async {
    final Map<String, double> result = {};

    //同時發出所有請求（parallel）
    final futures = symbols.map((symbol) async {
      final price = await fetchPrice(symbol);
      if (price != null) result[symbol] = price;
    });

    await Future.wait(futures);
    return result;
  }

  //查詢名稱
  static Future<String?> fetchName(String symbol) async {
    final ticker = '${symbol}.TW';
    final url = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/$ticker'
      '?interval=1d&range=1d&lang=zh-Hant-TW&region=TW',
    );
    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0',
        'Accept-Language': 'zh-TW,zh;q=0.9',
      });
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      final result = data['chart']['result'];
      if (result == null || result.isEmpty) return null;
      final meta = result[0]['meta'];
      // 建議優先用 shortName，若 null 才退回 longName
      final name = meta['shortName'] ?? meta['longName'] ?? meta['symbol'];
      return name as String?;
    } catch (_) {
      return null;
    }
  }

  //查詢歷史收盤價格
  static Future<double?> fetchHistoricalClose(String symbol, DateTime date) async {
    final ticker = '${symbol}.TW';
    final p1 = date.millisecondsSinceEpoch ~/ 1000;
    final url = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/$ticker'
      '?interval=1d&period1=$p1&period2=${p1 + 86400}'
    );

    try {
      final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      final result = data['chart']['result'];
      if (result == null || result.isEmpty) return null;
      final closes = result[0]['indicators']['quote'][0]['close'];
      if (closes == null || closes.isEmpty) return null;
      return (closes[0] as num).toDouble();
    } catch (_) {return null;}
  }
}