/// Renders the media portion of a chat bubble for whichever
/// [ChatMediaType] the message carries — image, video, voice note, or
/// document — including sending/receiving progress, failure, and retry
/// affordances. Text messages never reach this widget (`ChatMessage.media`
/// stays null for them); the existing text bubble is untouched.
library media_message_bubble;

import 'dart:io';

import 'package:flutter/material.dart';

import '../domain/chat_message_media.dart';
import 'document_tile.dart';
import 'image_viewer_screen.dart';
import 'video_player_screen.dart';
import 'voice_message_player.dart';

class MediaMessageBubble extends StatelessWidget {
  const MediaMessageBubble({
    super.key,
    required this.media,
    this.onCancel,
    this.onRetry,
  });

  final MediaAttachment media;

  /// Wired to `ChatMediaCoordinator.cancelSend`/`cancelReceive` by the
  /// screen hosting this bubble.
  final VoidCallback? onCancel;

  /// Wired to re-invoke the original `sendImage`/`sendVideo`/... call with
  /// the same local file, for a failed outgoing transfer.
  final VoidCallback? onRetry;

  bool get _inProgress =>
      media.status == MediaTransferStatus.sending ||
      media.status == MediaTransferStatus.receiving;

  @override
  Widget build(BuildContext context) {
    switch (media.type) {
      case ChatMediaType.image:
        return _buildImage(context);
      case ChatMediaType.video:
        return _buildVideo(context);
      case ChatMediaType.audio:
        return _buildAudio(context);
      case ChatMediaType.document:
        return DocumentTile(media: media, onRetry: onRetry);
    }
  }

  Widget _progressOverlay() {
    if (!_inProgress) return const SizedBox.shrink();
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: media.fileSize == 0 ? null : media.progressFraction,
                  color: Colors.white,
                ),
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _failedOverlay() {
    if (media.status != MediaTransferStatus.failed) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: Material(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onRetry,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(height: 4),
                Text(
                  'Failed — tap to retry',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double? _aspectHeightFor(double width) {
    if (media.width == null || media.height == null || media.width == 0) {
      return null;
    }
    return width * (media.height! / media.width!);
  }

  Widget _buildImage(BuildContext context) {
    const width = 220.0;
    final path = media.localPath ?? media.thumbnailPath;
    final heroTag = 'media_${media.transferId}';
    final canOpen =
        media.status == MediaTransferStatus.completed && media.localPath != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        height: _aspectHeightFor(width) ?? width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (path != null)
              GestureDetector(
                onTap: canOpen
                    ? () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ImageViewerScreen(
                            filePath: path,
                            heroTag: heroTag,
                          ),
                        ))
                    : null,
                child: Hero(
                  tag: heroTag,
                  child: Image.file(File(path), fit: BoxFit.cover),
                ),
              )
            else
              Container(color: Colors.black12),
            _progressOverlay(),
            _failedOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo(BuildContext context) {
    const width = 220.0;
    final thumb = media.thumbnailPath;
    final canPlay =
        media.status == MediaTransferStatus.completed && media.localPath != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        height: _aspectHeightFor(width) ?? width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumb != null)
              Image.file(File(thumb), fit: BoxFit.cover)
            else
              Container(color: Colors.black87),
            if (canPlay)
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(filePath: media.localPath!),
                )),
                child: const Center(
                  child: Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 48),
                ),
              ),
            if (media.durationMs != null)
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(media.durationMs!),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            _progressOverlay(),
            _failedOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAudio(BuildContext context) {
    if (media.status == MediaTransferStatus.completed &&
        media.localPath != null) {
      return VoiceMessagePlayer(
        filePath: media.localPath!,
        durationMs: media.durationMs ?? 0,
      );
    }

    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          Icon(
            media.status == MediaTransferStatus.failed
                ? Icons.error_outline
                : Icons.mic,
            color: media.status == MediaTransferStatus.failed
                ? theme.colorScheme.error
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: media.status == MediaTransferStatus.failed
                ? Text('Failed', style: TextStyle(color: theme.colorScheme.error))
                : LinearProgressIndicator(
                    value: media.fileSize == 0 ? null : media.progressFraction,
                  ),
          ),
          if (media.status == MediaTransferStatus.failed && onRetry != null)
            IconButton(icon: const Icon(Icons.refresh), onPressed: onRetry)
          else if (_inProgress && onCancel != null)
            IconButton(icon: const Icon(Icons.close), onPressed: onCancel),
        ],
      ),
    );
  }

  String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
