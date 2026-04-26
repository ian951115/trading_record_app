//新增股利頁面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dividend.dart';
import '../../repositories/dividend_repository.dart';
import '../../repositories/trade_repository.dart';
import '../../services/position_service.dart';
import '../../widgets/common/form_card.dart';
import '../../widgets/common/section_title.dart';

double _calcHealthInsurance(double amount) { //二代健保計算
  if (amount <= 20000) return 0;
  return amount * 0.0211;
}

class AddDividendScreen extends StatefulWidget {
  const AddDividendScreen({super.key});
  @override
  State<AddDividendScreen> createState() => _AddDividendScreenState();
}

class _AddDividendScreenState extends State<AddDividendScreen> {
  DividendType _type = DividendType.cash;
  DateTime _date = DateTime.now();
  String _symbol = '';
  String _name = '';
  double _pricePerShare = 0; //每股股利（現金）
  int _heldShares = 0; //持股數（現金股利計算用）
  int _shareAmount = 0; //配股股數（股票股利）
  double _fee = 0;
  String _note = '';

  double get _grossAmount => _pricePerShare * _heldShares; //計算毛額
  double get _healthInsurance => _calcHealthInsurance(_grossAmount); //自動計算二代健保
  double get _netAmount => _grossAmount - _fee - _healthInsurance; //淨額

  late final TextEditingController _symbolCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _sharesCtrl;
  late final TextEditingController _shareAmtCtrl;
  late final TextEditingController _feeCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _symbolCtrl = TextEditingController();
    _priceCtrl = TextEditingController();
    _sharesCtrl = TextEditingController();
    _shareAmtCtrl = TextEditingController();
    _feeCtrl = TextEditingController(text: '0');
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _symbolCtrl.dispose(); _priceCtrl.dispose();
    _sharesCtrl.dispose(); _shareAmtCtrl.dispose();
    _feeCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (_symbol.trim().isEmpty) {
      _showError('請填入股票代碼'); return;
    }
    if (_pricePerShare <= 0) {
      _showError('請填入有效每股股利'); return;
    }
    if (_type == DividendType.cash && _grossAmount <= 0) return;
    if (_type == DividendType.stock && _shareAmount <= 0) return;

    final div = Dividend(
      date: _date,
      symbol: _symbol,
      name: _name,
      type: _type,
      cashAmount: _type == DividendType.cash ? _grossAmount : 0,
      shareAmount: _type == DividendType.stock ? _shareAmount : 0,
      fee: _fee,
      healthInsurance: _type == DividendType.cash ? _healthInsurance : 0,
      note: _note.isEmpty ? null : _note,
    );

