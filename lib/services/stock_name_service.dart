//股票名稱查詢服務(台灣證交所)
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/stock_data.dart';

class StockNameService {
  // 記憶體快取，key = 股票代碼，value = 中文名稱
  static Map<String, String> _cache = {};
  static bool _loaded = false;

  // App 啟動時呼叫一次，失敗也沒關係（會用 fallback）
  static Future<void> init() async {
    try {
      await Future.wait([_loadTWSE(), _loadTPEx()]);
      _loaded = true;
    } catch (_) {
      // 網路失敗就靠 fallback map
    }
  }

  // 查名稱（主要對外接口，取代原本的 fetchName）
  static String? getName(String symbol) {
    return _cache[symbol] ?? stockFallbackMap[symbol];
  }

  // 拉上市股票（台灣證交所）
  static Future<void> _loadTWSE() async {
    final url = Uri.parse(
      'https://openapi.twse.com.tw/v1/exchangeReport/STOCK_DAY_ALL',
    );
    final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
    if (res.statusCode != 200) return;
    final list = jsonDecode(res.body) as List;
    for (final item in list) {
      final code = item['Code'] as String?;
      final name = item['Name'] as String?;
      if (code != null && name != null) _cache[code] = name;
    }
  }

  // 拉上櫃股票（TPEx）
  static Future<void> _loadTPEx() async {
    final url = Uri.parse(
      'https://www.tpex.org.tw/openapi/v1/tpex_mainboard_quotes',
    );
    final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
    if (res.statusCode != 200) return;
    final list = jsonDecode(res.body) as List;
    for (final item in list) {
      final code = item['SecuritiesCompanyCode'] as String?;
      final name = item['CompanyName'] as String?;
      if (code != null && name != null) _cache[code] = name;
    }
  }
}