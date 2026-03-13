//收益日曆ui
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trading_record_app/domain/aggregation/year_aggregation.dart';
import 'package:trading_record_app/domain/heatmap/heatmap_normalizer.dart';
import '../models/trade.dart';
import '../services/calendar_service.dart';
import '../models/daily_pnl.dart';
import '../repositories/trade_repository.dart';
import '../widgets/calendar/calendar_day_cell.dart';
import '../widgets/calendar/calendar_stats_card.dart';
import '../widgets/calendar/day_trades_sheet.dart';
import '../domain/filter/trade_filter.dart';
import '../domain/calendar/view_mode.dart';
import '../widgets/charts/mini_sparkline.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  Map<DateTime, DailyPnl> dailyPnLMap = {};
  Map<int, YearMonthData> yearData ={};
  CalendarViewMode _viewMode = CalendarViewMode.month;

  TradeFilter _filter = const TradeFilter();
  List<Trade> get filteredTrades {
    final repo = context.read<TradeRepository>();
    final allTrades = repo.getAllTrades();
    return applyTradeFilter(allTrades, _filter);
  }

  Map<String, dynamic> getMonthStats() { //取得月份資料
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

  Color getMonthHeatmapColor(double pnl) {
    final maxAbs = getYearMaxAbs();
    final n = HeatmapNormalizer.normalize(pnl, maxAbs);
    if (n == 0) return Colors.grey.shade200;
    if (n > 0) {
      return Colors.red.withValues(alpha: 0.15 + 0.35 * n);
    } else {
      return Colors.green.withValues(alpha: 0.15 + 0.35 * n.abs());
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
            return DayTradesSheet(
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

  String formatPnLDisplay(double pnl) { //輸出格式化
    String sign = pnl >= 0 ? '+' : '-';
    double absValue = pnl.abs();

    if (absValue >= 10000) {
      return '$sign${(absValue / 10000).toStringAsFixed(2)}萬';
    }
    return '$sign${absValue.toStringAsFixed(2)}';
  }

  int getWinStreak() { //連勝計算
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

  double getYearMaxAbs() { //找最大值
    double maxVal = 0;

    for (final m in yearData.values) {
      if (m.totalPnL.abs() > maxVal) {
        maxVal = m.totalPnL.abs();
      }
    }

    return maxVal;
  }

  void _toggleViewMode() { //年/月視圖切換按鈕
    setState(() {
      _viewMode = _viewMode == CalendarViewMode.month
          ? CalendarViewMode.year
          : CalendarViewMode.month;
    });
  }

  Widget _buildYearViewPlaceholder() { //年視圖
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final data = yearData[month];

        return _buildYearMonthCell(month, data);
      },
    );
  }

  Widget _buildMonthCalendar() { //月視圖
    return TableCalendar(
      firstDay: DateTime(1961),
      lastDay: DateTime(2100),
      focusedDay: focusedDay,
      rowHeight: 74, //讓格子變大
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
          final key =DateTime(day.year, day.month, day.day);
          final daily = dailyPnLMap[key];
          return CalendarDayCell(
            day: day,
            daily: daily,
            isSelected: true,
            formatPnL: formatPnLDisplay,
            heatmapColor: getHeatmapColor,
          );
        },
        todayBuilder: (context, day, focusedDay) {
          final key =DateTime(day.year, day.month, day.day);
          final daily = dailyPnLMap[key];
          return CalendarDayCell(
            day: day,
            daily: daily,
            isToday: true,
            formatPnL: formatPnLDisplay,
            heatmapColor: getHeatmapColor,
          );
        },
        defaultBuilder: (context, day, focusedDay) {
          final key =DateTime(day.year, day.month, day.day);
          final daily = dailyPnLMap[key];
          return CalendarDayCell(
            day: day,
            daily: daily,
            formatPnL: formatPnLDisplay,
            heatmapColor: getHeatmapColor,
          );
        },
      ),
    );
  }

  Widget _buildYearMonthCell(int month, YearMonthData? data) {
    final pnl = data?.totalPnL ?? 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          focusedDay = DateTime(focusedDay.year, month, 1);
          _viewMode = CalendarViewMode.month;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: getMonthHeatmapColor(pnl),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$month 月',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            MiniSparkline(
              data: data?.dailyPnLSequence ?? [],
            ),
            const Spacer(),
            Text(
              formatPnLDisplay(pnl),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TradeRepository>();
    repo.getAllTrades(); //為了trigger rebuild，rebuild仍依賴repo
    dailyPnLMap = CalendarService.groupTradesByDay(filteredTrades); //但資料來源變filter pipeline
    yearData = calculateYearlyData(dailyPnLMap, focusedDay.year);
    final stats = getMonthStats();
    final streak = getWinStreak();

    return Scaffold(
      appBar: AppBar(
        title: const Text('收益日曆'),
        actions: [
          IconButton(
            icon: Icon(
              _viewMode == CalendarViewMode.month
                  ? Icons.grid_view
                  : Icons.calendar_view_month
            ),
            onPressed: _toggleViewMode,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_viewMode == CalendarViewMode.month)
            CalendarStatsCard(
              focusedDay: focusedDay,
              stats: stats,
              streak: streak,
              formatPnL: formatPnLDisplay,
            ),
          Expanded(
            child: _viewMode == CalendarViewMode.month
                ? _buildMonthCalendar()
                : _buildYearViewPlaceholder(),
          ),
        ],
      ),
    );
  }
}