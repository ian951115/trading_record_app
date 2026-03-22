//設定資料存取
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/app_settings.dart';

class SettingsRepository extends ChangeNotifier {
  static const String boxName = 'settings';
  static const String settingsKey = 'app_settings';

  late Box<AppSettings> _box;
  late AppSettings _settings;
  bool _isReady = false;

  bool get isReady => _isReady;
  AppSettings get settings => _settings;

  SettingsRepository() {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<AppSettings>(boxName);

    //如果沒有設定就建立預設值
    if (_box.get(settingsKey) == null) {
      await _box.put(settingsKey, AppSettings());
    }

    _settings = _box.get(settingsKey)!;
    _isReady = true;
    notifyListeners();
  }

  Future<void> update(AppSettings newSettings) async {
    await _box.put(settingsKey, newSettings);
    _settings = newSettings;
    notifyListeners();
  }

  //單獨更新某個設定值的便利方法
  Future<void> updateFeeRate(double rate) async {
    _settings.defaultFeeRate = rate;
    await _settings.save();
    notifyListeners();
  }

  Future<void> updateTaxRate(double rate) async {
    _settings.defaultTaxRate = rate;
    await _settings.save();
    notifyListeners();
  }

  Future<void> updateWaterLevel(double threshold) async {
    _settings.waterLevelThreshold = threshold;
    await _settings.save();
    notifyListeners();
  }

  Future<void> updateAutoDepositDefault(bool value) async {
    _settings.autoDepositDefault = value;
    await _settings.save();
    notifyListeners();
  }

  Future<void> updatePnLMethod(String method) async {
    _settings.pnlMethod = method;
    await _settings.save();
    notifyListeners();
  }

  Future<void> updateColorScheme(bool redUp) async {
    _settings.redUpGreenDown = redUp;
    await _settings.save();
    notifyListeners();
  }

  Future<void> updateMinFees({
    double? perShare,
    double? perLot,
  }) async {
    if (perShare != null) _settings.minFeePerShare = perShare;
    if (perLot != null) _settings.minFeePerLot = perLot;
    await _settings.save();
    notifyListeners();
  }
}