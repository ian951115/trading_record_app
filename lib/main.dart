import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import '/models/custom_goal.dart';
import 'models/cash_flow.dart';
import 'models/trade.dart';
import 'models/dividend.dart';
import 'models/app_settings.dart';
import 'models/recurring_plan.dart';
import 'models/annual_goal.dart';
import 'repositories/cash_flow_repository.dart';
import 'repositories/trade_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/dividend_repository.dart';
import 'repositories/recurring_repository.dart';
import 'repositories/annual_goal_repository.dart';
import 'repositories/custom_goal_repository.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_TW');
  await Hive.initFlutter(); //初始化hive

  // ── Adapter 註冊 ──────────────────────────────
  Hive.registerAdapter(TradeAdapter());
  Hive.registerAdapter(TradeTypeAdapter());
  Hive.registerAdapter(AssetTypeAdapter());
  Hive.registerAdapter(CashFlowTypeAdapter());
  Hive.registerAdapter(CashFlowAdapter());
  Hive.registerAdapter(DividendAdapter());
  Hive.registerAdapter(DividendTypeAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(RecurringFrequencyAdapter());
  Hive.registerAdapter(RecurringPlanAdapter());
  Hive.registerAdapter(AnnualGoalAdapter());
  Hive.registerAdapter(CustomGoalAdapter());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TradeRepository(),
        ),
        ChangeNotifierProvider(
          create: (_) => CashFlowRepository(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsRepository(),
        ),
        ChangeNotifierProvider(
          create: (_) => DividendRepository(),
        ),
        ChangeNotifierProvider(
          create: (_) => RecurringRepository(),
        ),
        ChangeNotifierProvider(
          create: (_) => AnnualGoalRepository(),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomGoalRepository(),
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
          borderSide: const BorderSide(
            color: Color(0xFFE4E7ED),
            width: 1,
          ),
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