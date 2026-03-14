//整個 App 的 filter state
import 'package:flutter/material.dart';
import '../../models/trade.dart';

class TradeFilter {
  final Set<AssetType>? assetTypes;
  final Set<String>? strategies;
  final Set<String>? symbols;
  final bool includeDividend;
  final DateTimeRange? range;

  const TradeFilter({
    this.assetTypes,
    this.strategies,
    this.symbols,
    this.includeDividend = true,
    this.range,
  });

  TradeFilter copyWith({
    Set<AssetType>? assetTypes,
    Set<String>? strategies,
    Set<String>? symbols,
    bool? includeDividend,
    DateTimeRange? range,
  }) {
    return TradeFilter(
      assetTypes: assetTypes ?? this.assetTypes,
      strategies: strategies ?? this.strategies,
      symbols: symbols ?? this.symbols,
      includeDividend: includeDividend ?? this.includeDividend,
      range: range ?? this.range,
    );
  }
}

List<Trade> applyTradeFilter(
  List<Trade> trades,
  TradeFilter filter,
) {
  return trades.where((t) {
    if (filter.assetTypes != null &&
        !filter.assetTypes!.contains(t.assetType)) {
      return false;
    }

    if (filter.symbols != null &&
        !filter.symbols!.contains(t.symbol)) {
      return false;
    }

    if (filter.strategies != null &&
        !t.tags.any(filter.strategies!.contains)) {
      return false;
    }

    if (filter.range != null) {
      if (t.date.isBefore(filter.range!.start) ||
          t.date.isAfter(filter.range!.end)) {
        return false;
      }
    }
    return true;
  }).toList();
}