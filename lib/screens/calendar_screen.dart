//收益日曆ui
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/trade.dart';
import '../services/calendar_service.dart';
import '../models/daily_pnl.dart';
import '../repositories/trade_repository.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  Map<DateTime, DailyPnl> dailyPnLMap = {};

  Map<String, dynamic> getMonthStats() {
    double totalPnL = 0;
    int winDays = 0;
    int tradeCount = 0;

    for (final entry in dailyPnLMap.entries) {
      final day = entry.key;
      final daily = entry.value;

      if (day.year == focusedDay.year && day.month == focusedDay.month) {
        totalPnL += daily.pnl;
        if (daily.pnl > 0) {
          winDays++;
        }
        tradeCount += daily.trades.length;
      }
    }
    final totalDays = dailyPnLMap.entries
        .where((e) =>
            e.key.year == focusedDay.year &&
            e.key.month == focusedDay.month)
        .length;
    
    double winRate = totalDays == 0 ? 0 : winDays / totalDays;
    return {
      'pnl': totalPnL,
      'winRate': winRate,
      'trades': tradeCount,
    };
  }

  Color getHeatmapColor(double pnl, {bool isReverse = false}) { //熱力圖計算。isReverse配合之後的可顛倒設定
    if (pnl == 0) return Colors.transparent;
    const maxValue = 200000;
    double intensity = (pnl.abs() / maxValue).clamp(0.05, 0.5);
    if (pnl > 0) {
      return (isReverse ? Colors.green : Colors.red).withValues(alpha: intensity);
    } else {
      return (isReverse ? Colors.red : Colors.green).withValues(alpha: intensity);
    }
  }

  void _showDayTrades(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final daily = dailyPnLMap[key];
    final trades = daily?.trades ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return _DayTradesSheet(
              date: key,
              trades: trades,
              pnl: daily?.pnl ?? 0,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  String formatPnLDisplay(double pnl) {
    String sign = pnl >= 0 ? '+' : '-';
    double absValue = pnl.abs();

    if (absValue >= 10000) {
      return '$sign${(absValue / 10000).toStringAsFixed(2)}萬';
    }
    return '$sign${absValue.toStringAsFixed(2)}';
  }

  Widget _buildStatsCard(Map stats, int streak) { //統計卡 Widget
    final monthLabel = '${focusedDay.year}/${focusedDay.month}';

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              monthLabel,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(
                '月損益',
                formatPnLDisplay(stats['pnl']),
                stats['pnl'] >=0 ? Colors.red : Colors.green,
              ),
              _statItem(
                '勝率',
                '${(stats['winRate'] * 100).toStringAsFixed(1)}%',
                Colors.white,
              ),
              _statItem(
                '交易',
                '${stats['trades']}',
                Colors.white,
              ),
              _statItem(
                '連勝',
                '🔥$streak',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) { //統計項目UI
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  int getWinStreak() {
    final entries = dailyPnLMap.entries
        .where((e) =>
            e.key.year == focusedDay.year &&
            e.key.month == focusedDay.month)
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    int streak = 0;
    for (final entry in entries) {
      if (entry.value.pnl > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Widget _buildDayCell(
    DateTime day, {
      bool isSelected = false,
      bool isToday = false,
    }) {
      final key = DateTime(day.year, day.month, day.day);
      final daily = dailyPnLMap[key];

      return Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: daily != null //格子底色
              ? getHeatmapColor(daily.pnl)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: isSelected //用邊框表示狀態
              ? Border.all(color: Colors.deepPurple, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Align( //右上方日期
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, right: 4),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                    color: (isSelected || isToday) ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (daily != null && daily.pnl != 0) //下方資訊
              Text(
                formatPnLDisplay(daily.pnl),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: daily.pnl >=0 ? Colors.red : Colors.green,
                ),
              ),
              const Spacer(),
          ],
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TradeRepository>();
    final trades = repo.getAllTrades();
    dailyPnLMap = CalendarService.groupTradesByDay(trades);
    final stats = getMonthStats();
    final streak = getWinStreak();

    return Scaffold(
      appBar: AppBar(
        title: const Text('收益日曆'),
      ),
      body: Column(
        children: [
          _buildStatsCard(stats, streak),
          Expanded(
            child: TableCalendar(
              firstDay: DateTime(1961),
              lastDay: DateTime(2100),
              focusedDay: focusedDay,
              rowHeight: 80, //讓格子變大
              selectedDayPredicate: (day) {
                return isSameDay(selectedDay, day);
              },
              onDaySelected: (selected, focused) {
                setState(() {
                  selectedDay = selected;
                  focusedDay = focused;
                });
                _showDayTrades(selected);
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  this.focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(),
                todayDecoration: BoxDecoration(),
                outsideDaysVisible: false,
              ),
              calendarBuilders: CalendarBuilders(
                selectedBuilder: (context, day, focusedDay) {
                  return _buildDayCell(day, isSelected: true);
                },
                todayBuilder: (context, day, focusedDay) {
                  return _buildDayCell(day, isToday: true);
                },
                defaultBuilder: (context, day, focusedDay) {
                  return _buildDayCell(day);
                },
              ),
            ),
          )
        ]
      )
    );
  }
}

class _DayTradesSheet extends StatelessWidget {
  final DateTime date;
  final List<Trade> trades;
  final double pnl;
  final ScrollController scrollController;

  const _DayTradesSheet({
    required this.date,
    required this.trades,
    required this.pnl,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),        
      children: [
        Text(
          '${date.year}-${date.month}-${date.day}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '當日損益: ${pnl.toStringAsFixed(0)}',
          style: TextStyle(
            color: pnl >= 0 ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (trades.isEmpty)
          const Text('沒有交易'),
        
        ...trades.map((t) {
          return ListTile(
            title: Text(t.symbol),
            subtitle: Text(t.type.name),
            trailing: Text(
              t.netAmount.toStringAsFixed(0),
              style: TextStyle(
                color: t.netAmount >= 0
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          );
        }),
      ],
    );
  }
}