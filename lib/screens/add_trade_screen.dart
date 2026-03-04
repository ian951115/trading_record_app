//新增交易紀錄的頁面UI
import 'package:flutter/material.dart';
import 'package:trading_record_app/models/trade.dart';

const Map<String, String> mockStockMap = {
  '2330': '台積電',
  '2317': '鴻海',
  '2454': '聯發科',
  '0050': '元大台灣50',
};

class AddTradeScreen extends StatefulWidget {
  final Trade? editingTrade;
  const AddTradeScreen({super.key, this.editingTrade});

  @override
  State<AddTradeScreen> createState() => _AddTradeScreenState();
}

class _AddTradeScreenState extends State<AddTradeScreen> {
  bool isBuy = true;
  DateTime selectedDate = DateTime.now();
  double price = 0;
  int quantity = 0;
  
  String stockCode = '';
  String stockName = '';
  String note = '';
  String strategyTag = '';

  double defaultFeeRate = 0.000855; //預設手續費率0.0855%
  double defaultTaxRate = 0.003; //預設證交稅率0.3%
  double? feeRateOverride; // 使用者有沒有改
  double? taxRateOverride;
  double get feeRate => feeRateOverride ?? defaultFeeRate;
  double get taxRate => taxRateOverride ?? defaultTaxRate;
  double get feeAmount => price * quantity * feeRate; //手續費(實際需再改，例如:必須大於1元等)
  double get taxAmount => price * quantity * taxRate; //證交稅
  double get totalAmount { //總金額
    final base = price * quantity;
    if (isBuy) {return base + feeAmount;
    } else {return base - feeAmount - taxAmount;}
  }
  late final TextEditingController symbolController;
  late final TextEditingController priceController;
  late final TextEditingController quantityController;
  late final TextEditingController feeRateController;
  late final TextEditingController taxRateController;
  late final TextEditingController noteController;
  late final TextEditingController strategytagController;

  @override
  void initState() { //初始狀態設定
    super.initState();
    if(widget.editingTrade != null) { //是編輯就把資料塞回
      final t = widget.editingTrade!;
      isBuy = t.type == TradeType.buy;
      selectedDate = t.date;
      price = t.price;
      quantity = t.quantity;
      stockCode = t.symbol;
      stockName = t.name;
      note = t.note ?? '';
      strategyTag = t.tags.join(',');
      if(price > 0 && quantity > 0) {
        feeRateOverride = t.fee / (price * quantity);
        taxRateOverride = t.tax / (price * quantity);
      } 
    }
    symbolController = TextEditingController(
      text: stockCode,
    );
    priceController = TextEditingController(
      text: price == 0 ? '' : price.toString(),
    );
    quantityController = TextEditingController(
      text: quantity == 0 ? '' : quantity.toString(),
    );
    feeRateController = TextEditingController(
      text: (feeRate * 100).toStringAsFixed(4),
    );
    taxRateController = TextEditingController(
      text: (taxRate * 100).toStringAsFixed(3),
    );
    noteController = TextEditingController(
      text: note,
    );
    strategytagController = TextEditingController(
      text: strategyTag,
    );
  }

  @override
  void dispose() { //清除初始化
    symbolController.dispose();
    priceController.dispose();
    quantityController.dispose();
    feeRateController.dispose();
    taxRateController.dispose();
    noteController.dispose();
    strategytagController.dispose();
    super.dispose();
  }

