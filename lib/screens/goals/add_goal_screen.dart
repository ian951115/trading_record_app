//新增目標頁面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/annual_goal.dart';
import '../../models/custom_goal.dart';
import '../../models/goal_type.dart';
import '../../repositories/annual_goal_repository.dart';
import '../../repositories/custom_goal_repository.dart';
import '../../services/data/stock_name_service.dart';
import '../../core/enum_ext.dart';
import '../../widgets/common/form_card.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/app_snack_bar.dart';
import '../../widgets/common/app_filter_chip.dart';

class AddGoalScreen extends StatefulWidget {
  final GoalMode? initialMode;
  final AnnualGoal? existingAnnual;
  final CustomGoal? existingCustom;
  const AddGoalScreen({
    super.key,
    this.initialMode,
    this.existingAnnual,
    this.existingCustom,
  });

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  // ── controllers ──────────────────────────────────────
  late final TextEditingController _titleCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _stockNameCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _noteCtrl;

  // ── 共用 state ───────────────────────────────────────
  late GoalType _goalType;
  late String? _stockSymbol;
  late String? _stockName;
  late double _targetAmount;
  late String _note;
  late GoalMode _mode;

  // ── 年度目標專用 ──────────────────────────────────────
  late int _year;
  late final List<int> _yearOptions; //年份選擇
 
  // ── 自訂義目標專用 ────────────────────────────────────
  late String _title;
  late DateTime _startDate;
  late DateTime _endDate;
  String _quickKey = '本月';  //快捷日期當前選項

  static const _quickKeys = ['本週', '本月', '本季', '本年', '自訂'];
  bool _isFetchingName = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _yearOptions = List.generate(
      DateTime.now().year - 1960 + 2, //1960年到未來兩年
      (i) => 1960 + i,
    );

    _mode = widget.initialMode ?? GoalMode.annual;
    _startDate = DateTime.now();
    _endDate = DateTime(DateTime.now().year, 12, 31);
    _title = '';
    _note = '';
    if (_mode == GoalMode.annual) {
      final g = widget.existingAnnual;
      _year = g?.year ?? now.year;
      _goalType = g?.goalType ?? GoalType.totalPnL;
      _stockSymbol = g?.stockSymbol;
      _stockName = g?.stockName;
      _targetAmount = g?.targetPnL ?? 0;
      _note = g?.note ?? '';
    } else {
      final g = widget.existingCustom;
      _title = g?.title ?? '';
      _goalType = g?.goalType ?? GoalType.totalPnL;
      _stockSymbol = g?.stockSymbol;
      _stockName = g?.stockName;
      _targetAmount = g?.targetAmount ?? 0;
      _note = g?.note ?? '';
      // 日期：預設本月
      final range = g != null
          ? DateTimeRange(start: g.startDate, end: g.endDate)
          : _quickRange('本月');
      _startDate = range.start;
      _endDate = range.end;
    }

    // 初始化 controllers
    _titleCtrl = TextEditingController(text: _mode == GoalMode.custom ? _title : '');
    _stockCtrl = TextEditingController(text: _stockSymbol ?? '');
    _stockNameCtrl = TextEditingController(text: _stockName ?? '');
    _targetCtrl = TextEditingController(
      text: _targetAmount > 0 ? _targetAmount.toInt().toString() : '');
    _noteCtrl = TextEditingController(text: _note);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _stockCtrl.dispose();
    _stockNameCtrl.dispose();
    _targetCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── 自動查股票名稱 ──────────────────────────────────────
  Future<void> _onSymbolChanged(String value) async {
    final trimmed = value.trim();
    setState(() => _stockSymbol = trimmed.isEmpty ? null : trimmed);
    final name = StockNameService.getName(trimmed);
    if (name != null) {
      setState(() => _stockName = name);
      _stockNameCtrl.text = name;
      return;
    }
    setState(() => _stockName = '');
    _stockNameCtrl.text = '';
  }

