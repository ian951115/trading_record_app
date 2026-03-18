//收益日曆ui
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/trade.dart';
import '../../services/calendar_service.dart';
import '../../models/daily_pnl.dart';
import '../../repositories/trade_repository.dart';
import '../../widgets/calendar/calendar_stats_card.dart';
import '../../widgets/calendar/day_trades_sheet.dart';
import '../../utils/trade_filter.dart';
import '../../models/calendar_view_mode.dart';
import 'month_calendar_view.dart';
import 'year_calendar_view.dart';
import '../../services/heatmap_service.dart';
import '../../services/position_service.dart';

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
  int currentYear = DateTime.now().year;

  TradeFilter _filter = const TradeFilter();
  List<Trade> get filteredTrades {
    final repo = context.read<TradeRepository>();
    final allTrades = repo.getAllTrades();
    return applyTradeFilter(allTrades, _filter);
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

  void _toggleViewMode() { //年/月視圖切換
    setState(() {
      _viewMode = _viewMode == CalendarViewMode.month
          ? CalendarViewMode.year
          : CalendarViewMode.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TradeRepository>();
    repo.getAllTrades(); //為了trigger rebuild，rebuild仍依賴repo
    final result = buildPositions(filteredTrades);
    final dailyPnLMap = CalendarService.groupTradesByDay(  //但資料來源變filter pipeline
      filteredTrades,
      result.tradePnLMap,
    );
    yearData = CalendarService.calculateYearlyData(dailyPnLMap, currentYear);
    final stats = CalendarService.calculateMonthStats(dailyPnLMap, focusedDay);
    final streak = CalendarService.calculateWinStreak(dailyPnLMap, focusedDay);
    final yearMaxAbs = HeatmapService.getYearMaxAbs(yearData);
    final monthMaxAbs = HeatmapService.getMonthMaxAbs(dailyPnLMap, focusedDay);

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
            SizedBox(
              height: 160,
              child: CalendarStatsCard(
                focusedDay: focusedDay,
                stats: stats,
                streak: streak,
                formatPnL: formatPnLDisplay,
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: _viewMode == CalendarViewMode.month
                  ? MonthCalendarView(
                    key: const ValueKey('month'),
                    focusedDay: focusedDay,
                    selectedDay: selectedDay,
                    dailyPnLMap: dailyPnLMap,
                    formatPnL: formatPnLDisplay,
                    heatmapColor: (pnl) => HeatmapService.dayPnLColor(pnl, monthMaxAbs),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        selectedDay =selected;
                        focusedDay = focused;
                      });
                      _showDayTrades(selected);
                    },
                    onPageChanged: (focused) {
                      setState(() {
                        focusedDay = focused;
                      });
                    },
                  )
                  : YearCalendarView(
                    key: const ValueKey('year'),
                    currentYear: currentYear,
                    yearData: yearData,
                    heatmapColor: (pnl) => HeatmapService.monthPnLColor(pnl, yearMaxAbs),
                    formatPnL: formatPnLDisplay,
                    onPrevYear: () {
                      setState(() {
                        currentYear--;
                      });
                    },
                    onNextYear: () {
                      setState(() {
                        currentYear++;
                      });
                    },
                    onMonthTap: (month) {
                      setState(() {
                        focusedDay = DateTime(currentYear, month, 1);
                        _viewMode = CalendarViewMode.month;
                      });
                    },
                  ),
            ),
          )
        ],
      ),
    );
  }
}