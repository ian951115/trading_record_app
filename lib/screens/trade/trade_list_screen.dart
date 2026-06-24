//交易明細頁面UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trading_record_app/models/cash_flow.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../models/add_trade_result.dart';
import '../../models/trade.dart';
import '../../repositories/trade_repository.dart';
import '../../repositories/cash_flow_repository.dart';
import '../../services/calc/position_service.dart';
import '../../widgets/common/app_filter_chip.dart';
import '../../widgets/common/hero_card.dart';
import '../../widgets/common/expanded_actions.dart';
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
      result = allTrades.where((t) => //所選時間設定
        !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
    }
    result.sort((a, b) => b.date.compareTo(a.date)); //選完排序
    return result;
  }

  Map<String, dynamic> _calcStats(List<Trade> trades, Map<String, double> pnlMap) { //計算統計數據
    final totalCount = trades.length; //交易筆數
    final totalAmount = trades.fold(0.0, (sum, t) => sum + t.amount); //總價金
    final totalPnL = trades //損益
        .where((t) => t.type == TradeType.sell)
        .fold(0.0, (sum, t) => sum + (pnlMap[t.id] ?? 0));
    final totalFee = trades.fold( //交易費用
      0.0, (sum, t) => sum + t.fee + t.tax);
    
    return {
      'count': totalCount.toString(),
      'amountRaw': totalAmount,
      'pnl': AppFmt.pnl(totalPnL),
      'pnlColor': AppColors.pnl(totalPnL),
      'feeRaw': totalFee,
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
      appBar: AppBar(title: const Text('交易明細')),
      body: Column(
        children: [
          // ── HeroCard ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: HeroCard(
              title: '已實現損益',
              mainValue: Text(
                stats['pnl'] as String,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: stats['pnlColor'] as Color,
                  letterSpacing: -0.5,
                ),
              ),
              stats: [
                HeroStat(label: '交易筆數', value: stats['count'] as String),
                HeroStat(
                  label: '總價金',
                  value: AppFmt.compact(stats['amountRaw'] as double)
                ),
                HeroStat(
                  label: '交易費用',
                  value: AppFmt.compact(stats['feeRaw'] as double),
                ),
              ],
            ),
          ),

          // ── 篩選器 ────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AppFilterChip(
                    label: '全部',
                    isActive: selectedPeriod == 'all',
                    onTap: () => setState(() => selectedPeriod = 'all'),
                  ),
                  AppFilterChip(
                    label: '近一個月',
                    isActive: selectedPeriod == '1m',
                    onTap: () => setState(() => selectedPeriod = '1m'),
                  ),
                  AppFilterChip(
                    label: '近半年',
                    isActive: selectedPeriod == '6m',
                    onTap: () => setState(() => selectedPeriod = '6m'),
                  ),
                  AppFilterChip(
                    label: '近一年',
                    isActive: selectedPeriod == '1y',
                    onTap: () => setState(() => selectedPeriod = '1y'),
                  ),
                  AppFilterChip(
                    label: '近五年',
                    isActive: selectedPeriod == '5y',
                    onTap: () => setState(() => selectedPeriod = '5y'),
                  ),
                  AppFilterChip(
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
                            color: AppColors.border,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '尚無交易紀錄',
                          style: TextStyle(
                            color: AppColors.textMuted,
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
                            builder: (_) => AddTradeScreen(editingTrade: trade)),
                        );
                        if (result != null) {
                          tradeRepo.updateTrade(trade, result.trade);
                          final oldLinked = cashRepo.getAllFlows()
                              .where((f) => f.tradeId == trade.id)
                              .firstOrNull;
                          if (result.autoDeposit != null) {
                            if (oldLinked != null) {
                              final updated = CashFlow(
                                id: oldLinked.id,
                                date: result.autoDeposit!.date,
                                type: result.autoDeposit!.type,
                                amount: result.autoDeposit!.amount,
                                note: result.autoDeposit!.note,
                                tradeId: result.autoDeposit!.tradeId,
                              );
                              cashRepo.updateFlow(updated);
                            } else {
                              cashRepo.addFlow(result.autoDeposit!);
                            }
                          } else {
                            if (oldLinked != null) cashRepo.removeFlow(oldLinked.id);
                          }
                        }
                      },
                      onDelete: () async {
                        if (await ExpandedActions.confirmDelete(context)) {
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
              builder: (_) => const AddTradeScreen()),
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