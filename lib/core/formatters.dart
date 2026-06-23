// 全域格式化工具
import 'package:intl/intl.dart';

class AppFmt {
  // ── 數字格式化 ────────────────────────────
  static final _comma = NumberFormat('#,###');

  /// 整數千分位，例：1234567 → "1,234,567"
  static String num(double value) => _comma.format(value.toInt());

  /// 帶正負號的損益，例：1234 → "+1,234"，-500 → "-500"
  static String pnl(double value) =>
      (value >= 0 ? '+' : '') + _comma.format(value.toInt());

  /// 損益（含小數），用於報酬率等
  static String pnlDecimal(double value, {int digits = 2}) =>
      (value >= 0 ? '+' : '') + value.toStringAsFixed(digits);

  /// 股價格式（最多兩位小數），例：123.50
  static String price(double value) =>
      NumberFormat('#,###.##').format(value);

  /// 緊湊縮寫（空間不足時用），例：
  ///   12_345_678 → \"1,234.6萬\"
  ///   123_456    → \"12.3萬\"
  ///   9_999      → \"9,999\"
  /// 帶正負號版本：pnlCompact()
  static String compact(double value) {
    final abs = value.abs();
    if (abs >= 1e8) {
      return '${(value / 1e8).toStringAsFixed(2)}億';
    } else if (abs >= 1e4) {
      return '${(value / 1e4).toStringAsFixed(1)}萬';
    }
    return _comma.format(value.toInt());
  }

  /// 帶正負號的緊湊縮寫，例：+1,234.6萬
  static String pnlCompact(double value) =>
      (value >= 0 ? '+' : '') + compact(value.abs() * (value < 0 ? -1 : 1));
      

  // ── 日期格式化 ────────────────────────────
  /// yyyy/MM/dd，例：2025/01/07
  static String date(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, "0")}/${d.day.toString().padLeft(2, "0")}';

  /// yyyy/MM，例：2025/01
  static String yearMonth(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, "0")}';
}