    await context.read<DividendRepository>().addDividend(div);
    Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFE8504A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('新增股利'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            //類型切換
            const SectionTitle(title: '類型'),
            FormCard(
              child: Row(
                children: [
                  Expanded( //現金股利按鈕
                    child: GestureDetector(
                      onTap: () => setState(() => _type = DividendType.cash),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == DividendType.cash
                              ? const Color(0xFFEEF7F2)
                              : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _type == DividendType.cash
                                ? const Color(0xFFB8DFC9)
                                : const Color(0xFFE4E7ED),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '現金股利',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize:14,
                            fontWeight:FontWeight.w700,
                            color: _type == DividendType.cash
                                ? const Color(0xFF3D9E6B)
                                : const Color(0xFF9AA3B2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded( //股票股利按鈕
                    child: GestureDetector(
                      onTap: () => setState(() => _type = DividendType.stock),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == DividendType.stock
                              ? const Color(0xFFEBF0F8)
                              : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _type == DividendType.stock
                                ? const Color(0xFFC5D4EC)
                                : const Color(0xFFE4E7ED),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '股票股利',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize:14,
                            fontWeight:FontWeight.w700,
                            color: _type == DividendType.stock
                                ? const Color(0xFF4A6FA5)
                                : const Color(0xFF9AA3B2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 基本資訊
            const SectionTitle(title: '基本資訊'),
            FormCard(
              child: Column(
                children: [
                  _DateField(
                    date: _date,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(1961),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  _AppField(
                    label: '股票代碼',
                    controller: _symbolCtrl,
                    onChanged: (v) => setState(() {
                      _symbol = v;
                      _name = mockStockMap[v] ?? '';
                    }),
                  ),
                  const SizedBox(height: 12),
                  _ReadOnly(label:'股票名稱', value: _name),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 金額計算
            const SectionTitle(title: '金額計算'),
            FormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── 現金股利欄位 ──
                  if (_type == DividendType.cash) ...[
                    Row( //第一排
                      children: [
                        Expanded(
                          child: _AppField(
                            label: '每股股利（元）',
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() =>
                              _pricePerShare = double.tryParse(v) ?? 0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AppField(
                            label: '持股股數',
                            controller: _sharesCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() =>
                              _heldShares = int.tryParse(v) ?? 0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row( //第二排
                      children: [
                        Expanded(
                          child: _AppField(
                            label: '手續費（元）',
                            controller: _feeCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() =>
                              _fee = double.tryParse(v) ?? 0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '二代健保（元）',
                                style: TextStyle(
                                  fontSize:12,
                                  fontWeight:FontWeight.w600,
                                  color:Color(0xFF5A6375),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE4E7ED),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _healthInsurance.toStringAsFixed(0),
                                      style: const TextStyle(
                                        fontSize:13,
                                        color:Color(0xFF5A6375),
                                      ),
                                    ),
                                    const Text(
                                      '自動',
                                      style: TextStyle(
                                        fontSize:10,
                                        color:Color(0xFF9AA3B2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_grossAmount > 0 && _grossAmount <= 20000)
                              const Text(
                                '未達 2 萬，免課',
                                style: TextStyle(
                                  fontSize:10,
                                  color:Color(0xFF9AA3B2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── 股票股利欄位 ──
                  if (_type == DividendType.stock) ...[
                    _AppField(
                      label: '配股股數',
                      controller: _shareAmtCtrl,
                       keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() =>
                        _shareAmount = int.tryParse(v) ?? 0),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '💡 配股後均價將被稀釋，庫存明細會自動重算',
                      style: TextStyle(
                        fontSize:11,
                        color: Color(0xFF3D9E6B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 入帳預覽（現金股利才顯示）
            if (_type == DividendType.cash && _grossAmount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF7F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB8DFC9)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column( //說明及試算
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '實際入帳金額',
                          style: TextStyle(
                            fontSize:12,
                            fontWeight:FontWeight.w600,
                            color:Color(0xFF3D9E6B),
                          ),
                        ),
                        Text(
                          '${_grossAmount.toInt()} − '
                          '${_fee.toInt()} − '
                          '${_healthInsurance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize:10,
                            color:Color(0xFF3D9E6B),
                          ),
                        ),
                      ],
                    ),
                    Text( //實際數字
                      '+${_netAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize:20,
                        fontWeight:FontWeight.w700,
                        color:Color(0xFF3D9E6B),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const SectionTitle(title: '備註'),
            FormCard(
              child: TextField(
                controller: _noteCtrl,
                maxLines: 3,
                onChanged: (v) => setState(() => _note = v),
                decoration: const InputDecoration(hintText: '選填備註…'),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('儲存股利紀錄'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AppField extends StatelessWidget { //輸入格子
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  const _AppField({
    required this.label, required this.controller,
    required this.onChanged, this.keyboardType,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize:12,
            fontWeight:FontWeight.w600,
            color:Color(0xFF5A6375),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}

class _ReadOnly extends StatelessWidget { //唯獨格子
  final String label, value;
  const _ReadOnly({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize:12,
            fontWeight:FontWeight.w600,
            color:Color(0xFF5A6375),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFE4E7ED),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.isEmpty ? '－' : value,
            style: const TextStyle(fontSize:13, color:Color(0xFF9AA3B2)),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget { //日期選擇格子
  final DateTime date;
  final VoidCallback onTap;
  const _DateField({required this.date, required this.onTap});
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
          border: Border.all(color: const Color(0xFFE4E7ED))),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size:16,
              color:Color(0xFF4A6FA5),
            ),
            const SizedBox(width: 8),
            Text(
              '${date.year} / '
              '${date.month.toString().padLeft(2,'0')} / '
              '${date.day.toString().padLeft(2,'0')}',
              style: const TextStyle(fontSize:13, color:Color(0xFF1A1F2E)),
            ),
          ],
        ),
      ),
    );
  }
}

const Map<String,String> mockStockMap = {
  '2330': '台積電',
  '2317': '鴻海',
  '2454': '聯發科',
  '0050': '元大台灣50',
};