//股利頁面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../models/dividend.dart';
import '../../repositories/dividend_repository.dart';
import '../../widgets/common/stats_strip.dart';
import 'add_dividend_screen.dart';

class DividendScreen extends StatefulWidget {
  const DividendScreen({super.key});
  @override
  State<DividendScreen> createState() => _DividendScreenState();
}

enum _DivFilter { all, cash, stock }

class _DividendScreenState extends State<DividendScreen> {
  _DivFilter _filter = _DivFilter.all;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<DividendRepository>();
    final all = repo.getAllDividends();

    final filtered = switch (_filter) {
      _DivFilter.all => all,
      _DivFilter.cash => all
        .where((d) => d.type == DividendType.cash).toList(),
      _DivFilter.stock => all
        .where((d) => d.type == DividendType.stock).toList(),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('股利紀錄')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Container( //Hero卡片
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2D6A4F),AppColors.loss],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: AppColors.loss.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '累計股利收入',
                        style: TextStyle(
                          fontSize:10,
                          color:Colors.white60,
                          letterSpacing:1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppFmt.num(repo.totalCashDividend),
                        style: const TextStyle(
                          fontSize:24, fontWeight:FontWeight.w700,
                          color:Colors.white)),
                      const SizedBox(height: 14),
                      const Divider(color:Colors.white24, height:1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _DivHeroStat(
                            label:'現金股利',
                            value: AppFmt.num(repo.totalCashDividend),
                          ),
                          _DivHeroDivider(),
                          _DivHeroStat(
                            label:'股票股利',
                            value: '${repo.totalShareDividend} 股',
                          ),
                          _DivHeroDivider(),
                          _DivHeroStat(
                            label:'扣費後淨額',
                            value: AppFmt.num(repo.totalNetCashDividend),
                            valueColor: const Color(0xFFB8F0D0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
          
                Padding( //Stats
                  padding: const EdgeInsets.symmetric(horizontal:14),
                  child: StatsStrip(
                    cells: [
                      StatCell(
                        label:'配息次數',
                        value: '${all.length}',
                      ),
                      StatCell(
                        label:'二代健保',
                        value: AppFmt.num(repo.totalHealthInsurance),
                      ),
                      StatCell(
                        label:'手續費',
                        value: AppFmt.num(repo.totalFee),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
          
                SingleChildScrollView( //Filter chips
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal:14, vertical:6),
                  child: Row(
                    children: [
                      _DivFilterChip(
                        label:'全部',
                        isActive: _filter == _DivFilter.all,
                        onTap: () => setState(() => _filter = _DivFilter.all),
                      ),
                      _DivFilterChip(
                        label:'現金股利',
                        isActive: _filter == _DivFilter.cash,
                        onTap: () => setState(() => _filter = _DivFilter.cash),
                      ),
                      _DivFilterChip(
                        label:'股票股利',
                        isActive: _filter == _DivFilter.stock,
                        onTap: () => setState(() => _filter = _DivFilter.stock),
                      ),
                    ],
                  ),
                ),
          
                Padding( //列表標題
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                  child: Text(
                    '股利紀錄',
                    style: const TextStyle(
                      fontSize:14,
                      fontWeight:FontWeight.w700,
                      color:Color(0xFF1A1F2E),
                    ),
                  ),
                ),
          
                if (filtered.isEmpty) //列表
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        '尚無股利紀錄',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),      
                  )
                else
                  ...filtered.map((d) => _DividendTile(
                    dividend: d,
                    onDelete: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('確認刪除'),
                          content: const Text('確定要刪除這筆股利紀錄？\n此操作無法復原。'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.profit),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('刪除'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) repo.removeDividend(d.id);
                    },
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddDividendScreen(), //暫無編輯功能
                      ),
                    ),
                  )),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.loss,
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AddDividendScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DivHeroStat extends StatelessWidget { //Hero統計小元件
  final String label, value;
  final Color valueColor;
  const _DivHeroStat({
    required this.label, required this.value,
    this.valueColor = Colors.white,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize:9, color:Colors.white60),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize:12,
            fontWeight:FontWeight.w700,
            color:valueColor,
          ),
        ),
      ],
    ),
  );
}

