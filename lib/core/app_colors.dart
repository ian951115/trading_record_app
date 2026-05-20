//全域色彩常數與損益顏色輔助函式
import 'package:flutter/material.dart';

class AppColors {
  // ── 主色系 ────────────────────────────────
  static const primary      = Color(0xFF4A6FA5);
  static const primaryDark  = Color(0xFF3D5A8A);
  static const primaryLight = Color(0xFFEBF0F8);

  // ── 背景 / 表面 ───────────────────────────
  static const scaffoldBg   = Color(0xFFF0F2F5);
  static const cardBg       = Color(0xFFF0F2F7);
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceAlt   = Color(0xFFF8F9FC);
  static const border       = Color(0xFFE4E7ED);

  // ── 文字 ──────────────────────────────────
  static const textPrimary  = Color(0xFF1A1F2E);
  static const textSecond   = Color(0xFF5A6375);
  static const textMuted    = Color(0xFF9AA3B2);

  // ── 損益顏色（台灣：紅漲綠跌）────────────
  static const profit       = Color(0xFFE8504A); // 紅
  static const loss         = Color(0xFF3D9E6B); // 綠
  static const neutral      = Color(0xFF9AA3B2); // 灰（零值）

  // ── 損益背景色 ────────────────────────────
  static const profitBg     = Color(0xFFFDF0EF);
  static const profitBorder = Color(0xFFF5C4C2);
  static const lossBg       = Color(0xFFEEF7F2);
  static const lossBorder   = Color(0xFFB8DFC9);

  // ── 損益背景色（稍深，日曆格子等需明顯區別的場景）
  static const profitBgStrong = Color(0xFFF9D8D6);
  static const lossBgStrong   = Color(0xFFD4EEE2);

  /// 根據數值與顏色模式回傳損益顏色
  /// [redUpGreenDown] 對應 AppSettings.redUpGreenDown，預設 true（台灣慣例）
  static Color pnlColor(double value, {bool redUpGreenDown = true}) {
    if (value == 0) return neutral;
    final isProfit = value > 0;
    // redUpGreenDown=true：正值→紅，負值→綠
    return (isProfit == redUpGreenDown) ? profit : loss;
  }

  /// pnlColor 的簡化版（不需要顏色設定時使用，固定台灣慣例）
  static Color pnl(double value) => pnlColor(value);
}