  void _saveTrade() { //儲存交易
    final trade = Trade(
      date: selectedDate,
      symbol: stockCode,
      name: stockName,
      type: isBuy ? TradeType.buy : TradeType.sell,
      price: price,
      quantity: quantity,
      fee: feeAmount,
      tax: taxAmount,
      note: note.isEmpty ? null : note,
      tags: strategyTag.isEmpty ? [] : [strategyTag],
    );
    Navigator.pop(context, trade);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editingTrade == null ? '新增交易' : '編輯交易',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: '交易基本資訊'),
            _FormCard(
              child: Column(
                children: [
                  _DatePickerField(
                    date: selectedDate,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(1961),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 12),
                  _ToggleBuySell(
                    isBuy: isBuy,
                    onChanged: (value) {
                      setState(() {
                        isBuy = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _TextField(
                    label: '商品代碼',
                    controller: symbolController,
                    onChanged: (v) {
                      setState(() {
                        stockCode = v;
                        stockName = mockStockMap[v] ?? '';
                      });
                    },
                  ),
                  SizedBox(height: 12),
                  _ReadOnlyField(
                    label: '商品名稱',
                    value: stockName,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24), //--------------------
            _SectionTitle(title: '金額計算'),
            _FormCard(
              child: Column(
                children: [
                  _NumberField(
                    label: '價格',
                    unit: '元',
                    controller: priceController,
                    onChanged: (v) { //(v)輸入資料/{...}函式本身
                      setState(() {
                        price = double.tryParse(v) ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    label: '數量',
                    unit: '股',
                    controller: quantityController,
                    onChanged: (v) { //(v)輸入資料/{...}函式本身
                      setState(() {
                        quantity = int.tryParse(v) ?? 0;
                      });
                    },
                  ),             
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _FeeField(
                        label: '手續費',
                        controller: feeRateController,
                        onChanged: (v) {
                          setState(() {
                            feeRateOverride =
                                v.isEmpty ? null : (double.tryParse(v) ?? 0)/100;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      _FeeField(
                        label: '交易稅',
                        controller: taxRateController,
                        onChanged: (v) {
                          setState(() {
                            taxRateOverride =
                                v.isEmpty ? null : (double.tryParse(v) ?? 0)/100;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container( //交易金額顯示
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                         '交易金額',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalAmount.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24), //--------------------
            _SectionTitle(title: '備註與策略'),
            _FormCard(
              child: Column(
                children: [
                  _MultiLineField(
                    label: '備註',
                    hint: '記錄進出場原因、想法…',
                    controller: noteController,
                    onChanged: (v) {
                      setState(() {
                        note = v;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _TextField(
                    label: '策略標籤',
                    controller: strategytagController,
                    onChanged: (v) {
                      setState(() {
                        strategyTag = v;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32), //--------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTrade,
                child: const Text('儲存交易'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}





class _SectionTitle extends StatelessWidget { //區塊標題
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FormCard extends StatelessWidget { //表單卡片
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ToggleBuySell extends StatelessWidget { //買/賣切換元件
  final bool isBuy;
  final ValueChanged<bool> onChanged;
  const _ToggleBuySell({
    required this.isBuy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 4) / 2;
          return ToggleButtons(
            isSelected: [isBuy, !isBuy],
            onPressed: (index) {
              onChanged(index == 0);
            },
            borderRadius: BorderRadius.circular(8),
            constraints: BoxConstraints(
              minHeight: 48,
              minWidth: width,
            ),
            children: const [Text('買'),Text('賣')],
          );
        },
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget { //日期選擇元件
  final DateTime date;
  final VoidCallback onTap;
  const _DatePickerField({
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 14),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(8)
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,size: 18),
            const SizedBox(width: 8),
            Text(
              '${date.year}/${date.month}/${date.day}',
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget { //數字輸入元件
  final String label;
  final String unit;
  final TextEditingController controller;
  final ValueChanged<String> onChanged; //接收String，沒有回傳值的函式
  const _NumberField({
    required this.label,
    required this.unit,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.blueGrey.shade50,
            suffixText: unit, //字尾/下標
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _TextField extends StatelessWidget { //單行輸入元件
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _TextField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.blueGrey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget { //唯讀元件(名稱)
  final String label;
  final String value;
  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12,vertical: 14),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.isEmpty ? '_' : value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

class _FeeField extends StatelessWidget { //費率元件
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _FeeField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.blueGrey.shade50,
              suffixText: '%',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );  
  }
}

class _MultiLineField extends StatelessWidget { //多行輸入元件
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _MultiLineField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          maxLines: 4,
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.blueGrey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}