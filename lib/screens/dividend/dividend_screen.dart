//股利頁面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../models/dividend.dart';
import '../../repositories/dividend_repository.dart';
import '../../widgets/common/app_filter_chip.dart';
import '../../widgets/common/hero_card.dart';
import '../../widgets/common/stats_strip.dart';
import '../../widgets/common/expanded_actions.dart';
import 'add_dividend_screen.dart';

class DividendScreen extends StatefulWidget {
  const DividendScreen({super.key});
  @override
  State<DividendScreen> createState() => _DividendScreenState();
}

enum _DivFilter {all, cash, stock}

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
              padding: const EdgeInsets.all(14),
              children: [
                HeroCard(
                  title: '累計股利收入',
                  colors: const [Color(0xFF2D6A4F), AppColors.loss],
                  mainValue: Text(
                    AppFmt.num(repo.totalCashDividend),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  stats: [
                    HeroStat(
                      label:'現金股利',
                      value: AppFmt.num(repo.totalCashDividend),
                    ),
                    HeroStat(
                      label:'股票股利',
                      value: '${repo.totalShareDividend} 股',
                    ),
                    HeroStat(
                      label:'扣費後淨額',
                      value: AppFmt.num(repo.totalNetCashDividend),
                      valueColor: const Color(0xFFB8F0D0),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
          
                StatsStrip(
                  cells: [
                    StatCell(label:'配息次數', value: '${all.length}'),
                    StatCell(label:'二代健保', value: AppFmt.num(repo.totalHealthInsurance)),
                    StatCell(label:'手續費', value: AppFmt.num(repo.totalFee)),
                  ],
                ),
                
                const SizedBox(height: 12),
          
                SingleChildScrollView( //Filter chips
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AppFilterChip(
                        label:'全部',
                        isActive: _filter == _DivFilter.all,
                        activeColor: AppColors.loss,
                        onTap: () => setState(() => _filter = _DivFilter.all),
                      ),
                      AppFilterChip(
                        label:'現金股利',
                        isActive: _filter == _DivFilter.cash,
                        activeColor: AppColors.loss,
                        onTap: () => setState(() => _filter = _DivFilter.cash),
                      ),
                      AppFilterChip(
                        label:'股票股利',
                        isActive: _filter == _DivFilter.stock,
                        activeColor: AppColors.loss,
                        onTap: () => setState(() => _filter = _DivFilter.stock),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
          
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
                      if (await ExpandedActions.confirmDelete(context)) {
                        repo.removeDividend(d.id);
                      }
                    },
                    onEdit: () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => AddDividendScreen(editingDividend: d)), //暫無編輯功能
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

class _DividendTile extends StatefulWidget { //股利卡片
  final Dividend dividend;
  final VoidCallback onDelete, onEdit;
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
            color: _expanded ? AppColors.primary : AppColors.border,
            width: _expanded ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius:4,
            offset: const Offset(0,1),
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
                          ? AppColors.lossBg
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCash ? Icons.payments_outlined : Icons.trending_up,
                      size: 18,
                      color: isCash
                          ? AppColors.loss
                          : AppColors.primary,
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
                                color:AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container( //分類標籤
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: isCash
                                    ? AppColors.lossBg
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isCash ? '現金' : '股票',
                                style: TextStyle(
                                  fontSize:9,
                                  fontWeight:FontWeight.w700,
                                  color: isCash ? AppColors.loss : AppColors.primary,
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
                        isCash ? AppFmt.pnl(d.cashAmount) : '+${d.shareAmount} 股',
                        style: TextStyle(
                          fontSize:14,
                          fontWeight:FontWeight.w700,
                          color: isCash ? AppColors.loss : AppColors.primary,
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
                color: AppColors.border,
                indent: 14,
                endIndent: 14,
              ),
              if (d.note != null && d.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notes_outlined,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          d.note!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: ExpandedActions(
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                )
              ),
            ],
          ],
        ),
      ),
    );
  }
}