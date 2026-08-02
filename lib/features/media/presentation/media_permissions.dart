/// Thin wrapper around `permission_handler` so picker/recorder code
/// requests exactly the permission it's about to use, exactly when it's
/// about to use it — never at app startup, never all at once. Maps to
/// READ_MEDIA_IMAGES/READ_MEDIA_VIDEO/READ_MEDIA_AUDIO on Android 13+ and
/// the photo library/camera/microphone permissions on iOS via the
/// plugin's own platform channels.
library media_permissions;

import 'package:permission_handler/permission_handler.dart';

class MediaPermissions {
  const MediaPermissions();

  Future<bool> ensureCamera() => _ensure(Permission.camera);
  Future<bool> ensureMicrophone() => _ensure(Permission.microphone);
  Future<bool> ensurePhotos() => _ensure(Permission.photos);
  Future<bool> ensureVideos() => _ensure(Permission.videos);

  /// True if a previously-denied permission was denied permanently
  /// ("Don't ask again" / iOS after a first denial) — the caller should
  /// prompt the user to open Settings instead of requesting again.
  Future<bool> isPermanentlyDenied(Permission permission) async {
    return permission.status.then((s) => s.isPermanentlyDenied);
  }

  Future<void> openSettings() => openAppSettings();

  Future<bool> _ensure(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return true;
    final result = await permission.request();
    return result.isGranted || result.isLimited;
  }
}
