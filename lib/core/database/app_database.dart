import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

import 'tables/messages_table.dart';
import 'tables/reactions_table.dart';
import 'tables/keys_settings_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Messages,
  MediaMetadataTable,
  Reactions,
  KeyRecords,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  /// Opens (or creates) the encrypted local database.
  ///
  /// [passphrase] is derived by the crypto module from the device's
  /// secure-enclave key material and is never stored alongside the
  /// database.
  static AppDatabase open(String passphrase) {
    final executor = LazyDatabase(() async {
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();

      final dir = await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, 'shared_space.sqlite'));

      return NativeDatabase(
  file,
  setup: (rawDb) {
          final escaped = passphrase.replaceAll("'", "''");
          rawDb.execute("PRAGMA key = '$escaped';");

          final result = rawDb.select('PRAGMA cipher_version;');
          if (result.isEmpty) {
            throw StateError(
              'SQLCipher is not active — refusing to open what would '
              'be an unencrypted database at ${file.path}.',
            );
          }
        },
      );
    });

    return AppDatabase(executor);
  }

  /// In-memory database used by unit tests.
  static AppDatabase forTesting() {
    return AppDatabase(NativeDatabase.memory());
  }
}