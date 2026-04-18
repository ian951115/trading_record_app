//定期定額確認畫面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/trade.dart';
import '../../repositories/recurring_repository.dart';
import '../../repositories/trade_repository.dart';
import '../../services/recurring_service.dart';
import '../../services/stock_price_service.dart';

class ConfirmRecurringScreen extends StatefulWidget {
  const ConfirmRecurringScreen({super.key});

  @override
  State<ConfirmRecurringScreen> createState() => _ConfirmRecurringScreenState();
}

class _ConfirmRecurringScreenState extends State<ConfirmRecurringScreen> {
  // 勾選狀態：key = scheduledDate.toString() + planId
  final Map<String, bool> _checked = {};
  // 手動輸入股數：key 同上
  final Map<String, TextEditingController> _qtyControllers = {};
  // 現價快取
  final Map<String, double?> _priceCache = {};

  bool _isSaving = false;

  List<PendingEntry> _pending = [];

  @override
  void initState() {
    super.initState();
    // initState 不能直接用 context.read，改用 addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPending();
    });
  }

  void _loadPending() {
    final recurringRepo = context.read<RecurringRepository>();
    final tradeRepo = context.read<TradeRepository>();
    final entries = RecurringService.getAllPendingEntries(
      activePlans: recurringRepo.getActive(),
      allTrades: tradeRepo.getAllTrades(),
    );
    setState(() {
      _pending = entries;
      //預設全部勾選（週末的除外）
      for (final e in entries) {
        final key = _key(e);
        _checked[key] = !e.isWeekend;
        _qtyControllers[key] = TextEditingController();
      }
    });
    //非同步批次查現價
    _fetchPrice(entries);
  }

  Future<void> _fetchPrice(List<PendingEntry> entries) async {
    final symbols = entries.map((e) => e.plan.symbol).toSet().toList();
    for (final sym in symbols) {
      final price = await StockPriceService.fetchPrice(sym);
      if (mounted) setState(() => _priceCache[sym] = price);
    }
    //用現價估算股數並填入 controller（若 controller 為空）
    for (final e in entries) {
      final key = _key(e);
      final price = _priceCache[e.plan.symbol];
      final ctrl = _qtyControllers[key];
      if (ctrl != null && ctrl.text.isEmpty && price != null && price > 0) {
        final est = RecurringService.estimateShares(
          amount: e.plan.amountPerTime,
          price: price,
        );
        if (mounted) setState(() => ctrl.text = '$est');
      }
    }
  }

  String _key(PendingEntry e) =>
      '${e.plan.id}_${e.scheduledDate.millisecondsSinceEpoch}';

  // ── 計算勾選合計 ─────────────────────────────
  double get _checkedTotal {
    double total = 0;
    for (final e in _pending) {
      final key = _key(e);
      if (_checked[key] == true) total += e.plan.amountPerTime;
    }
    return total;
  }

  int get _checkedCount =>
      _checked.values.where((v) => v == true).length;

  // ── 確認入帳 ─────────────────────────────────
  Future<void> _confirm() async {
    if (_checkedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請勾選至少一筆'))
      );
      return;
    }
    setState(() => _isSaving = true);
    final tradeRepo = context.read<TradeRepository>();

    for (final e in _pending) {
      final key = _key(e);
      if (_checked[key] != true) continue;

      //取股數
      final qtyText = _qtyControllers[key]?.text ?? '';
      final qty = int.tryParse(qtyText) ?? 0;
      if (qty <= 0) continue; //股數為0跳過

      //計算成交價（金額 ÷ 股數）
      final price = e.plan.amountPerTime / qty;

      final trade = Trade(
        date: e.scheduledDate,
        symbol: e.plan.symbol,
        name: e.plan.name,
        type: TradeType.buy,
        price: price,
        quantity: qty,
        fee: 0, //定期定額手續費另計，此處留0
        note: '定期定額',
      );
      await tradeRepo.addTrade(trade);
    }

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已完成入帳！'))
      );
    }
  }

  @override
  void dispose() {
    for (final c in _qtyControllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(title: const Text('補帳確認')),
      body: _pending.isEmpty
          ? const Center(
            child: Text(
              '目前沒有待確認的紀錄',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9AA3B2),
              ),
            ),
          )
          : Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    ..._pending.map((e) => _EntryTile(
                      entry: e,
                      isChecked: _checked[_key(e)] ?? false,
                      qtyCtrl: _qtyControllers[_key(e)]!,
                      price: _priceCache[e.plan.symbol],
                      onToggle: (v) => setState(
                        () => _checked[_key(e)] = v,
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ── 底部合計 + 確認按鈕 ──────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE4E7ED))),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '勾選 $_checkedCount 筆  ·  合計',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5A6375),
                          ),
                        ),
                        Text(
                          '${fmt.format(_checkedTotal.toInt())} 元',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A6FA5)
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _confirm,
                        child: _isSaving
                            ? const SizedBox(
                              height: 18, width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white,
                              ),
                            )
                            : const Text('確認入帳'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

// ── 單筆待確認項目 ────────────────────────────
class _EntryTile extends StatelessWidget {
  final PendingEntry entry;
  final bool isChecked;
  final TextEditingController qtyCtrl;
  final double? price; //現價（可能為 null）
  final ValueChanged<bool> onToggle;

  const _EntryTile({
    required this.entry,
    required this.isChecked,
    required this.qtyCtrl,
    required this.price,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final fmt = NumberFormat('#,###');
    final d = e.scheduledDate;
    final dateStr = '${d.year}/${d.month.toString().padLeft(2,"0")}'
        '/${d.day.toString().padLeft(2,"0")}';
    final weekdays = ['一','二','三','四','五','六','日'];
    final weekday = weekdays[d.weekday - 1];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isChecked ? Colors.white : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isChecked
              ? const Color(0xFF4A6FA5)
              : const Color(0xFFE4E7ED),
          width: isChecked ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector( //勾選框
            onTap: () => onToggle(!isChecked),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: isChecked
                    ? const Color(0xFF4A6FA5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isChecked
                      ? const Color(0xFF4A6FA5)
                      : const Color(0xFFD0D8E8),
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded( //內容
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 第一行：股票名稱 + 代碼
                Text(
                  '${e.plan.name} (${e.plan.symbol})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1F2E),
                  ),
                ),
                const SizedBox(height: 4),
                // 第二行：日期 + 星期
                Row(
                  children: [
                    Text(
                      '$dateStr（$weekday）',
                      style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9AA3B2),
                      ),
                    ),
                    if (e.isWeekend) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '假日',
                          style: TextStyle(
                            fontSize: 10, color: Color(0xFFE07B20),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // 第三行：股數輸入 + 金額
                Row(
                  children: [
                    Expanded( //股數
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '股數',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9AA3B2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 36,
                            child: TextField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                                hintText: price == null ? '請輸入' : '估算中…',
                                suffixText: '股',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column( //金額(固定)
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '扣款金額',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9AA3B2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${fmt.format(e.plan.amountPerTime.toInt())} 元',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A6FA5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}