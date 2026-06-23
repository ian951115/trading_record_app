//收益日曆ui
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/trade.dart';
import '../../models/daily_pnl.dart';
import '../../models/calendar_view_mode.dart';
import '../../repositories/trade_repository.dart';
import '../../services/calc/position_service.dart';
import '../../services/calc/pnl_service.dart';
import '../../core/trade_filter.dart';
import '../../widgets/calendar/calendar_stats_card.dart';
import '../../widgets/calendar/day_trades_sheet.dart';
import 'month_calendar_view.dart';
import 'year_calendar_view.dart';


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

  void _showDayTrades(DateTime day, Map<DateTime, DailyPnl> map) {
    final key = DateTime(day.year, day.month, day.day);
    final daily = map[key];
    final trades = daily?.trades ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('收益日曆'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEBF0F8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC5D4EC)),
              ),
              child: Row(
                children: [
                  _ViewToggleBtn(
                    label: '月',
                    isActive: _viewMode == CalendarViewMode.month,
                    onTap: () {
                      if (_viewMode != CalendarViewMode.month) {
                        _toggleViewMode();
                      }
                    },
                  ),
                  _ViewToggleBtn(
                    label: '年',
                    isActive: _viewMode == CalendarViewMode.year,
                    onTap: () {
                      if (_viewMode != CalendarViewMode.year) {
                        _toggleViewMode();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _viewMode == CalendarViewMode.month
          ? Column(
              children: [
                CalendarStatsCard(
                  focusedDay: focusedDay,
                  stats: stats,
                  streak: streak,
                ),      
                Expanded(
                  child: MonthCalendarView(
                    key: const ValueKey('month'),
                    focusedDay: focusedDay,
                    selectedDay: selectedDay,
                    dailyPnLMap: dailyPnLMap,
                    onDaySelected: (selected, focused) {
                      setState(() {
                        selectedDay =selected;
                        focusedDay = focused;
                      });
                      _showDayTrades(selected, dailyPnLMap);
                    },
                    onPageChanged: (focused) {
                      setState(() {
                        focusedDay = focused;
                      });
                    },
                  ),
                ),
              ],
            )
          : YearCalendarView(
              key: const ValueKey('year'),
              currentYear: currentYear,
              yearData: yearData,
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
    );
  }
}

class _ViewToggleBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggleBtn({
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
        padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4A6FA5) : Colors.transparent,
          borderRadius: BorderRadius.circular(7)
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : const Color(0xFF4A6FA5)
          ),
        ),
      ),
    );
  }
}