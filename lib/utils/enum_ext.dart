//extension

// 這段代碼賦予了所有 Enum 列表 .byNameOrNull 的能力
extension EnumByNameOrNull<T extends Enum> on Iterable<T> {
  T? byNameOrNull(String? name) {
    if (name == null) return null;
    try {
      return byName(name) as T;
    } catch (_) {
      return null;
    }
  }
}

extension StringX on String {
  String? get orNull => trim().isEmpty ? null : trim();
}