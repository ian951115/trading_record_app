//新增交易紀錄的頁面UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/trade.dart';
import '../../models/add_trade_result.dart';
import '../../models/cash_flow.dart';
import '../../repositories/trade_repository.dart';
import '../../repositories/cash_flow_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/portfolio_service.dart';
import '../../services/stock_price_service.dart';
import '../../services/stock_name_service.dart';
import '../../core/stock_fallback.dart';
import '../../widgets/common/form_card.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/info_item.dart';

class AddTradeScreen extends StatefulWidget {
  final Trade? editingTrade;
  const AddTradeScreen({super.key, this.editingTrade});
  @override
  State<AddTradeScreen> createState() => _AddTradeScreenState();
}

class _AddTradeScreenState extends State<AddTradeScreen> {
  bool _isFetchingName = false;
  bool isBuy = true;
  DateTime selectedDate = DateTime.now();
  double price = 0;
  int quantity = 0;
  
  String stockCode = '';
  String stockName = '';
  String note = '';
  List<String> strategyTags = [];

  double defaultFeeRate = 0.000855; //預設手續費率0.0855%
  double defaultTaxRate = 0.003; //預設證交稅率0.3%
  double? feeRateOverride; // 使用者有沒有改
  double? taxRateOverride;
  double get feeRate => feeRateOverride ?? defaultFeeRate;
  double get taxRate => taxRateOverride ?? defaultTaxRate;
  double get feeAmount => price * quantity * feeRate;
  double get taxAmount => price * quantity * taxRate; //證交稅
  double get totalAmount { //總金額
    final base = price * quantity;
    if (isBuy) return base + feeAmount;
      return base - feeAmount - taxAmount;
  }

  bool autoDepositEnabled = false; //是否同時入金
  late double autoDepositAmount;

  late final TextEditingController symbolController;
  late final TextEditingController nameController;
  late final TextEditingController priceController;
  late final TextEditingController quantityController;
  late final TextEditingController feeRateController;
  late final TextEditingController taxRateController;
  late final TextEditingController noteController;
  late final TextEditingController autoDepositController;

