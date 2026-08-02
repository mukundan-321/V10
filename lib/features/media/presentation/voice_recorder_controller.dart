/// Controls a single hold-to-record voice message: start/stop/cancel,
/// live amplitude for a waveform, and slide-to-cancel state. Owns the
/// `record` package's recorder instance so the composer widget doesn't
/// touch the plugin directly.
library voice_recorder_controller;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum VoiceRecorderState { idle, recording, cancelling, processing }

class VoiceRecording {
  final File file;
  final Duration duration;
  const VoiceRecording(this.file, this.duration);
}

class VoiceRecorderController extends ChangeNotifier {
  VoiceRecorderController({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  VoiceRecorderState _state = VoiceRecorderState.idle;
  DateTime? _startedAt;
  StreamSubscription<Amplitude>? _amplitudeSub;
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  /// Minimum recording length to treat as a real voice note rather than an
  /// accidental tap.
  static const Duration _minimumDuration = Duration(milliseconds: 500);

  VoiceRecorderState get state => _state;
  bool get isRecording =>
      _state == VoiceRecorderState.recording ||
      _state == VoiceRecorderState.cancelling;
  Stream<double> get amplitude => _amplitudeController.stream;
  Duration get elapsed =>
      _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  /// Requests mic permission (if needed) and starts recording to a
  /// temporary file. Returns false if permission was denied or a
  /// recording is already in progress.
  Future<bool> start() async {
    if (_state != VoiceRecorderState.idle) return false;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return false;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 96000,
        sampleRate: 44100,
      ),
      path: path,
    );

    _startedAt = DateTime.now();
    _state = VoiceRecorderState.recording;
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) => _amplitudeController.add(amp.current));
    notifyListeners();
    return true;
  }

  /// Toggles the "will cancel if released now" visual state as the user
  /// drags the mic button left, per the slide-to-cancel gesture.
  void setCancelling(bool cancelling) {
    if (_state == VoiceRecorderState.idle ||
        _state == VoiceRecorderState.processing) {
      return;
    }
    final next =
        cancelling ? VoiceRecorderState.cancelling : VoiceRecorderState.recording;
    if (next == _state) return;
    _state = next;
    notifyListeners();
  }

  /// Stops recording and returns the finished note, or null if the
  /// recording was too short to be a real voice message (and the partial
  /// file was discarded).
  Future<VoiceRecording?> stopAndSend() async {
    if (_state == VoiceRecorderState.idle) return null;

    _state = VoiceRecorderState.processing;
    notifyListeners();

    final path = await _recorder.stop();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    final duration = elapsed;
    _reset();

    if (path == null) return null;

    final file = File(path);
    if (duration < _minimumDuration) {
      await file.delete().catchError((_) => file);
      return null;
    }
    return VoiceRecording(file, duration);
  }

  /// Stops recording and discards the file — the user slid to cancel.
  Future<void> cancel() async {
    if (_state == VoiceRecorderState.idle) return;

    final path = await _recorder.stop();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    _reset();

    if (path != null) {
      await File(path).delete().catchError((_) => File(path));
    }
  }

  void _reset() {
    _startedAt = null;
    _state = VoiceRecorderState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    _amplitudeController.close();
    _recorder.dispose();
    super.dispose();
  }
}
