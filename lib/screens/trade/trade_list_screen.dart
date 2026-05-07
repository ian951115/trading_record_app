//交易明細頁面UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/add_trade_result.dart';
import '../../models/trade.dart';
import '../../repositories/trade_repository.dart';
import '../../repositories/cash_flow_repository.dart';
import '../../services/calc/position_service.dart';
import '../../widgets/common/stats_strip.dart';
import '../../widgets/trade/trade_tile.dart';
import 'add_trade_screen.dart';

class TradeListScreen extends StatefulWidget {
  const TradeListScreen({super.key});

  @override
  State<TradeListScreen> createState() => _TradeListScreenState();
}

class _TradeListScreenState extends State<TradeListScreen> {
  String selectedPeriod = 'all';
  DateTimeRange? customRange;

  List<Trade> getFilteredTrades(List<Trade> allTrades) { //時間區間篩選
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

  Map<String, dynamic> _calcStats(List<Trade> trades, Map<String, double> pnlMap) { //計算統計數據
    final formatter = NumberFormat('#,###');
    final totalCount = trades.length; //交易筆數
    final totalAmount = trades.fold( //總價金
      0.0, (sum, t) => sum + t.amount,
    );
    final totalPnL = trades //損益
        .where((t) => t.type == TradeType.sell)
        .fold(0.0, (sum, t) => sum + (pnlMap[t.id] ?? 0));
    final totalFee = trades.fold( //交易費用（手續費 + 證交稅）
      0.0, (sum, t) => sum + t.fee + t.tax);
    
    return {
      'count': totalCount.toString(),
      'amount': formatter.format(totalAmount.toInt()),
      'pnl': totalPnL >= 0
          ? '+${formatter.format(totalPnL.toInt())}'
          : formatter.format(totalPnL.toInt()),
      'pnlColor': totalPnL >= 0
          ? const Color(0xFFE8504A)
          : const Color(0xFF3D9E6B),
      'fee': formatter.format(totalFee.toInt()),
    };
  }

  @override
  Widget build(BuildContext context) {
    final tradeRepo = context.watch<TradeRepository>(); //需在build裡才有contxet
    final cashRepo = context.watch<CashFlowRepository>();
    final allTrades = tradeRepo.getAllTrades();
    final filteredTrades = getFilteredTrades(allTrades);
    final pnlMap = buildPositions(allTrades).tradePnLMap;
    final stats = _calcStats(filteredTrades, pnlMap);

    return Scaffold(
      appBar: AppBar(
        title: const Text('交易明細'),
      ),
      body: Column(
        children: [

          // ── 篩選器 ────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: '全部',
                    isActive: selectedPeriod == 'all',
                    onTap: () => setState(() => selectedPeriod = 'all'),
                  ),
                  _FilterChip(
                    label: '近一個月',
                    isActive: selectedPeriod == '1m',
                    onTap: () => setState(() => selectedPeriod = '1m'),
                  ),
                  _FilterChip(
                    label: '近半年',
                    isActive: selectedPeriod == '6m',
                    onTap: () => setState(() => selectedPeriod = '6m'),
                  ),
                  _FilterChip(
                    label: '近一年',
                    isActive: selectedPeriod == '1y',
                    onTap: () => setState(() => selectedPeriod = '1y'),
                  ),
                  _FilterChip(
                    label: '近五年',
                    isActive: selectedPeriod == '5y',
                    onTap: () => setState(() => selectedPeriod = '5y'),
                  ),
                  _FilterChip(
                    label: '自選',
                    isActive: selectedPeriod == 'custom',
                    onTap: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(1961),
                        lastDate: DateTime.now(),
                        initialDateRange: customRange,
                      );
                      if (range != null) {
                        setState(() {
                          selectedPeriod = 'custom';
                          customRange = range;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1), //分隔線寬

          // ── 統計列 ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: StatsStrip(
              cells: [
                StatCell(
                  label: '交易筆數',
                  value: stats['count'],
                ),
                StatCell(
                  label: '總價金',
                  value: stats['amount'],
                ),
                StatCell(
                  label: '損益',
                  value: stats['pnl'],
                  valueColor: stats['pnlColor'],
                ),
                StatCell(
                  label: '交易費用',
                  value: stats['fee'],
                ),
              ],
            ),
          ),

          // ── 交易列表 ──────────────────────
          Expanded(
            child: filteredTrades.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Color(0xFFE4E7ED),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '尚無交易紀錄',
                          style: TextStyle(
                            color: Color(0xFF9AA3B2),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                  itemCount: filteredTrades.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8), //_:不會用到此參數
                  itemBuilder: (context, index) {
                    final trade = filteredTrades[index];
                    return TradeTile(
                      trade: trade,
                      realizedPnL: pnlMap[trade.id],
                      onEdit: () async {
                        final result = await Navigator.push<AddTradeResult>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTradeScreen(editingTrade: trade),
                          ),
                        );
                        if (result != null) {
                          tradeRepo.updateTrade(trade, result.trade);
                        }
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('確認刪除'),
                            content: const Text('確定要刪除這筆交易紀錄？\n此操作無法復原。'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFFE8504A)),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('刪除'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          tradeRepo.removeTrade(trade);
                        }
                      },
                    );
                  },
                ),
          ),
        ],
      ),

      // ── 新增按鈕 ──────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<AddTradeResult>(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTradeScreen(),
            ),
          );
          if (result != null) {
            tradeRepo.addTrade(result.trade);
            if (result.autoDeposit != null) { //同時記錄入金
              cashRepo.addFlow(result.autoDeposit!);
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget { //篩選器Chip
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4A6FA5)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF4A6FA5)
                : const Color(0xFFE4E7ED),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive
                ? Colors.white
                : const Color(0xFF5A6375),
          ),
        ),
      ),
    );
  }
}