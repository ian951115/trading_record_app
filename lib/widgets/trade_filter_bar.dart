//下拉式選單的元件
import 'package:flutter/material.dart';

class TradeFilterBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<DateTimeRange> onRangeChanged;
  const TradeFilterBar({
    super.key,
    required this.onChanged,
    required this.onRangeChanged,
  });

  @override
  State<TradeFilterBar> createState() => _TradeFilterBarState();
}

class _TradeFilterBarState extends State<TradeFilterBar> {
  String selectedValue = 'all';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 20),
          const SizedBox(width: 8),
          const Text('時間區間'),
          const Spacer(),
          DropdownButton<String>(
            value: selectedValue,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: '1m',child: Text('近一個月')),
              DropdownMenuItem(value: '6m',child: Text('近半年')),
              DropdownMenuItem(value: '1y',child: Text('近一年')),
              DropdownMenuItem(value: '5y',child: Text('近五年'),),
              DropdownMenuItem(value: 'all',child: Text('全部')),
              DropdownMenuItem(value: 'custom',child: Text('自選區間')),
            ],
            onChanged: (value) async { // 更新選擇值並重建 UI
              if (value == null) return; 
              if (value == 'custom') { //自選
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(1961),
                  lastDate: DateTime.now(),
                );
                if (range != null) {
                  widget.onRangeChanged(range);
                  setState(() {
                    selectedValue = 'custom';
                  });
                }
              } else { //其他非自選
                setState(() {
                  selectedValue = value;
                });
                widget.onChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}