class _DivHeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width:1, height:28, color:Colors.white24,
    margin: const EdgeInsets.symmetric(horizontal:4));
}

class _DivFilterChip extends StatelessWidget { //篩選Chip
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _DivFilterChip({
    required this.label, required this.isActive,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds:150),
      margin: const EdgeInsets.only(right:8),
      padding: const EdgeInsets.symmetric(horizontal:14, vertical:6),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.loss
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppColors.loss
              : const Color(0xFFE4E7ED)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize:12,
          fontWeight:FontWeight.w600,
          color: isActive
              ? Colors.white
              : const Color(0xFF5A6375),
        ),
      ),
    ),
  );
}

class _DividendTile extends StatefulWidget { //股利卡片
  final Dividend dividend;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _DividendTile({
    required this.dividend,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_DividendTile> createState() => _DividendTileState();
}

class _DividendTileState extends State<_DividendTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.dividend;
    final isCash = d.type == DividendType.cash;
    final dateStr = '${d.date.year}/'
        '${d.date.month.toString().padLeft(2,'0')}/'
        '${d.date.day.toString().padLeft(2,'0')}';

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _expanded
                ? const Color(0xFF4A6FA5)
                : const Color(0xFFE4E7ED),
            width: _expanded ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius:4, offset: const Offset(0,1),
          )],
        ),
        child: Column(
          children: [
            // ── 主行（永遠顯示）──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child:  Row(
                children: [
                  Container( //左側圖示
                    width:36, height:36,
                    decoration: BoxDecoration(
                      color: isCash
                          ? const Color(0xFFEEF7F2)
                          : const Color(0xFFEBF0F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCash
                          ? Icons.payments_outlined
                          : Icons.trending_up,
                      size:18,
                      color: isCash
                          ? AppColors.loss
                          : const Color(0xFF4A6FA5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded( //中間資訊
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text( //名稱及股號
                              '${d.name} (${d.symbol})',
                              style: const TextStyle(
                                fontSize:13,
                                fontWeight:FontWeight.w700,
                                color:Color(0xFF1A1F2E),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container( //分類標籤
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: isCash
                                    ? const Color(0xFFEEF7F2)
                                    : const Color(0xFFEBF0F8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isCash ? '現金' : '股票',
                                style: TextStyle(
                                  fontSize:9,
                                  fontWeight:FontWeight.w700,
                                  color: isCash
                                      ? AppColors.loss
                                      : const Color(0xFF4A6FA5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text( //第二排日期及數量
                          isCash
                            ? '$dateStr · 每股 ${d.cashAmount / (d.shareAmount > 0 ? d.shareAmount : 1)} 元'
                            : '$dateStr · 配股 ${d.shareAmount} 股',
                          style: const TextStyle(fontSize:11, color:AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Column( //右側金額
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isCash
                          ? AppFmt.pnl(d.cashAmount)
                          : '+${d.shareAmount} 股',
                        style: TextStyle(
                          fontSize:14,
                          fontWeight:FontWeight.w700,
                          color: isCash
                              ? AppColors.loss
                              : const Color(0xFF4A6FA5),
                        ),
                      ),
                      if (isCash && d.netCashAmount != d.cashAmount)
                      Text(
                        '淨 ${AppFmt.num(d.netCashAmount)}',
                        style: const TextStyle(
                          fontSize:10,
                          color:AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── 展開行（編輯/刪除按鈕）──────────
            if (_expanded) ...[
              Divider(
                height: 1,
                color: const Color(0xFFE4E7ED),
                indent: 14,
                endIndent: 14,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onEdit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF0F8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: Color(0xFF4A6FA5),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '編輯',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A6FA4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onDelete,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF0EF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 14,
                                color: AppColors.profit,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '刪除',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.profit,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}