/// Renders a document/file attachment: icon, filename, size, and a tap
/// target that opens it with the OS's default viewer via `open_filex`.
library document_tile;

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../domain/chat_message_media.dart';

class DocumentTile extends StatelessWidget {
  const DocumentTile({super.key, required this.media, this.onRetry});

  final MediaAttachment media;
  final VoidCallback? onRetry;

  String _formattedSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _open(BuildContext context) async {
    final path = media.localPath;
    if (path == null) return;
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: ${result.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFailed = media.status == MediaTransferStatus.failed;
    final isReady = media.status == MediaTransferStatus.completed &&
        media.localPath != null;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 260),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isReady ? () => _open(context) : (isFailed ? onRetry : null),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    isFailed ? Icons.error_outline : Icons.insert_drive_file,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        media.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFailed
                            ? 'Failed — tap to retry'
                            : _formattedSize(media.fileSize),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isFailed
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isReady && !isFailed)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value:
                          media.fileSize == 0 ? null : media.progressFraction,
                    ),
                  )
                else if (isReady)
                  Icon(Icons.download_done,
                      color: theme.colorScheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
