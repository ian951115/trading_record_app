//App設定模型
import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 6)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool redUpGreenDown; //紅漲綠跌

  @HiveField(1)
  String pnlMethod; //損益計算方式：'fifo' or 'avg'

  @HiveField(2)
  double defaultFeeRate; //預設手續費率

  @HiveField(3)
  double defaultTaxRate; //預設證交稅率

  @HiveField(4)
  double minFeePerShare; //最低手續費（以股）

  @HiveField(5)
  double minFeePerLot; //最低手續費（以張）

  @HiveField(6)
  double waterLevelThreshold; //資金水位警戒線

  @HiveField(7)
  bool autoDepositDefault; //同時記錄入金預設值

  AppSettings({
    this.redUpGreenDown = true,
    this.pnlMethod = 'fifo',
    this.defaultFeeRate = 0.000855,
    this.defaultTaxRate = 0.003,
    this.minFeePerShare = 1.0,
    this.minFeePerLot = 20.0,
    this.waterLevelThreshold = 0.3,
    this.autoDepositDefault = false,
  });
}