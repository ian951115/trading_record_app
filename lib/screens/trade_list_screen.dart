//交易明細頁面UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trading_record_app/repositories/trade_repository.dart';
import '../models/trade.dart';
import '../widgets/trade_filter_bar.dart';
import '../widgets/trade_tile.dart';
import '../screens/add_trade_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TradeListScreen extends StatefulWidget {
  const TradeListScreen({super.key});

  @override
  State<TradeListScreen> createState() => _TradeListScreenState();
}

class _TradeListScreenState extends State<TradeListScreen> {
  String selectedPeriod = 'all';
  DateTimeRange? customRange;

  List<Trade> getFilteredTrades(List<Trade> allTrades) { //時間區間設定
    List<Trade> result;

    if(selectedPeriod == 'all') {
      result = List.from(allTrades);
    } else {
      DateTime start;
      DateTime end = DateTime.now();
      if (selectedPeriod == 'custom' && customRange != null) { //自選
        start = customRange!.start;
        end = customRange!.end;
      } else { //非自選
        final now = DateTime.now();
        switch(selectedPeriod) {
          case '1m':
            start = DateTime(now.year, now.month - 1, now.day);
            break;
          case '6m':
            start = DateTime(now.year, now.month - 6, now.day);
            break;
          case '1y':
            start = DateTime(now.year - 1, now.month, now.day);
            break;
          case '5y':
            start = DateTime(now.year - 5, now.month, now.day);
            break;
          default:
            result = List.from(allTrades);
            result.sort((a, b) => b.date.compareTo(a.date));
            return result;
        }
      }
      result = allTrades.where((t) { //所選時間設定
        return !t.date.isBefore(start) && !t.date.isAfter(end);
      }).toList();
    }
    result.sort((a, b) => b.date.compareTo(a.date)); //選完排序
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<TradeRepository>();
    final allTrades = repository.getAllTrades(); //這兩行需在build裡，才有contxet
    final filteredTrades = getFilteredTrades(allTrades);

    return Scaffold(
      appBar: AppBar(
        title: const Text('交易明細'),
      ),
      floatingActionButton: FloatingActionButton( //新增按鈕
        onPressed: () async {
          final trade = await Navigator.push<Trade>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTradeScreen(),
            ),
          );
          if (trade != null) {
            repository.addTrade(trade);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TradeFilterBar(
            onChanged: (value) {
              setState(() {
                selectedPeriod = value;
              });
            },
            onRangeChanged: (range) {
              setState(() {
                selectedPeriod = 'custom';
                customRange = range;
              });
            },
          ),
          const Divider(height: 1), //分隔線寬
          Expanded(
            child: ListView.separated(
              itemCount: filteredTrades.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4), //_:不會用到此參數
              itemBuilder: (context, index) {
                final trade = filteredTrades[index];
                return Slidable(
                  key: ValueKey(trade.hashCode),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction( //編輯
                        onPressed: (_) async {
                          final updateTrade = await Navigator.push<Trade>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddTradeScreen(editingTrade: trade),
                            ),
                          );
                          if(updateTrade != null) {
                            repository.updateTrade(trade, updateTrade);
                          }
                        },
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                        label: '編輯',
                      ),
                      SlidableAction( //刪除
                        onPressed: (_) async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('刪除交易'),
                              content: const Text('確定要刪除這筆交易嗎?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    '刪除',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if(confirm == true) {
                            repository.removeTrade(trade);
                          }
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: '刪除',
                      ),
                    ],
                  ),
                  child: TradeTile(trade: trade),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}