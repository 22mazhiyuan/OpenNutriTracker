/// Which visual system the app draws.
///
/// [glass] is the default: a mint Liquid Glass look (frosted bars, cards and
/// sheets). [classic] keeps the earlier warm, opaque surfaces. Light and dark
/// mode apply to both.
enum AppLook {
  classic(0),
  glass(1);

  final int storageIndex;

  const AppLook(this.storageIndex);

  /// Null — a config written before this setting existed — is [glass], so
  /// this fork opens in the new look until someone picks classic.
  static AppLook fromStorage(int? index) {
    if (index == classic.storageIndex) return classic;
    return glass;
  }
}