  // ── 快捷日期範圍 ──────────────────────────────────────
  DateTimeRange _quickRange(String key) {
    final now = DateTime.now();
    switch (key) {
      case '本週':
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return DateTimeRange(start: _dateOnly(start), end: _dateOnly(end));
      case '本月':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case '本季':
        final q = (now.month - 1) ~/ 3;
        return DateTimeRange(
          start: DateTime(now.year, q * 3 + 1, 1),
          end: DateTime(now.year, q * 3 + 4, 0),
        );
      case '本年':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
      default:
        return DateTimeRange(start: _dateOnly(now), end: _dateOnly(now));
    }
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  void _save() async {
    if (_targetAmount <= 0) {
      AppSnackBar.showError(context, '請輸入目標金額');
      return;
    }
 
    if (_mode == GoalMode.annual) {
      if (_goalType == GoalType.stockPnL &&
          (_stockSymbol == null || _stockSymbol!.trim().isEmpty)) {
        AppSnackBar.showError(context, '請輸入股票代號');
        return;
      }
      final repo = context.read<AnnualGoalRepository>();
      // 新增時防重複
      if (widget.existingAnnual == null &&
          repo.hasGoalForYearAndType(_year, _goalType, symbol: _stockSymbol)) {
        AppSnackBar.showError(context, '同年份、同標的的目標已存在');
        return;
      }
      final g = AnnualGoal(
        id: widget.existingAnnual?.id,
        year: _year,
        targetPnL: _targetAmount,
        note: _note.orNull,
        goalTypeStr: _goalType.name,
        stockSymbol: _stockSymbol,
        stockName: _stockName,
      );
      widget.existingAnnual != null ? await repo.update(g) : await repo.add(g);
    } else {
      if (_title.trim().isEmpty) {
        AppSnackBar.showError(context, '請輸入目標標題');
        return;
      }
      if (_goalType == GoalType.stockPnL &&
          (_stockSymbol == null || _stockSymbol!.trim().isEmpty)) {
        AppSnackBar.showError(context, '請輸入股票代號');
        return;
      }
      final repo = context.read<CustomGoalRepository>();
      final g = CustomGoal(
        id: widget.existingCustom?.id,
        title: _title.trim(),
        goalTypeStr: _goalType.name,
        stockSymbol: _stockSymbol,
        stockName: _stockName,
        targetAmount: _targetAmount,
        startDate: _startDate,
        endDate: _endDate,
        note: _note.orNull,
      );
      widget.existingCustom != null ? await repo.update(g) : await repo.add(g);
    }

    if (mounted) Navigator.pop(context);
  }

  // ── 追蹤'標的'的 ToggleButtons ────────────────────────────
  Widget _buildGoalTypeToggle() => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F2F7),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        _toggleBtn(GoalType.totalPnL, '📊 總損益'),
        _toggleBtn(GoalType.stockPnL, '📈 個股損益'),
      ],
    ),
  );

  Widget _toggleBtn(GoalType type, String label) {
    final selected = _goalType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _goalType = type;
          if (type == GoalType.totalPnL) { //追蹤總損益所以不用
            _stockSymbol = null;
            _stockName = null;
            _stockCtrl.clear();
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ── 快捷日期 Chips ────────────────────────────────────
  Widget _buildQuickDateChips() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),
      const SectionTitle(title: '日期範圍'),
      SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: _quickKeys.map((k) => AppFilterChip(
              label: k,
              isActive: _quickKey == k,
              onTap: () async {
                if (k == '自訂') {
                  final r = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1960),
                    lastDate: DateTime(2099),
                    initialDateRange: DateTimeRange(
                      start: _startDate,
                      end: _endDate,
                    ),
                  );
                  if (r != null) setState(() {
                    _quickKey = '自訂';
                    _startDate = r.start;
                    _endDate = r.end;
                  });
                } else {
                  final r = _quickRange(k);
                  setState(() {
                    _quickKey = k;
                    _startDate = r.start;
                    _endDate = r.end;
                  });
                }
              },
            )).toList(),
          ),
        ),
      ),
      const SizedBox(height: 8),
      // 日期顯示
      FormCard(
        child: Column(
          children: [
            _dateRow('開始', _startDate),
            const Divider(height: 1),
            _dateRow('結束', _endDate),
          ],
        ),
      ),
    ],
  );

  Widget _dateRow(String label, DateTime date) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          _fmtDate(date),
          style: const TextStyle(fontSize: 14, color: AppColors.textSecond),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingAnnual != null || widget.existingCustom != null;
    final modeLabel = _mode == GoalMode.annual ? '年度目標' : '自訂義目標';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${isEdit ? '編輯' : '新增'} $modeLabel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 基本資訊：目標種類（新增時才顯示）+ 年份／標題 ──
            const SectionTitle(title: '基本資訊'),
            FormCard(
              child: Column(
                children: [
                  if (widget.initialMode == null) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          _ModeTab(
                            label: '年度目標',
                            isActive: _mode == GoalMode.annual,
                            onTap: () => setState(() {
                              _mode = GoalMode.annual;
                              _titleCtrl.text = '';
                            }),
                          ),
                          _ModeTab(
                            label: '自定義目標',
                            isActive: _mode == GoalMode.custom,
                            onTap: () => setState(() {
                              _mode = GoalMode.custom;
                              _titleCtrl.text = _title;
                              if (_endDate.isBefore(_startDate)) {
                                _endDate = DateTime(_startDate.year, 12, 31);
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                  ],
                  _mode == GoalMode.custom
                      ? TextField(
                          controller: _titleCtrl,
                          onChanged: (v) => setState(() => _title = v),
                          decoration: const InputDecoration(
                            hintText: 'e.g. 五月衝刺計畫',
                            border: InputBorder.none,
                          ),
                      )
                      : DropdownButtonFormField<int>(
                        initialValue: _year,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                          isDense: true,
                        ),
                        items: _yearOptions.map((y) =>
                            DropdownMenuItem(value: y, child: Text('$y 年')),
                        ).toList(),
                        onChanged: (v) => setState(() => _year = v ?? _year),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 追蹤標的（含個股代號/名稱，條件顯示）──
            const SectionTitle(title: '追蹤標的'),
            FormCard(
              child: Column(
                children: [
                  _buildGoalTypeToggle(),
                  if (_goalType == GoalType.stockPnL) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    const _FieldLabel(label: '股票代號'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: _onSymbolChanged,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 2330',
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel(label: '股票名稱'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _stockNameCtrl,
                      onChanged: (v) => setState(() => _stockName = v.isEmpty ? null : v),
                      decoration: InputDecoration(
                        hintText: '自動填入或手動輸入',
                        border: InputBorder.none,
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
                ],
              ),
            ),

            // ── 自訂義：日期範圍 ──────────────
            if (_mode == GoalMode.custom) _buildQuickDateChips(),

            const SizedBox(height: 20),

            // ── 目標金額 ──────────────────
            const SectionTitle(title: '目標損益'),
            FormCard(
              child: TextField(
                controller: _targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                onChanged: (v) => setState(() {
                  _targetAmount = double.tryParse(v) ?? 0;
                }),
                decoration: const InputDecoration(
                  hintText: 'e.g. 100000',
                  suffixText: '元',
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── 備註 ──────────────────────
            const SectionTitle(title: '備註（選填）'),
            FormCard(
              child: TextField(
                controller: _noteCtrl,
                onChanged: (v) => setState(() => _note = v),
                decoration: const InputDecoration(
                  hintText: 'e.g. 目標存到頭期款',
                  border: InputBorder.none,
                ),
              ),
            ),

            // ── 年度目標說明提示 ──────────────
            if (_mode == GoalMode.annual) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📌 關於年度目標',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '年度目標固定追蹤 1/1 – 12/31 的損益。\n'
                      '同一年份可新增多個目標（總損益 + 個股）。\n'
                      '總損益目標會固定顯示在最上方。',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecond,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isEdit ? '更新目標' : '新增目標',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 32),
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
        color: AppColors.textSecond,
      ),
    ),
  );
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}