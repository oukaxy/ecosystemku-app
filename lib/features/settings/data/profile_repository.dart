import '../../../core/db/daos/meta_dao.dart';

class UserProfile {
  const UserProfile({required this.name, this.avatarPath});

  final String name;
  final String? avatarPath;
}

class ProfileRepository {
  ProfileRepository(this.dao);

  static const fallbackName = 'Pengguna';

  final MetaDao dao;

  Future<UserProfile> load() async {
    final profile = await dao.profile();
    final name = profile?.name?.trim();
    return UserProfile(
      name: (name == null || name.isEmpty) ? fallbackName : name,
      avatarPath: profile?.avatarPath,
    );
  }

  Future<void> save({required String name, String? avatarPath}) =>
      dao.saveProfile(name: name.trim(), avatarPath: avatarPath);
}
