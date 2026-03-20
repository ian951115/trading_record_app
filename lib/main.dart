import 'package:flutter/material.dart';
import 'package:trading_record_app/models/cash_flow.dart';
import 'package:trading_record_app/models/trade.dart';
import 'package:trading_record_app/models/dividend.dart';
import 'package:trading_record_app/repositories/cash_flow_repository.dart';
import '../screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'repositories/trade_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); //初始化hive

  Hive.registerAdapter(TradeAdapter());
  Hive.registerAdapter(TradeTypeAdapter());
  Hive.registerAdapter(AssetTypeAdapter());
  Hive.registerAdapter(CashFlowTypeAdapter());
  Hive.registerAdapter(CashFlowAdapter());
  Hive.registerAdapter(DividendAdapter());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TradeRepository(),
        ),
        ChangeNotifierProvider(
          create: (_) => CashFlowRepository(),
        ),
      ],
      child: const TradingRecordApp(),
    ),
  );
}

class TradingRecordApp extends StatelessWidget {
  const TradingRecordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '交易紀錄',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    // ── 色彩定義 ──────────────────────────────
    const primary      = Color(0xFF4A6FA5);
    const primaryDark  = Color(0xFF3D5A8A);
    const primaryLight = Color(0xFFEBF0F8);
    const scaffoldBg   = Color(0xFFF0F2F5);
    const surfaceColor = Color(0xFFFFFFFF);
    const borderColor  = Color(0xFFE4E7ED);
    const textPrimary  = Color(0xFF1A1F2E);
    const textSecond   = Color(0xFF5A6375);
    const textMuted    = Color(0xFF9AA3B2);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surfaceColor,
      ),

      // ── Scaffold 背景 ──────────────────────
      scaffoldBackgroundColor: scaffoldBg,

      // ── AppBar ────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        shape: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),

      // ── Card ──────────────────────────────
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── 輸入欄位 ──────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        hintStyle: const TextStyle(
          color: textMuted,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE8504A)),
        ),
      ),

      // ── ElevatedButton ────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── FloatingActionButton ──────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),

      // ── Divider ───────────────────────────
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // ── 文字樣式 ──────────────────────────
      textTheme: const TextTheme(
        // 頁面大標題
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        // 卡片標題
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        // 一般內文
        bodyMedium: TextStyle(
          fontSize: 13,
          color: textSecond,
        ),
        // 小標籤
        bodySmall: TextStyle(
          fontSize: 11,
          color: textMuted,
        ),
      ),
    );
  }
}