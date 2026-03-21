//入金/提領 頁面ui
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cash_flow.dart';
import '../repositories/cash_flow_repository.dart';
import '../widgets/common/form_card.dart';
import '../widgets/common/section_title.dart';

class AddCashFlowScreen extends StatefulWidget {
  const AddCashFlowScreen({super.key});

  @override
  State<AddCashFlowScreen> createState() =>_AddCashFlowScreenState();
}

class _AddCashFlowScreenState extends State<AddCashFlowScreen> {
  CashFlowType _type = CashFlowType.deposit;
  DateTime _selectedDate = DateTime.now();
  double _amount = 0;
  String _note = '';

  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_amount <= 0) { //底部小彈窗
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入正確金額')),
      );
      return;
    }

    final cashRepo = context.read<CashFlowRepository>();
    final flow = CashFlow(
      date: _selectedDate,
      type: _type,
      amount: _amount,
      note: _note.isEmpty ? null : _note,
    );

    await cashRepo.addFlow(flow);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('新增資金紀錄'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── 類型選擇 ──────────────────────
            const SectionTitle(title: '類型'),
            FormCard(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _type = CashFlowType.deposit),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == CashFlowType.deposit
                              ? const Color(0xFFEEF7F2)
                              : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _type == CashFlowType.deposit
                                ? const Color(0xFFB8DFC9)
                                : const Color(0xFFE4E7ED),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '入金',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _type == CashFlowType.deposit
                                ? const Color(0xFF3D9E6B)
                                : const Color(0xFF9AA3B2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _type = CashFlowType.withdraw),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == CashFlowType.withdraw
                              ? const Color(0xFFFDF0EF)
                              : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _type == CashFlowType.withdraw
                                ? const Color(0xFFF5C4C2)
                                : const Color(0xFFE4E7ED),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '提領',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _type == CashFlowType.withdraw
                                ? const Color(0xFFE8504A)
                                : const Color(0xFF9AA3B2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 金額與日期 ────────────────────
            const SectionTitle(title: '基本資訊'),
            FormCard(
              child: Column(
                children: [

                  _FieldLabel(label: '金額'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) => setState(() {
                      _amount = double.tryParse(v) ?? 0;
                    }),
                    decoration: const InputDecoration(
                      hintText: '請輸入金額',
                      suffixText: '元'
                    ),
                  ),

                  const SizedBox(height: 14),

                  _FieldLabel(label: '日期'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked =await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(1961),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE4E7ED)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Color(0xFF4A6FA5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedDate.year} / '
                            '${_selectedDate.month.toString().padLeft(2,'0')} / '
                            '${_selectedDate.day.toString().padLeft(2,'0')}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1A1F2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 備註 ──────────────────────────
            const SectionTitle(title: '備註'),
            FormCard(
              child: TextField(
                controller: _noteController,
                maxLines: 3,
                onChanged: (v) => setState(() => _note = v),
                decoration: const InputDecoration(
                  hintText: '選填，例如：薪資入金、生活費提領…',
                ),
              ),
            ),

            // ── 金額預覽 ──────────────────────
            if (_amount > 0) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _type == CashFlowType.deposit
                      ? const Color(0xFFEEF7F2)
                      : const Color(0xFFFDF0EF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _type == CashFlowType.deposit
                        ? const Color(0xFFB8DFC9)
                        : const Color(0xFFF5C4C2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _type == CashFlowType.deposit ? '入金金額' : '提領金額',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _type == CashFlowType.deposit
                            ? const Color(0xFF3D9E6B)
                            : const Color(0xFFE8504A),
                      ),
                    ),
                    Text(
                      '${_type == CashFlowType.deposit ? '+' : '-'}'
                      '${_amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _type == CashFlowType.deposit
                            ? const Color(0xFF3D9E6B)
                            : const Color(0xFFE8504A),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── 儲存按鈕 ──────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('儲存'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// 欄位標籤
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
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
}