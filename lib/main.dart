import 'package:flutter/material.dart';
import 'package:trading_record_app/models/cash_flow.dart';
import 'package:trading_record_app/models/trade.dart';
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
  Hive.registerAdapter(CashFlowTypeAdapter());
  Hive.registerAdapter(CashFlowAdapter());

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
      title: 'Trading Record',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,   //底色
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}