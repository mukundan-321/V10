import 'package:get_it/get_it.dart';

import 'package:two_person_app/core/database/app_database.dart';

import 'package:two_person_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:two_person_app/features/chat/data/chat_repository_impl.dart';

import 'package:two_person_app/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:two_person_app/features/pairing/data/pairing_repository_impl.dart';
import 'package:two_person_app/features/pairing/data/crypto/secure_key_store.dart';
import 'package:two_person_app/features/pairing/data/crypto/identity_key_service.dart';
import 'package:two_person_app/features/pairing/data/signaling/invite_api_client.dart';

final GetIt sl = GetIt.instance;

/// Points the client at your deployed signaling relay (see
/// signaling_server/ and docs/PAIRING_MIGRATION.md). These placeholder
/// values work with the reference server run locally
/// (`dart run bin/server.dart 8080`) on the SAME device/emulator as
/// the Flutter app -- update both before running against a real
/// deployment, and switch to https/wss once that deployment has TLS
/// (see signaling_server/README.md's "deploying this for real").
const String _signalingHttpBaseUrl = 'http://localhost:8080';
const String _signalingWsBaseUrl = 'ws://localhost:8080';

/// Called once from main() after the device passphrase has been
/// unlocked. Kept as plain manual registration rather than
/// `injectable` codegen: this is a small, fixed set of repositories,
/// and readability here matters more than saving a few lines.
Future<void> configureDependencies({required String dbPassphrase}) async {
  // Core
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase.open(dbPassphrase));

  // Feature: pairing (identity, key exchange, signaling relay, live connection)
  sl.registerLazySingleton<SecureKeyValueStore>(
    () => DeviceSecureKeyValueStore(),
  );
  sl.registerLazySingleton<IdentityKeyService>(
    () => IdentityKeyService(sl()),
  );
  sl.registerLazySingleton<InviteApiClient>(
    () => InviteApiClient(baseHttpUrl: _signalingHttpBaseUrl),
  );
  sl.registerLazySingleton<PairingRepository>(
    () => PairingRepositoryImpl(
      db: sl(),
      identityKeyService: sl(),
      inviteApiClient: sl(),
      baseWsUrl: _signalingWsBaseUrl,
    ),
  );

  // Feature: chat -- depends on pairing for live message delivery.
  // Unchanged by the pairing architecture migration: chat only ever
  // depended on PairingRepository's interface (transport,
  // connectionStatus), never on how pairing itself works underneath.
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(db: sl(), pairingRepository: sl()),
  );
}

/// Call from test setUp() to point the locator at an in-memory DB and
/// fakes instead of real implementations.
Future<void> configureDependenciesForTesting() async {
  sl.reset();
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase.forTesting());
}
