import 'media_repository.dart';

class MediaSessionManager {
  MediaRepository? _repository;

  MediaRepository? get repository => _repository;

  bool get isReady => _repository != null;

  void attach(MediaRepository repository) {
    _repository = repository;
  }

  Future<void> clear() async {
    await _repository?.dispose();
    _repository = null;
  }
}
