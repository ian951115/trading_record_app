//新增目標頁面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/annual_goal.dart';
import '../../repositories/annual_goal_repository.dart';
import '../../widgets/common/form_card.dart';
import '../../widgets/common/section_title.dart';

class AddGoalScreen extends StatefulWidget {
  final AnnualGoal? existingGoal;
  const AddGoalScreen({super.key, this.existingGoal});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  late int _year;
  late double _target;
  late String _note;

  late final TextEditingController _targetCtrl;
  late final TextEditingController _noteCtrl;

  // 今年 ~ 今年+5 可選
  late final List<int> _yearOptions;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().year;
    _yearOptions = List.generate(6, (i) => now + i);

    final g = widget.existingGoal;
    _year = g?.year ?? now;
    _target = g?.targetPnL ?? 0;
    _note = g?.note ?? '';

    // 編輯時，若年份是過去的年份（不在 options 裡）也要能顯示
    if (!_yearOptions.contains(_year)) _yearOptions.insert(0, _year);

    _targetCtrl = TextEditingController(
      text: _target > 0 ? _target.toStringAsFixed(0) : '');
    _noteCtrl = TextEditingController(text: _note);
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (_target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入目標金額')));
      return;
    }

    final repo     = context.read<AnnualGoalRepository>();
    final existing = widget.existingGoal;

    // 新增時檢查該年是否已有目標
    if (existing == null && repo.hasGoalForYear(_year)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_year 年已有目標，請編輯現有目標')));
      return;
    }

    if (existing != null) {
      await repo.update(existing.copyWith(
        year:      _year,
        targetPnL: _target,
        note:      _note.isEmpty ? null : _note,
      ));
    } else {
      await repo.add(AnnualGoal(
        year:      _year,
        targetPnL: _target,
        note:      _note.isEmpty ? null : _note,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingGoal != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEdit ? '編輯年度目標' : '新增年度目標'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 年份 ──────────────────────
            const SectionTitle(title: '目標年份'),
            FormCard(
              child: DropdownButtonFormField<int>(
                value: _year,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                items: _yearOptions.map((y) =>
                  DropdownMenuItem(value: y, child: Text('$y年')),
                ).toList(),
                onChanged: (v) => setState(() => _year = v ?? _year),
              ),
            ),

            const SizedBox(height: 20),

            // ── 目標金額 ──────────────────
            const SectionTitle(title: '目標損益'),
            FormCard(
              child: TextField(
                controller: _targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                onChanged: (v) => setState(() {
                  _target = double.tryParse(v) ?? 0;
                }),
                decoration: const InputDecoration(
                  hintText: 'e.g. 100000',
                  suffixText: '元',
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
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? '更新' : '新增目標'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}