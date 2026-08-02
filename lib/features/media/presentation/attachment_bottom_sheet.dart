/// The 📎 attachment bottom sheet: Gallery, Camera, Video, Document, Voice
/// Message, Cancel — per the Signal/WhatsApp-style composer spec.
library attachment_bottom_sheet;

import 'package:flutter/material.dart';

import 'media_permissions.dart';
import 'media_picker_service.dart';

enum _VideoSource { camera, gallery }

const MediaPermissions _permissions = MediaPermissions();

/// Runs a picker action, and if it throws [MediaPermissionDeniedException],
/// shows a snackbar offering to open Settings instead of failing silently.
Future<T?> _guardPermission<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  try {
    return await action();
  } on MediaPermissionDeniedException catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${e.permissionName[0].toUpperCase()}${e.permissionName.substring(1)} permission is needed for this.'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: _permissions.openSettings,
        ),
      ),
    );
    return null;
  }
}

/// Shows the attachment sheet and returns the picked media, or null if the
/// user cancelled / picked nothing. Pass [onVoiceMessageRequested] to
/// handle the "Voice Message" tile — the sheet closes and hands control
/// back to the composer's own hold-to-record flow rather than picking a
/// file itself.
Future<List<PickedMedia>?> showAttachmentBottomSheet(
  BuildContext context, {
  required MediaPickerService pickerService,
  required VoidCallback onVoiceMessageRequested,
}) {
  return showModalBottomSheet<List<PickedMedia>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _AttachmentSheet(
      pickerService: pickerService,
      onVoiceMessageRequested: onVoiceMessageRequested,
    ),
  );
}

class _AttachmentSheet extends StatelessWidget {
  const _AttachmentSheet({
    required this.pickerService,
    required this.onVoiceMessageRequested,
  });

  final MediaPickerService pickerService;
  final VoidCallback onVoiceMessageRequested;

  Future<void> _pickGallery(BuildContext context) async {
    final media = await _guardPermission(
      context,
      pickerService.pickImagesFromGallery,
    );
    if (context.mounted) Navigator.of(context).pop(media ?? <PickedMedia>[]);
  }

  Future<void> _pickCamera(BuildContext context) async {
    final media = await _guardPermission(
      context,
      pickerService.captureImageFromCamera,
    );
    if (context.mounted) {
      Navigator.of(context).pop(media != null ? [media] : <PickedMedia>[]);
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    final source = await _chooseVideoSource(context);
    if (source == null) return;
    if (!context.mounted) return;

    final media = await _guardPermission(
      context,
      source == _VideoSource.camera
          ? pickerService.captureVideoFromCamera
          : pickerService.pickVideoFromGallery,
    );

    if (context.mounted) {
      Navigator.of(context).pop(media != null ? [media] : <PickedMedia>[]);
    }
  }

  Future<void> _pickDocument(BuildContext context) async {
    final media = await pickerService.pickDocuments();
    if (context.mounted) Navigator.of(context).pop(media);
  }

  Future<_VideoSource?> _chooseVideoSource(BuildContext context) {
    return showModalBottomSheet<_VideoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Record video'),
              onTap: () => Navigator.of(context).pop(_VideoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(_VideoSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _AttachmentOption(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              onTap: () => _pickGallery(context),
            ),
            _AttachmentOption(
              icon: Icons.camera_alt_outlined,
              label: 'Camera',
              onTap: () => _pickCamera(context),
            ),
            _AttachmentOption(
              icon: Icons.videocam_outlined,
              label: 'Video',
              onTap: () => _pickVideo(context),
            ),
            _AttachmentOption(
              icon: Icons.insert_drive_file_outlined,
              label: 'Document',
              onTap: () => _pickDocument(context),
            ),
            _AttachmentOption(
              icon: Icons.mic_none_outlined,
              label: 'Voice Message',
              onTap: () {
                Navigator.of(context).pop(<PickedMedia>[]);
                onVoiceMessageRequested();
              },
            ),
            const Divider(height: 16),
            _AttachmentOption(
              icon: Icons.close,
              label: 'Cancel',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
