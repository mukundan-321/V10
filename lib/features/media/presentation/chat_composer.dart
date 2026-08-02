/// The redesigned chat composer: 📎 attach · text field · mic/send toggle.
///
/// - Empty text field → microphone button (hold to record, slide left to
///   cancel, release to send).
/// - Non-empty text field → send button.
/// - 📎 opens the attachment bottom sheet (Gallery/Camera/Video/Document/
///   Voice Message/Cancel).
///
/// This widget only knows about picking/recording — it has no dependency
/// on the transfer layer. The screen that hosts it wires the three
/// callbacks to `MediaRepository` (typically via
/// `ref.read(mediaRepositoryProvider)`), keeping this widget reusable and
/// easy to preview/test in isolation.
library chat_composer;

import 'dart:io';

import 'package:flutter/material.dart';

import 'attachment_bottom_sheet.dart';
import 'media_picker_service.dart';
import 'voice_recorder_controller.dart';

/// Horizontal drag distance (px) past which releasing the mic button
/// cancels the recording instead of sending it.
const double _slideToCancelThreshold = 80.0;

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.onSendText,
    required this.onSendMedia,
    required this.onSendVoiceNote,
    this.pickerService,
    this.voiceRecorder,
  });

  final ValueChanged<String> onSendText;
  final ValueChanged<List<PickedMedia>> onSendMedia;
  final void Function(File file, Duration duration) onSendVoiceNote;

  /// Injectable for testing; defaults to real plugin-backed instances.
  final MediaPickerService? pickerService;
  final VoiceRecorderController? voiceRecorder;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  late final MediaPickerService _pickerService =
      widget.pickerService ?? MediaPickerService();
  late final VoiceRecorderController _voiceRecorder =
      widget.voiceRecorder ?? VoiceRecorderController();

  final TextEditingController _textController = TextEditingController();
  double _slideOffset = 0;

  bool get _hasText => _textController.text.trim().isNotEmpty;
  bool get _isRecording => _voiceRecorder.isRecording;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _voiceRecorder.addListener(_onRecorderChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _voiceRecorder.removeListener(_onRecorderChanged);
    _voiceRecorder.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});
  void _onRecorderChanged() => setState(() {});

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _textController.clear();
  }

  Future<void> _openAttachmentSheet() async {
    final picked = await showAttachmentBottomSheet(
      context,
      pickerService: _pickerService,
      onVoiceMessageRequested: _startRecording,
    );
    if (picked != null && picked.isNotEmpty) {
      widget.onSendMedia(picked);
    }
  }

  Future<void> _startRecording() async {
    final started = await _voiceRecorder.start();
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Microphone permission is required to record voice messages',
          ),
        ),
      );
    }
  }

  void _onMicDragUpdate(LongPressMoveUpdateDetails details) {
    final dx = details.localOffsetFromOrigin.dx;
    final clamped = dx.clamp(-160.0, 0.0);
    setState(() => _slideOffset = clamped);
    _voiceRecorder.setCancelling(-clamped >= _slideToCancelThreshold);
  }

  Future<void> _onMicReleased() async {
    final shouldCancel = -_slideOffset >= _slideToCancelThreshold;
    setState(() => _slideOffset = 0);

    if (shouldCancel) {
      await _voiceRecorder.cancel();
      return;
    }
    final recording = await _voiceRecorder.stopAndSend();
    if (recording != null) {
      widget.onSendVoiceNote(recording.file, recording.duration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: _isRecording ? _buildRecordingBar(context) : _buildComposerBar(context),
      ),
    );
  }

  Widget _buildComposerBar(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.attach_file),
          onPressed: _openAttachmentSheet,
          tooltip: 'Attach',
        ),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Message',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        _buildTrailingAction(context),
      ],
    );
  }

  Widget _buildTrailingAction(BuildContext context) {
    if (_hasText) {
      return IconButton(
        icon: const Icon(Icons.send),
        onPressed: _sendText,
        tooltip: 'Send',
      );
    }
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressMoveUpdate: _onMicDragUpdate,
      onLongPressEnd: (_) => _onMicReleased(),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.mic_none_outlined),
      ),
    );
  }

  Widget _buildRecordingBar(BuildContext context) {
    final cancelling = _voiceRecorder.state == VoiceRecorderState.cancelling;
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.fiber_manual_record, color: theme.colorScheme.error, size: 14),
        const SizedBox(width: 8),
        _RecordingTimer(controller: _voiceRecorder),
        const Spacer(),
        AnimatedOpacity(
          opacity: cancelling ? 1 : 0.6,
          duration: const Duration(milliseconds: 150),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chevron_left,
                color: cancelling ? theme.colorScheme.error : null,
              ),
              Text(
                cancelling ? 'Release to cancel' : 'Slide to cancel',
                style: TextStyle(
                  color: cancelling ? theme.colorScheme.error : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onLongPressMoveUpdate: _onMicDragUpdate,
          onLongPressEnd: (_) => _onMicReleased(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.mic,
              color: cancelling ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Ticks once a second off the recorder's elapsed time — cheap enough not
/// to warrant a StreamBuilder for a value that only needs whole-second
/// resolution.
class _RecordingTimer extends StatefulWidget {
  const _RecordingTimer({required this.controller});
  final VoiceRecorderController controller;

  @override
  State<_RecordingTimer> createState() => _RecordingTimerState();
}

class _RecordingTimerState extends State<_RecordingTimer> {
  late final Stream<int> _ticker = Stream<int>.periodic(
    const Duration(seconds: 1),
    (i) => i,
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _ticker,
      builder: (context, _) {
        final elapsed = widget.controller.elapsed;
        final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
        final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
        return Text('$minutes:$seconds');
      },
    );
  }
}
