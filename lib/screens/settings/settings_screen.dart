//設定頁面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../repositories/settings_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsRepo = context.watch<SettingsRepository>();
    if (!settingsRepo.isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final settings = settingsRepo.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [

          // ── App 資訊 ──────────────────────
          _AboutCard(),
          const SizedBox(height: 20),

          // ── 顯示設定 ──────────────────────
          const _SectionLabel(title: '顯示設定'),
          _SettingsGroup(
            children: [
              _SettingsToggleRow(
                icon: Icons.palette_outlined,
                iconBg: const Color(0xFFFDF0EF),
                iconColor: const Color(0xFFE8504A),
                title: '紅漲綠跌',
                subtitle: '台灣慣例，關閉後改為綠漲紅跌',
                value: settings.redUpGreenDown,
                onChanged: (v) {
                  if (!v) {
                    _showComingSoon(context, '綠漲紅跌');
                    return;
                  }
                  settingsRepo.updateColorScheme(v);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── 交易設定 ──────────────────────
          const _SectionLabel(title: '交易設定'),
          _SettingsGroup(
            children: [
              _SettingsNavRow(
                icon: Icons.calculate_outlined,
                iconBg: const Color(0xFFEBF0F8),
                iconColor: const Color(0xFF4A6FA5),
                title: '損益計算方式',
                subtitle: '影響庫存成本與已實現損益',
                value: settings.pnlMethod == 'fifo' ? 'FIFO' : '加權平均',
                onTap: () {
                  if (settings.pnlMethod == 'fifo') {
                    _showComingSoon(context, '加權平均計算');
                    return;
                  }
                  settingsRepo.updatePnLMethod(settings.pnlMethod);
                  _showPnlMethodSheet(context, settingsRepo);
                },
              ),
              _SettingsDivider(),
              _SettingsNavRow(
                icon: Icons.percent,
                iconBg: const Color(0xFFEBF0F8),
                iconColor: const Color(0xFF4A6FA5),
                title: '預設手續費率',
                subtitle: '新增交易時自動帶入',
                value: '${(settings.defaultFeeRate * 100).toStringAsFixed(4)}%',
                onTap: () => _showFeeRateSheet(context, settingsRepo),
              ),
              _SettingsDivider(),
              _SettingsNavRow(
                icon: Icons.receipt_outlined,
                iconBg: const Color(0xFFEBF0F8),
                iconColor: const Color(0xFF4A6FA5),
                title: '預設證交稅率',
                subtitle: '賣出時自動帶入',
                value: '${(settings.defaultTaxRate * 100).toStringAsFixed(3)}%',
                onTap: () => _showTaxRateSheet(context, settingsRepo),
              ),
              _SettingsDivider(),
              _SettingsNavRow(
                icon: Icons.money_off_outlined,
                iconBg: const Color(0xFFEBF0F8),
                iconColor: const Color(0xFF4A6FA5),
                title: '最低手續費',
                subtitle: '低於此金額時使用最低費用',
                value: '股 ${settings.minFeePerShare.toInt()}元・張 ${settings.minFeePerLot.toInt()}元',
                onTap: () => _showMinFeeSheet(context, settingsRepo),
              ),
              _SettingsDivider(),
              _SettingsNavRow(
                icon: Icons.currency_exchange,
                iconBg: const Color(0xFFEBF0F8),
                iconColor: const Color(0xFF4A6FA5),
                title: '定期定額手續費',
                subtitle: '每筆定期定額入帳的預設手續費',
                value: '${settings.recurringFeeDefault.toInt()}元',
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => _NumberInputSheet(
                    title: '定期定額費率',
                    hint: '例如 1',
                    suffix: '元',
                    initialValue: settings.recurringFeeDefault.toStringAsFixed(0),
                    onSave: (v) {
                      final fee = double.tryParse(v);
                      if (fee != null) settingsRepo.updateRecurringFee(fee);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── 資金設定 ──────────────────────
          const _SectionLabel(title: '資金設定'),
          _SettingsGroup(
            children: [
              _SettingsNavRow(
                icon: Icons.water_outlined,
                iconBg: const Color(0xFFEEF7F2),
                iconColor: const Color(0xFF3D9E6B),
                title: '資金水位警戒線',
                subtitle: '低於此比例時顯示警告',
                value: '${(settings.waterLevelThreshold * 100).toInt()}%',
                onTap: () => _showWaterLevelSheet(context, settingsRepo),
              ),
              _SettingsDivider(),
              _SettingsToggleRow(
                icon: Icons.savings_outlined,
                iconBg: const Color(0xFFEEF7F2),
                iconColor: const Color(0xFF3D9E6B),
                title: '新增買入時預設記錄入金',
                subtitle: '開啟後同時記錄入金預設為開',
                value: settings.autoDepositDefault,
                onChanged: (v) => settingsRepo.updateAutoDepositDefault(v),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── 資料管理 ──────────────────────
          const _SectionLabel(title: '資料管理'),
          _SettingsGroup(
            children: [
              _SettingsNavRow(
                icon: Icons.upload_file_outlined,
                iconBg: const Color(0xFFF7F8FA),
                iconColor: const Color(0xFF9AA3B2),
                title: '匯出資料',
                subtitle: '匯出為 CSV 檔案',
                onTap: () => _showComingSoon(context, '匯出資料'),
              ),
              _SettingsDivider(),
              _SettingsNavRow(
                icon: Icons.delete_outline,
                iconBg: const Color(0xFFFDF0EF),
                iconColor: const Color(0xFFE8504A),
                title: '清除所有資料',
                subtitle: '此操作無法復原',
                titleColor: const Color(0xFFE8504A),
                onTap: () => _showClearDataDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── 底部表單 ────────────────────────

  void _showPnlMethodSheet(
    BuildContext context,
    SettingsRepository repo,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PnlMethodSheet(repo: repo),
    );
  }

  void _showFeeRateSheet(
    BuildContext context,
    SettingsRepository repo,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NumberInputSheet(
        title: '預設手續費率',
        hint: '例如 0.0855',
        suffix: '%',
        initialValue: (repo.settings.defaultFeeRate * 100).toStringAsFixed(4),
        onSave: (v) {
          final rate = double.tryParse(v);
          if (rate != null) repo.updateFeeRate(rate / 100);
        },
      ),
    );
  }

  void _showTaxRateSheet(
    BuildContext context,
    SettingsRepository repo,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NumberInputSheet(
        title: '預設證交稅率',
        hint: '例如 0.300',
        suffix: '%',
        initialValue: (repo.settings.defaultTaxRate * 100).toStringAsFixed(3),
        onSave: (v) {
          final rate = double.tryParse(v);
          if (rate != null) repo.updateTaxRate(rate / 100);
        },
      ),
    );
  }

  void _showMinFeeSheet(
    BuildContext context,
    SettingsRepository repo,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MinFeeSheet(repo: repo),
    );
  }

  void _showWaterLevelSheet(
    BuildContext context,
    SettingsRepository repo,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NumberInputSheet(
        title: '資金水位警戒線',
        hint: '例如 30',
        suffix: '%',
        initialValue: (repo.settings.waterLevelThreshold * 100).toInt().toString(),
        onSave: (v) {
          final pct = double.tryParse(v);
          if (pct != null) repo.updateWaterLevel(pct / 100);
        },
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清除所有資料'),
        content: const Text('確定要清除所有交易紀錄和資金紀錄嗎？\n\n此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              //之後實作
              Navigator.pop(context);
            },
            child: const Text(
              '清除',
              style: TextStyle(color: Color(0xFFE8504A)),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(feature),
        content: const Text('此功能開發中，敬請期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }
}

//底部表單內容
class _PnlMethodSheet extends StatelessWidget {
  final SettingsRepository repo;
  const _PnlMethodSheet({required this.repo});

  @override
  Widget build(BuildContext context) {
    final current = repo.settings.pnlMethod;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          const Text(
            '損益計算方式',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1F2E),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '影響庫存平均成本與已實現損益的計算方式',
            style: TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
          ),
          const SizedBox(height: 16),
          _OptionTile(
            title: 'FIFO（先進先出）',
            subtitle: '最先買入的股票最先賣出計算損益，與多數台灣券商一致',
            isSelected: current == 'fifo',
            onTap: () {
              repo.updatePnLMethod('fifo');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          _OptionTile(
            title: '加權平均成本',
            subtitle: '以所有買入的平均成本計算損益，台灣稅務申報常用',
            isSelected: current == 'avg',
            onTap: () {
              repo.updatePnLMethod('avg');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MinFeeSheet extends StatefulWidget {
  final SettingsRepository repo;
  const _MinFeeSheet({required this.repo});

  @override
  State<_MinFeeSheet> createState() => _MinFeeSheetState();
}

class _MinFeeSheetState extends State<_MinFeeSheet> {
  late final TextEditingController _shareController;
  late final TextEditingController _lotController;

  @override
  void initState() {
    super.initState();
    _shareController = TextEditingController(
      text: widget.repo.settings.minFeePerShare.toInt().toString(),
    );
    _lotController = TextEditingController(
      text: widget.repo.settings.minFeePerLot.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _shareController.dispose();
    _lotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          const Text(
            '最低手續費',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1F2E),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '計算手續費時若低於此金額，改用最低費用',
            style: TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
          ),
          const SizedBox(height: 16),
          Row( //輸入區
            children: [
              Expanded(
                child: _SheetField(
                  label: '以股交易（元）',
                  controller: _shareController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetField(
                  label: '以張交易（元）',
                  controller: _lotController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox( //儲存
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.repo.updateMinFees(
                  perShare: double.tryParse(_shareController.text),
                  perLot: double.tryParse(_lotController.text),
                );
                Navigator.pop(context);
              },
              child: const Text('儲存'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberInputSheet extends StatefulWidget {
  final String title;
  final String hint;
  final String suffix;
  final String initialValue;
  final void Function(String) onSave;

  const _NumberInputSheet({
    required this.title,
    required this.hint,
    required this.suffix,
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_NumberInputSheet> createState() => _NumberInputSheetState();
}

class _NumberInputSheetState extends State<_NumberInputSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          Text( //標題
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1F2E),
            ),
          ),
          const SizedBox(height: 16),
          TextField( //輸入框
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: widget.hint,
              suffixText: widget.suffix,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox( //按鈕
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_controller.text);
                Navigator.pop(context);
              },
              child: const Text('儲存'),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 共用小元件
// ══════════════════════════════════════════════

class _AboutCard extends StatelessWidget { //名稱及版本顯示
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3D5A8A), Color(0xFF4A6FA5)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A6FA5).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.show_chart,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '交易紀錄',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F2E),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9AA3B2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget { //區塊標題
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9AA3B2),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget { //區塊
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget { //分隔線
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 56);
  }
}

class _SettingsToggleRow extends StatelessWidget { //開關切換
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container( //左邊徽章
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded( //中間資訊
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1F2E),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9AA3B2),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF4A6FA5),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsNavRow extends StatelessWidget { //點擊彈出下方表單
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? value;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsNavRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.value,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container( //左邊徽章
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded( //中間資訊
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? const Color(0xFF1A1F2E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9AA3B2),
                    ),
                  ),
                ],
              ),
            ),
            if (value != null) ...[ //右邊顯示設定值
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5A6375),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon( //最右邊箭頭
              Icons.chevron_right,
              size: 18,
              color: Color(0xFF9AA3B2),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget { //底部表單上方佔位
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36, height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE4E7ED),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEBF0F8)
              : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A6FA5)
                : const Color(0xFFE4E7ED),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded( //選項文本區
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF4A6FA5)
                          : const Color(0xFF1A1F2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9AA3B2),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) //右邊勾勾
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4A6FA5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _SheetField({
    required this.label,
    required this.controller,
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
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: '元'),
        ),
      ],
    );
  }
}