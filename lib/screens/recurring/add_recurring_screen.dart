//新增定期定額畫面
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/recurring_plan.dart';
import '../../repositories/recurring_repository.dart';
import '../../services/data/stock_name_service.dart';
import '../../widgets/common/form_card.dart';
import '../../widgets/common/section_title.dart';

class AddRecurringScreen extends StatefulWidget {
  final RecurringPlan? existingPlan;
  const AddRecurringScreen({super.key, this.existingPlan});

  @override
  State<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends State<AddRecurringScreen> {
  // ── 表單狀態 ─────────────────────────────────
  String _symbol = '';
  String _name = '';
  double _amount = 0;
  DateTime _startDate = DateTime.now();
  String _note = '';
  bool _isLookingUp = false; //API 查股票名稱中

  final Set<int> _selectedDays = {}; //每月扣款日（多選，1~31）
  final fmt = NumberFormat('#,###');

  late final TextEditingController _symbolCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPlan;
    if (p != null) { //編輯模式預填
      _symbol = p.symbol;
      _name = p.name;
      _amount = p.amountPerTime;
      _startDate = p.startDate;
      _note = p.note ?? '';
      _selectedDays.addAll(p.dayOfMonth);
    }
    _symbolCtrl = TextEditingController(text: _symbol);
    _nameCtrl = TextEditingController(text: _name);
    _amountCtrl = TextEditingController(
      text: _amount > 0 ? _amount.toStringAsFixed(0) : '');
    _noteCtrl = TextEditingController(text: _note);
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future <void> _onSymbolChanged(String value) async {
    final name = StockNameService.getName(value.trim());
    if (name != null) {
      setState(() => _name = name);
      _nameCtrl.text = _name;  
      return;
    }
    setState(() => _name = '');
    _nameCtrl.text = '';
  }

  void _save() async {
    if (_symbol.isEmpty) {
      _showSnack('請輸入股票代碼');
      return;
    }
    if (_name.isEmpty) {
      _showSnack('請輸入股票名稱');
      return;
    }
    if (_selectedDays.isEmpty) {
      _showSnack('請選擇至少一個扣款日');
      return;
    }
    if (_amount <= 0) {
      _showSnack('請輸入正確金額');
      return;
    }

    final repo = context.read<RecurringRepository>();
    final existing = widget.existingPlan;

    if (existing != null) {
      final updated = existing.copyWith(
        symbol: _symbol,
        name: _name,
        dayOfMonth: _selectedDays.toList()..sort(),
        amountPerTime: _amount,
        startDate: _startDate,
        note: _note.isEmpty ? null : _note,
      );
      await repo.update(updated);
    } else {
      final plan = RecurringPlan(
        symbol: _symbol,
        name: _name,
        frequency: RecurringFrequency.monthly,
        dayOfMonth: _selectedDays.toList()..sort(),
        amountPerTime: _amount,
        startDate: _startDate,
        note: _note.isEmpty ? null : _note,
      );
      await repo.update(plan);
    }
    if (mounted) Navigator.pop(context);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger
      .of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1960),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingPlan != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEdit ? '編輯定期定額' : '新增定期定額'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 股票資訊 ───────────────────────
            const SectionTitle(title: '股票'),
            FormCard(
              child: Column(
                children: [
                  _FieldLabel(label: '股票代碼'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _symbolCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: _onSymbolChanged,
                    decoration: InputDecoration(
                      hintText: 'e.g. 0050',
                      suffixIcon: _isLookingUp
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel(label: '股票名稱'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    onChanged: (v) => setState(() => _name = v.trim()),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 元大台灣50'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 扣款設定 ───────────────────────
            const SectionTitle(title: '扣款設定'),
            FormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [ //扣款日選擇
                  _FieldLabel(label: '每月扣款日（可多選）'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6, runSpacing: 6, //主軸及垂直軸間隔
                    children: List.generate(31, (i) {
                      final day = i + 1;
                      final isSelected = _selectedDays.contains(day);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selectedDays.remove(day);
                          } else {
                            _selectedDays.add(day);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF4A6FA5)
                                : const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4A6FA5)
                                  : const Color(0xFFE4E7ED),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF5A6375),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 14),

                  _FieldLabel(label: '每次扣款金額'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    onChanged: (v) => setState(() {
                      _amount = double.tryParse(v) ?? 0;
                    }),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 10000',
                      suffixText: '元',
                    ),
                  ),
                  
                  //月投入預覽（有選日期且有金額才顯示）
                  if (_selectedDays.isNotEmpty && _amount > 0)...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF0F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '每月合計',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5A6375),
                            ),
                          ),
                          Text(
                            '${fmt.format((_amount * _selectedDays.length).toInt())} 元',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3D5A8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 開始日期 ───────────────────────
            const SectionTitle(title: '開始日期'),
            FormCard(
              child: GestureDetector(
                onTap: _pickDate,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                      size: 16, color: Color(0xFF4A6FA5)),
                    const SizedBox(width: 10),
                    Text(
                      '${_startDate.year} / '
                      '${_startDate.month.toString().padLeft(2,"0")} / '
                      '${_startDate.day.toString().padLeft(2,"0")}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1F2E),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                      size: 18, color: Color(0xFF9AA3B2)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── 備註（選填）────────────────────
            const SectionTitle(title: '備註(選填)'),
            FormCard(
              child: TextField(
                controller: _noteCtrl,
                maxLines: 2,
                onChanged: (v) => setState(() => _note = v),
                decoration: const InputDecoration(
                  hintText: 'e.g. 退休金定存股',
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── 儲存按鈕 ───────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? '更新' : '新增計畫'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── 欄位標籤 ─────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF5A6375),
      ),
    ),
  );
}
