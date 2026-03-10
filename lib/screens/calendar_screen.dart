//收益日曆ui
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trading_record_app/models/trade.dart';
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

  Color getHeatmapColor(double pnl) {
    const maxValue = 10000;

    double intensity = (pnl.abs() / maxValue).clamp(0.1, 0.8);

    if (pnl > 0) {
      return Colors.red.withValues(alpha: intensity);
    } else if (pnl < 0) {
      return Colors.green.withValues(alpha: intensity);
    } else {
      return Colors.transparent;
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

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TradeRepository>();
    final trades = repo.getAllTrades();

    dailyPnLMap = CalendarService.groupTradesByDay(trades);

    return Scaffold(
      appBar: AppBar(
        title: const Text('收益日曆'),
      ),

      body: TableCalendar(
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

        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final key =DateTime(day.year, day.month, day.day);
            final daily = dailyPnLMap[key];

            if (daily == null) {
              return null;
            }

            final color = getHeatmapColor(daily.pnl);

            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '${day.day}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (daily.pnl !=0)
                    Text(
                      formatPnLDisplay(daily.pnl),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
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