  @override
  void initState() { //初始狀態設定
    super.initState();
    autoDepositAmount = totalAmount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsRepository>().settings;
      setState(() {
        defaultFeeRate = settings.defaultFeeRate;
        defaultTaxRate = settings.defaultTaxRate;
        autoDepositEnabled = settings.autoDepositDefault;
        //更新controller顯示值
        feeRateController.text = (defaultFeeRate * 100).toStringAsFixed(4);
        taxRateController.text = (defaultTaxRate * 100).toStringAsFixed(3);
      });
    });

    if(widget.editingTrade != null) { //是編輯就把資料塞回
      final t = widget.editingTrade!;
      isBuy = t.type == TradeType.buy;
      selectedDate = t.date;
      price = t.price;
      quantity = t.quantity;
      stockCode = t.symbol;
      stockName = t.name;
      note = t.note ?? '';
      strategyTags = List.from(t.tags);
      if(price > 0 && quantity > 0) {
        feeRateOverride = t.fee / (price * quantity);
        taxRateOverride = t.tax / (price * quantity);
      } 
    }
    symbolController = TextEditingController(text: stockCode);
    nameController = TextEditingController(text: stockName);
    priceController = TextEditingController(
      text: price == 0 ? '' : price.toString());
    quantityController = TextEditingController(
      text: quantity == 0 ? '' : quantity.toString());
    feeRateController = TextEditingController(
      text: (feeRate * 100).toStringAsFixed(4));
    taxRateController = TextEditingController(
      text: (taxRate * 100).toStringAsFixed(3));
    noteController = TextEditingController(text: note);
    autoDepositController = TextEditingController(
      text: totalAmount.toStringAsFixed(0));
  }

  @override
  void dispose() { //清除初始化
    symbolController.dispose();
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    feeRateController.dispose();
    taxRateController.dispose();
    noteController.dispose();
    autoDepositController.dispose();
    super.dispose();
  }

  void _updateAutoDeposit() { //當金額改變時同步更新入金預設值
    autoDepositAmount = totalAmount;
    autoDepositController.text = totalAmount.toStringAsFixed(0);
  }

  void _saveTrade() { //儲存交易
    // ── 驗證 ──────────────────────
    if (stockCode.trim().isEmpty) {
      _showError('請填入股票代碼'); return;
    }
    if (price <= 0) {
      _showError('請填入有效價格'); return;
    }
    if (quantity <= 0) {
      _showError('請填入有效數量'); return;
    }

    double finalFee = feeAmount;
    if (mounted) {
      final settings = context.read<SettingsRepository>().settings;
      //判斷以股還是以張
      final minFee = quantity >= 1000
          ? settings.minFeePerLot
          : settings.minFeePerShare;
      if (finalFee < minFee) finalFee = minFee;
    }

    final trade = Trade(
      id: widget.editingTrade?.id,
      date: selectedDate,
      symbol: stockCode,
      name: stockName,
      type: isBuy ? TradeType.buy : TradeType.sell,
      price: price,
      quantity: quantity,
      fee: finalFee,
      tax: isBuy ? 0 : taxAmount,
      note: note.isEmpty ? null : note,
      tags: strategyTags,
    );

    CashFlow? autoDeposit;
    if (isBuy && autoDepositEnabled) {
      autoDeposit = CashFlow(
        date: selectedDate,
        type: CashFlowType.deposit,
        amount: double.tryParse(autoDepositController.text) ?? totalAmount,
      );
    }
    Navigator.pop(context, AddTradeResult(
      trade: trade,
      autoDeposit: autoDeposit,
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFE8504A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _onSymbolChanged(String value) async {
    final name = StockNameService.getName(value.trim());
    if (name != null) {
      setState(() => stockName = name); //同步查快取
      nameController.text = stockName;
      return;
    }
    // 查不到就清空，讓使用者手動填
    setState(() => stockName = '');
    nameController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    final cashFlows = context.watch<CashFlowRepository>().getAllFlows();
    final allTrades = context.watch<TradeRepository>().getAllTrades();
    final hasCashData = cashFlows.isNotEmpty;
    final currentCash = hasCashData
        ? PortfolioService.calculateCash(
            trades: allTrades, cashFlows: cashFlows)
        : 0.0;
    final afterCash = isBuy
        ? currentCash - totalAmount
        : currentCash + totalAmount;
    final fmt = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.editingTrade == null ? '新增交易' : '編輯交易'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── 基本資訊 ──────────────────────
            const SectionTitle(title: '基本資訊'),
            FormCard(
              child: Column(
                children: [
                  _DatePickerField( //選日期
                    date: selectedDate,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(1961),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _ToggleBuySell( //買/賣
                    isBuy: isBuy,
                    onChanged: (value) {
                      setState(() {
                        isBuy = value;
                        _updateAutoDeposit();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _AppTextField(
                    label: '商品代碼',
                    controller: symbolController,
                    onChanged: (v) {
                      stockCode = v;
                      _onSymbolChanged(v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '商品名稱',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5A6375),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        onChanged: (v) => setState(() => stockName = v),
                        decoration: InputDecoration(
                          hintText: '自動填入或手動輸入',
                          suffixIcon: _isFetchingName
                              ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 金額計算 ──────────────────────
            const SectionTitle(title: '金額計算'),
            FormCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _AppTextField(
                          label: '價格',
                          suffix: '元',
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            setState(() {
                              price = double.tryParse(v) ?? 0;
                              _updateAutoDeposit();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AppTextField(
                          label: '數量',
                          suffix: '股',
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            setState(() {
                              quantity = int.tryParse(v) ?? 0;
                              _updateAutoDeposit();
                            });
                          },
                        ),
                      ),
                    ],
                  ),             
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AppTextField(
                          label: '手續費率',
                          suffix: '%',
                          controller: feeRateController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            setState(() {
                              feeRateOverride = v.isEmpty
                                  ? null
                                  : (double.tryParse(v) ?? 0) / 100;
                              _updateAutoDeposit();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AppTextField(
                          label: '證交稅率',
                          suffix: '%',
                          controller: taxRateController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            setState(() {
                              taxRateOverride = v.isEmpty
                                  ? null
                                  : (double.tryParse(v) ?? 0) / 100;
                              _updateAutoDeposit();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container( //交易金額顯示
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEBF0F8), Color(0xFFDDE8F5)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC5D4EC))
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                         '交易金額',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A6FA5),
                          ),
                        ),
                        Text(
                          totalAmount.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A6FA5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasCashData) ...[
                    const Divider(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InfoItem(
                            label: '現金餘額',
                            value: fmt.format(currentCash.toInt()),
                          ),
                        ),
                        Expanded(
                          child: InfoItem(
                            label: isBuy ? '交易後剩餘' : '交易後現金',
                            value: fmt.format(afterCash.toInt()),
                            valueColor: afterCash < 0 ? const Color(0xFFE8504A) : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            // ── 備註與策略 ────────────────────
            const SectionTitle(title: '備註與策略'),
            FormCard(
              child: Column(
                children: [
                  _AppTextField(
                    label: '備註',
                    hint: '記錄進出場原因、想法…',
                    controller: noteController,
                    maxLines: 4,
                    onChanged: (v) => setState(() => note = v),
                  ),
                  const SizedBox(height: 12),
                  _TagsField(
                    tags: strategyTags,
                    onChanged: (tags) => setState(() => strategyTags = tags),
                  ),
                ],
              ),
            ),

            // ── 同時記錄入金（只在買入時顯示）──
            if (isBuy) ...[
              const SizedBox(height: 20),
              const SectionTitle(title: '資金管理'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E7ED)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding( //開關列
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '同時記錄入金',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1F2E),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '自動新增對應入金紀錄',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9AA3B2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: autoDepositEnabled,
                            activeThumbColor: const Color(0xFF4A6FA5),
                            onChanged: (v) {
                              setState(() => autoDepositEnabled = v);
                            },
                          ),
                        ],
                      ),
                    ),
                    if (autoDepositEnabled) ...[ //入金金額欄位（開啟時才顯示）
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _AppTextField(
                          label: '入金金額（可修改）',
                          controller: autoDepositController,
                          keyboardType: TextInputType.number,
                          filled: true,
                          fillColor: const Color(0xFFEEF7F2),
                          onChanged: (_) {},
                          suffix: '元',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── 儲存按鈕 ──────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTrade,
                child: const Text('儲存交易'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? suffix;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool filled;
  final Color? fillColor;

  const _AppTextField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.hint,
    this.suffix,
    this.keyboardType,
    this.maxLines = 1,
    this.filled = false,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5A6375),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            filled: filled,
            fillColor: fillColor,
          ),
        ),
      ],
    );
  }
}

class _ToggleBuySell extends StatelessWidget { //買賣切換元件
  final bool isBuy;
  final ValueChanged<bool> onChanged;

  const _ToggleBuySell({
    required this.isBuy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isBuy
                    ? const Color(0xFFFDF0EF)
                    : const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isBuy
                      ? const Color(0xFFF5C4C2)
                      : const Color(0xFFE4E7ED),
                  width: 1.5,
                ),
              ),
              child: Text(
                '買入',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isBuy
                      ? const Color(0xFFE8504A)
                      : const Color(0xFF9AA3B2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !isBuy
                    ? const Color(0xFFEEF7F2)
                    : const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: !isBuy
                      ? const Color(0xFFB8DFC9)
                      : const Color(0xFFE4E7ED),
                  width: 1.5,
                ),
              ),
              child: Text(
                '賣出',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: !isBuy
                      ? const Color(0xFF3D9E6B)
                      : const Color(0xFF9AA3B2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(8),
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
              '${date.year} / ${date.month.toString().padLeft(2, '0')} / ${date.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A1F2E),
              ),
            ),
          ],
        ),
      ),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5A6375),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12,vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFE4E7ED),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.isEmpty ? '_' : value,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9AA3B2),
            ),
          ),
        ),
      ],
    );
  }
}

class _TagsField extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  const _TagsField({required this.tags, required this.onChanged});
  
  @override
  State<_TagsField> createState() => _TagsFieldState();
}

class _TagsFieldState extends State<_TagsField> {
  final _ctrl = TextEditingController();

  void _add() { //新增標籤
    final v = _ctrl.text.trim();
    if (v.isEmpty || widget.tags.contains(v)) {_ctrl.clear(); return;} //檢查是否已有標籤
    widget.onChanged([...widget.tags, v]); //無則新增
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '策略標籤',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF9AA3B2),
        ),
      ),
      const SizedBox(height: 8),
      if (widget.tags.isNotEmpty) Wrap(
        spacing: 6,
        runSpacing: 4,
        children: widget.tags.map((tag) => Chip(
          label: Text(tag, style: const TextStyle(fontSize: 12)),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: () => widget.onChanged(widget.tags.where((t) => t != tag).toList()),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        )).toList(),
      ),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: '輸入後按 + 新增',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) => _add(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _add,
            color: const Color(0xFF4A6FA5),
          ),
        ],
      ),
    ],
  );
}