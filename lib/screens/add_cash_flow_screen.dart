//入金/提領 頁面ui
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/cash_flow.dart';
import '../repositories/cash_flow_repository.dart';

class AddCashFlowScreen extends StatefulWidget {
  const AddCashFlowScreen({super.key});

  @override
  State<AddCashFlowScreen> createState() =>_AddCashFlowScreenState();
}

class _AddCashFlowScreenState extends State<AddCashFlowScreen> {
  final _formKey = GlobalKey<FormState>();

  CashFlowType _type = CashFlowType.deposit;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final cashRepo = context.read<CashFlowRepository>();

    final flow = CashFlow(
      id: const Uuid().v4(),
      date: _selectedDate,
      amount: double.parse(_amountController.text),
      type: _type,
      note: _noteController.text,
    );

    await cashRepo.addFlow(flow);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增資金紀錄'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SegmentedButton<CashFlowType>( //類型選擇
                segments: const [
                  ButtonSegment(
                    value: CashFlowType.deposit,
                    label: Text('入金'),
                  ),
                  ButtonSegment(
                    value: CashFlowType.withdraw,
                    label: Text('提領'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (value) {
                  setState(() {
                    _type = value.first;
                  });
                },
              ),

              const SizedBox(height: 16),

              TextFormField( //金額
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '金額',
                ),
                validator: (value) { //像密碼錯誤的那種下方紅字提示
                  if (value == null || value.isEmpty) {
                    return '請輸入金額';
                  }
                  if (double.tryParse(value) == null) {
                    return '請輸入正確數字';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              ListTile( //日期
                title: const Text('日期'),
                subtitle: Text(_selectedDate.toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(1961),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              TextFormField( //備註
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: '備註(選填)',
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _save,
                child: const Text('儲存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
