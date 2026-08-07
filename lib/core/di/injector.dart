import 'package:get_it/get_it.dart';

import 'package:two_person_app/core/database/app_database.dart';

import 'package:two_person_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:two_person_app/features/chat/data/chat_repository_impl.dart';
import 'package:two_person_app/features/media/data/media_repository.dart';
import 'package:two_person_app/features/media/data/media_file_storage.dart';

import 'package:two_person_app/features/chat/data/media_session_manager.dart';

import 'package:two_person_app/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:two_person_app/features/pairing/data/pairing_repository_impl.dart';
import 'package:two_person_app/features/pairing/data/crypto/secure_key_store.dart';
import 'package:two_person_app/features/pairing/data/crypto/identity_key_service.dart';
import 'package:two_person_app/features/pairing/data/signaling/invite_api_client.dart';
import 'package:two_person_app/features/media/data/chunked_file_sender.dart';
import 'package:two_person_app/features/media/data/chunked_file_receiver.dart';
import 'package:two_person_app/features/chat/data/media_metadata_dao.dart';
import 'package:two_person_app/features/media/data/media_transfer_progress_store.dart';
import 'package:two_person_app/features/media/data/rtc_media_data_channel.dart';
import 'package:two_person_app/core/media/session_cipher.dart';

final GetIt sl = GetIt.instance;

/// Your deployed Render signaling server.
const String _signalingHttpBaseUrl = 'https://v10-12.onrender.com';
const String _signalingWsBaseUrl = 'wss://v10-12.onrender.com';

/// Called once from main() after the device passphrase has been
/// unlocked.
Future<void> configureDependencies({required String dbPassphrase}) async {
  // Core
  sl.registerLazySingleton<AppDatabase>(
    () => AppDatabase.open(dbPassphrase),
  );

  // Pairing
  sl.registerLazySingleton<SecureKeyValueStore>(
    () => DeviceSecureKeyValueStore(),
  );

  sl.registerLazySingleton<IdentityKeyService>(
    () => IdentityKeyService(sl()),
  );

  sl.registerLazySingleton<InviteApiClient>(
    () => InviteApiClient(
      baseHttpUrl: _signalingHttpBaseUrl,
    ),
  );

  sl.registerLazySingleton<PairingRepository>(
    () => PairingRepositoryImpl(
      db: sl(),
      identityKeyService: sl(),
      inviteApiClient: sl(),
      baseWsUrl: _signalingWsBaseUrl,
    ),
  );

  // Media
  final mediaStorage = await AppMediaFileStorage.create();
  sl.registerSingleton<AppMediaFileStorage>(mediaStorage);

  sl.registerLazySingleton<MediaMetadataDao>(
    () => MediaMetadataDao(sl()),
  );

  sl.registerLazySingleton<DriftMediaTransferProgressStore>(
    () => DriftMediaTransferProgressStore(sl<MediaMetadataDao>()),
  );

  sl.registerLazySingleton<MediaSessionManager>(
    () => MediaSessionManager(
      pairingRepository: sl(),
      storage: sl(),
      progressStore: sl(),
    ),
  );

  // Chat
  sl.registerLazySingleton<ChatRepositoryImpl>(
    () {
      final chatRepo = ChatRepositoryImpl(
        db: sl(),
        pairingRepository: sl(),
        mediaSession: sl(),
        storage: sl(),
      );
      sl<MediaSessionManager>().initialize(chatRepo);
      return chatRepo;
    },
  );

  sl.registerLazySingleton<ChatRepository>(
    () => sl<ChatRepositoryImpl>(),
  );
}

/// Configure dependencies for unit tests.
Future<void> configureDependenciesForTesting() async {
  await sl.reset();

  sl.registerLazySingleton<AppDatabase>(
    () => AppDatabase.forTesting(),
  );
}