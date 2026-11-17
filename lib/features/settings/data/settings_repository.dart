import '../../../core/db/daos/meta_dao.dart';

enum ThemeSetting {
  system,
  dark,
  light;

  static ThemeSetting parse(String? raw) {
    switch (raw) {
      case 'dark':
        return ThemeSetting.dark;
      case 'light':
        return ThemeSetting.light;
      default:
        return ThemeSetting.system;
    }
  }
}

class SettingsRepository {
  SettingsRepository(this.dao);

  static const themeKey = 'settings.theme';

  final MetaDao dao;

  Future<ThemeSetting> theme() async =>
      ThemeSetting.parse(await dao.getString(themeKey));

  Future<void> setTheme(ThemeSetting theme) =>
      dao.setString(themeKey, theme.name);
}
