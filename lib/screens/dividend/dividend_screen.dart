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
import '../../widgets/tiles/dividend_tile.dart';
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: HeroCard(
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
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              children: [
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
                  ...filtered.map((d) => DividendTile(
                    dividend: d,
                    onDelete: () async {
                      if (await ExpandedActions.confirmDelete(context)) {
                        repo.removeDividend(d.id);
                      }
                    },
                    onEdit: () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => AddDividendScreen(editingDividend: d)),
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