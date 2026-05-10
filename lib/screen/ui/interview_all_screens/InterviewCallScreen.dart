import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_interview/network/Api_URL.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../Service/subscription_service.dart';
import '../../../ads/ad_service.dart';
import '../../../models/Subscription.dart';
import 'AvatarSelectionScreen.dart';
import 'QuickSessionScreen.dart';
import '../../../models/Subscription.dart'; // ← এখানে UsageModel আছে?

// ── Only STT key stays in frontend ───────────────────────────────────────────
// Groq & ElevenLabs keys এখন backend .env এ থাকবে
const String _assemblyAiApiKey = '337b2052bb5a4b0295d2b7a68b77f2c0';

// ── Backend URLs — আপনার server IP দিন ──────────────────────────────────────
const String _backendHttp    = 'http://192.168.1.100:8000'; // ← পরিবর্তন করুন
const String _backendWs      = 'ws://192.168.1.100:8000';   // ← পরিবর্তন করুন

const String baseURL = "https://b48f-103-99-182-5.ngrok-free.app/";
const String WebShokedbaseURL = "wss://b48f-103-99-182-5.ngrok-free.app/";

const String _interviewWsUrl = '${ApiURL.WebShokedbaseURL}ws/interview';
const String _ttsUrl         = '${ApiURL.baseURL}tts';

var _usage;


// ── Design Tokens ─────────────────────────────────────────────────────────────
const _bgDeep      = Color(0xFF080810);
const _bgCard      = Color(0xFF0F0F1C);
const _bgElevated  = Color(0xFF161625);
const _bgSurface   = Color(0xFF1C1C2E);
const _accent      = Color(0xFF6366F1);
const _accentSoft  = Color(0xFF818CF8);
const _accentGlow  = Color(0x336366F1);
const _green       = Color(0xFF10B981);
const _greenSoft   = Color(0xFF34D399);
const _amber       = Color(0xFFF59E0B);
const _red         = Color(0xFFEF4444);
const _textPrimary = Color(0xFFF1F5F9);
const _textSecond  = Color(0xFF94A3B8);
const _textMuted   = Color(0xFF475569);
const _border      = Color(0xFF1E2035);

// ─────────────────────────────────────────────────────────────────────────────
class InterviewCallScreen extends StatefulWidget {
  final SessionConfig sessionConfig;
  final AvatarConfig  avatarConfig;
  final String        userId; // login থেকে পাস করুন

  const InterviewCallScreen({
    super.key,
    required this.sessionConfig,
    required this.avatarConfig,
    required this.userId,
  });

  @override
  State<InterviewCallScreen> createState() => _InterviewCallScreenState();
}

class _InterviewCallScreenState extends State<InterviewCallScreen>
    with TickerProviderStateMixin {

  final Dio _dio = Dio();

  // ── Language ──
  String _selectedLang = 'EN';

  // ── Timer / REC ──
  bool  _recVisible     = true;
  int   _elapsedSeconds = 0;
  late Timer _recTimer;
  late Timer _clockTimer;

  // ── Camera ──
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _isCameraOn  = true;

  // ── Mic ──
  bool _isMicOn = true;

  // ── AssemblyAI STT WebSocket ──────────────────────────────────────────────
  final AudioRecorder _recorder      = AudioRecorder();
  WebSocketChannel?   _sttWsChannel;
  StreamSubscription? _sttWsSubscription;
  StreamSubscription? _audioSubscription;
  bool                _assemblyReady = false;
  bool                _isConnecting  = false;

  // ── Transcript ──
  String _interimText = '';
  String _finalText   = '';
  String get _spokenText => (_finalText + ' ' + _interimText).trim();

  // ── Silence auto-submit ──
  Timer? _silenceTimer;

  // ── Backend Interview WebSocket ───────────────────────────────────────────
  WebSocketChannel?   _interviewWsChannel;
  StreamSubscription? _interviewWsSubscription;
  bool                _interviewWsReady = false;
  String?             _sessionId; // backend থেকে আসবে

  // ── AI / Session State ──
  bool   _aiSpeaking      = false;
  bool   _aiThinking      = false;
  String _aiQuestion      = '';
  int    _questionCount   = 0;
  int    _maxQuestions    = 5;
  bool   _sessionComplete = false;

  // ── Audio playback ──
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ── Animations ──
  late AnimationController _pulseCtrl;
  late Animation<double>    _pulseAnim;
  late AnimationController _waveCtrl;
  late Animation<double>    _waveAnim;
  late AnimationController _speakBarsCtrl;
  late AnimationController _micRingCtrl;
  late Animation<double>    _micRingAnim;
  late AnimationController _fadeInCtrl;
  late Animation<double>    _fadeInAnim;


  // ─────────────────────────────────────────────────────────────────────────
  // Init / Dispose
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initAnimations();

  /*  _recTimer = Timer.periodic(const Duration(milliseconds: 900),
            (_) => setState(() => _recVisible = !_recVisible));
    _clockTimer = Timer.periodic(const Duration(seconds: 1),
            (_) => setState(() => _elapsedSeconds++));

    _initCamera();*/

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _connectInterviewWs(); // backend WS → first question আসবে
      await _initAssemblyAI();     // STT ready
      await _loadUsage();
    });
  }

  void _initAnimations() {
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.025)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _waveAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _waveCtrl, curve: Curves.easeInOut));

    _speakBarsCtrl =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);

    _micRingCtrl =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _micRingAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _micRingCtrl, curve: Curves.easeInOut));

    _fadeInCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeInAnim = CurvedAnimation(parent: _fadeInCtrl, curve: Curves.easeOut);
    _fadeInCtrl.forward();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _recTimer.cancel();
    _clockTimer.cancel();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _speakBarsCtrl.dispose();
    _micRingCtrl.dispose();
    _fadeInCtrl.dispose();
    _cameraController?.dispose();
    _audioPlayer.dispose();
    _stopAssemblyAI();
    _closeInterviewWs();
    AdService.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Camera
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraController =
        CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();
    if (mounted) setState(() => _cameraReady = true);
  }

  Future<void> _toggleCamera() async {
    _isCameraOn
        ? await _cameraController?.pausePreview()
        : await _cameraController?.resumePreview();
    setState(() => _isCameraOn = !_isCameraOn);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Backend Interview WebSocket
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _connectInterviewWs() async {
    try {
      _interviewWsChannel =
          IOWebSocketChannel.connect(Uri.parse(_interviewWsUrl));

      _interviewWsSubscription = _interviewWsChannel!.stream.listen(
        _onInterviewWsMessage,
        onError: (e) {
          debugPrint('Interview WS error: $e');
          if (mounted && !_sessionComplete) {
            Future.delayed(const Duration(seconds: 2), _connectInterviewWs);
          }
        },
        onDone: () {
          debugPrint('Interview WS closed');
          if (mounted && !_sessionComplete) {
            Future.delayed(const Duration(seconds: 2), _connectInterviewWs);
          }
        },
      );

      setState(() => _interviewWsReady = true);
      debugPrint('Interview WS connected');

      // Connect হওয়ার সাথে সাথে session start করো
      _sendInterviewStart();
    } catch (e) {
      debugPrint('Interview WS connect error: $e');
      _showError('Could not connect to interview server.');
    }
  }

  // action: start → নতুন session তৈরি + প্রথম question
  void _sendInterviewStart() {
    if (_interviewWsChannel == null) return;
    _interviewWsChannel!.sink.add(json.encode({
      'action'    : 'start',
      'user_id'   : widget.userId,
      'category'  : widget.sessionConfig.category,
      'topics'    : widget.sessionConfig.topics,
      'difficulty': widget.sessionConfig.difficulty,
    }));
    setState(() => _aiThinking = true);
  }

  // action: answer → user এর answer পাঠাও, AI feedback + next question পাবে
  void _sendInterviewAnswer(String answer) {
    if (_interviewWsChannel == null || _sessionId == null) return;
    _interviewWsChannel!.sink.add(json.encode({
      'action'    : 'answer',
      'user_id'   : widget.userId,
      'session_id': _sessionId,
      'message'   : answer,
    }));
    setState(() => _aiThinking = true);
  }

  // Backend থেকে আসা message handle করো
  void _onInterviewWsMessage(dynamic raw) {
    if (!mounted) return;
    try {
      final data = json.decode(raw as String) as Map<String, dynamic>;

      if (data.containsKey('error')) {
        setState(() => _aiThinking = false);
        _showError(data['error'].toString());
        return;
      }

      final reply         = data['reply']          as String? ?? '';
      final sessionId     = data['session_id']     as String?;
      final questionCount = data['question_count'] as int?    ?? _questionCount;
      final maxQuestions  = data['max_questions']  as int?    ?? _maxQuestions;
      final isComplete    = data['is_complete']    as bool?   ?? false;

      if (sessionId != null) _sessionId = sessionId;

      setState(() {
        _aiQuestion      = reply;
        _questionCount   = questionCount;
        _maxQuestions    = maxQuestions;
        _sessionComplete = isComplete;
        _aiThinking      = false;
      });

      // AI reply কে voice দাও (backend TTS)
      if (reply.isNotEmpty) _speakFromBackend(reply);

      // সব question শেষ হলে complete dialog
      if (isComplete) {
        Future.delayed(const Duration(milliseconds: 500),
            _showSessionCompleteDialog);
      }
    } catch (e) {
      debugPrint('Interview WS parse error: $e');
      setState(() => _aiThinking = false);
    }
  }

  void _closeInterviewWs() {
    _interviewWsSubscription?.cancel();
    _interviewWsSubscription = null;
    _interviewWsChannel?.sink.close();
    _interviewWsChannel  = null;
    _interviewWsReady = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AssemblyAI STT WebSocket (frontend only — real-time audio stream)
  // ─────────────────────────────────────────────────────────────────────────
  String get _assemblySpeechModel => _selectedLang == 'EN'
      ? 'universal-streaming-english'
      : 'universal-streaming-multilingual';

  Future<void> _initAssemblyAI() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showError('Microphone permission denied.');
      return;
    }
    await _connectAssemblyAI();
  }

  Future<void> _connectAssemblyAI() async {
    if (_isConnecting || !mounted) return;
    setState(() => _isConnecting = true);

    try {
      final uri = Uri.parse(
        'wss://streaming.assemblyai.com/v3/ws'
            '?sample_rate=16000'
            '&speech_model=$_assemblySpeechModel'
            '&encoding=pcm_s16le'
            '&format_turns=true'
            '&min_end_of_turn_silence_when_confident=2500'
            '&max_turn_silence=8000',
      );

      _sttWsChannel = IOWebSocketChannel.connect(
        uri,
        headers: {'Authorization': _assemblyAiApiKey},
      );

      _sttWsSubscription = _sttWsChannel!.stream.listen(
        _onAssemblyMessage,
        onError: (e) {
          debugPrint('AssemblyAI WS error: $e');
          _reconnectAssemblyAI();
        },
        onDone: () {
          debugPrint('AssemblyAI WS closed');
          if (_isMicOn && !_aiSpeaking && mounted) _reconnectAssemblyAI();
        },
      );

      if (mounted) setState(() {_assemblyReady = true; _isConnecting = false;});
    } catch (e) {
      debugPrint('AssemblyAI connect error: $e');
      if (mounted) setState(() => _isConnecting = false);
      _showError('Could not connect to speech service.');
    }
  }

  Future<void> _startAudioStream() async {
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder      : AudioEncoder.pcm16bits,
        sampleRate   : 16000,
        numChannels  : 1,
        echoCancel   : true,
        noiseSuppress: true,
      ),
    );
    _audioSubscription = stream.listen((chunk) {
      if (_sttWsChannel != null && _isMicOn && !_aiSpeaking && _assemblyReady) {
        try { _sttWsChannel!.sink.add(chunk); } catch (e) {}
      }
    });
  }

  void _onAssemblyMessage(dynamic raw) {
    if (!mounted) return;
    try {
      final data    = json.decode(raw as String) as Map<String, dynamic>;
      final msgType = data['type'] as String?;

      // Session began → start sending audio
      if (msgType == 'Begin' || msgType == 'session_begins' || msgType == 'SessionBegins') {
        _startAudioStream();
        return;
      }

      // v3: Turn
      if (msgType == 'Turn') {
        final transcript      = data['transcript']       as String? ?? '';
        final endOfTurn       = data['end_of_turn']      as bool?   ?? false;
        final turnIsFormatted = data['turn_is_formatted'] as bool?  ?? false;

        if (transcript.isNotEmpty) {
          _silenceTimer?.cancel();
          setState(() {
            if (endOfTurn && turnIsFormatted) {
              _finalText   = (_finalText + ' ' + transcript).trim();
              _interimText = '';
            } else {
              _interimText = transcript;
            }
          });
          if (endOfTurn && turnIsFormatted) {
            _silenceTimer = Timer(const Duration(milliseconds: 4000), () {
              if (_spokenText.trim().isNotEmpty && !_aiSpeaking && !_aiThinking) {
                _autoSubmit();
              }
            });
          }
        } else if (!endOfTurn) {
          _silenceTimer?.cancel();
        }
        return;
      }

      // v2 fallback: PartialTranscript
      if (msgType == 'PartialTranscript' || msgType == 'partial_transcript') {
        final text = data['text'] as String? ?? '';
        if (text.isNotEmpty) setState(() => _interimText = text);
        return;
      }

      // v2 fallback: FinalTranscript
      if (msgType == 'FinalTranscript' || msgType == 'final_transcript') {
        final text = data['text'] as String? ?? '';
        if (text.isNotEmpty) {
          setState(() {_finalText = (_finalText + ' ' + text).trim(); _interimText = '';});
          _silenceTimer?.cancel();
          _silenceTimer = Timer(const Duration(milliseconds: 3000), () {
            if (_spokenText.trim().isNotEmpty && !_aiSpeaking && !_aiThinking) _autoSubmit();
          });
        }
        return;
      }

      if (msgType == 'Termination' || msgType == 'SessionTerminated') {
        _assemblyReady = false;
      }
    } catch (e) {
      debugPrint('AssemblyAI parse error: $e');
    }
  }

  // User এর transcribed answer → backend interview WS এ পাঠাও
  void _autoSubmit() {
    final answer = _spokenText.trim();
    if (answer.isEmpty || _aiThinking || _aiSpeaking) return;
    setState(() {_finalText = ''; _interimText = '';});
    _pauseMicStream();
    _sendInterviewAnswer(answer); // ← backend এ যাচ্ছে
  }

  Future<void> _stopAssemblyAI() async {
    _silenceTimer?.cancel();
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    try { await _recorder.stop(); } catch (_) {}
    try { _sttWsChannel?.sink.add(json.encode({'terminate_session': true})); } catch (_) {}
    await _sttWsSubscription?.cancel();
    _sttWsSubscription = null;
    _sttWsChannel?.sink.close();
    _sttWsChannel  = null;
    _assemblyReady = false;
  }

  Future<void> _reconnectAssemblyAI() async {
    if (!mounted || _aiSpeaking) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted && _isMicOn) await _connectAssemblyAI();
  }

  Future<void> _pauseMicStream() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    try { await _recorder.stop(); } catch (_) {}
  }

  Future<void> _resumeMicStream() async {
    if (!_isMicOn || !mounted) return;
    if (_sttWsChannel == null || !_assemblyReady) {
      await _connectAssemblyAI();
    } else {
      await _startAudioStream();
    }
  }

  Future<void> _toggleMic() async {
    if (_isMicOn) {
      _silenceTimer?.cancel();
      await _pauseMicStream();
      setState(() {_isMicOn = false; _finalText = ''; _interimText = '';});
    } else {
      setState(() => _isMicOn = true);
      await _resumeMicStream();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TTS — Backend HTTP endpoint (ElevenLabs/Groq handled server-side)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _speakFromBackend(String text) async {
    if (!mounted) return;
    setState(() => _aiSpeaking = true);
    _waveCtrl.repeat(reverse: true);

    try {
      debugPrint('🔊 TTS calling: $_ttsUrl');
      debugPrint('🔊 TTS text: ${text.substring(0, text.length.clamp(0, 50))}');

      final response = await _dio.post(
        _ttsUrl,
        options: Options(
          headers: {
            'Content-Type'               : 'application/json',
            'ngrok-skip-browser-warning' : 'true',
          },
          responseType : ResponseType.bytes,
          sendTimeout  : const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 20),
        ),
        data: {
          'text'    : text,
          'voice_id': widget.avatarConfig.elevenLabsVoiceId,
        },
      );

      debugPrint('🔊 TTS status: ${response.statusCode}');
      debugPrint('🔊 TTS content-type: ${response.headers.value('content-type')}');
      debugPrint('🔊 TTS bytes: ${(response.data as List<int>).length}');

      if (response.statusCode == 200 && mounted) {
        final bytes    = response.data as List<int>;
        final tempDir  = await getTemporaryDirectory();
        final isWav    = (response.headers.value('content-type') ?? '').contains('wav');
        final tmpFile  = File('${tempDir.path}/tts_reply.${isWav ? 'wav' : 'mp3'}');
        await tmpFile.writeAsBytes(bytes);

        debugPrint('🔊 File written: ${tmpFile.path}');

        await _audioPlayer.stop();  // আগেরটা বন্ধ করো
        await _audioPlayer.setFilePath(tmpFile.path);
        await _audioPlayer.play();
        await _audioPlayer.processingStateStream
            .firstWhere((s) => s == ProcessingState.completed);

        debugPrint('🔊 Playback complete');
      }
    } on DioException catch (e) {
      debugPrint('❌ TTS DioException type : ${e.type}');
      debugPrint('❌ TTS DioException msg  : ${e.message}');
      debugPrint('❌ TTS response status  : ${e.response?.statusCode}');
      // response.data bytes হলে string convert করো
      final rawData = e.response?.data;
      if (rawData is List<int>) {
        debugPrint('❌ TTS response body: ${String.fromCharCodes(rawData)}');
      } else {
        debugPrint('❌ TTS response body: $rawData');
      }
    } catch (e, stack) {
      debugPrint('❌ TTS unexpected error: $e');
      debugPrint('❌ TTS stack: $stack');
    }

    if (mounted) {
      setState(() => _aiSpeaking = false);
      _waveCtrl.stop();
      _waveCtrl.reset();
      if (_isMicOn) {
        _finalText   = '';
        _interimText = '';
        await _resumeMicStream();
      }
    }
  }
  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(msg),
      backgroundColor: _red,
      behavior       : SnackBarBehavior.floating,
      shape          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String get _formattedTime {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds  % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showSessionCompleteDialog() async{
    if (!mounted) return;

    // Free plan → interview শেষে interstitial দেখাও
    await AdService.showInterstitialAd(
      showAds: _usage?.showAds ?? true,
    );

    if (!mounted) return;
    showDialog(
      context           : context,
      barrierColor      : Colors.black.withOpacity(0.7),
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side        : const BorderSide(color: _border, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding   : const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.emoji_events_rounded, color: _accent, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Interview Complete!',
                  style: TextStyle(
                      color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('$_questionCount/$_maxQuestions questions answered.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _textSecond, fontSize: 13, height: 1.5)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {Navigator.pop(context); Navigator.pop(context);},
                child: Container(
                  width  : double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color       : _accent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: _accent.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Center(
                    child: Text('View Report',
                        style: TextStyle(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: FadeTransition(
        opacity: _fadeInAnim,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 12),
              _buildAvatarSection(),
              const SizedBox(height: 12),
              _buildSubtitleBubble(),
              const SizedBox(height: 12),
              _buildUserVideoSection(),
              const SizedBox(height: 10),
              _buildControlBar(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          // REC + timer
          Container(
            padding    : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration : BoxDecoration(
              color       : _red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border      : Border.all(color: _red.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  opacity : _recVisible ? 1.0 : 0.1,
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: 6),
                Text(_formattedTime,
                    style: const TextStyle(
                        color: _red, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ],
            ),
          ),

          const Spacer(),

          // Q progress badge — session start হওয়ার পর দেখাবে
          if (_sessionId != null) ...[
            Container(
              margin    : const EdgeInsets.only(right: 8),
              padding   : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color       : _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border      : Border.all(color: _accent.withOpacity(0.3), width: 1),
              ),
              child: Text('Q $_questionCount/$_maxQuestions',
                  style: const TextStyle(
                      color: _accentSoft, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],

          // STT status
          Container(
            padding   : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color       : _bgSurface,
              borderRadius: BorderRadius.circular(20),
              border      : Border.all(color: _border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    color: _isConnecting ? _amber : _assemblyReady ? _green : _red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _isConnecting ? 'Connecting...' : _assemblyReady ? 'Live' : 'STT Off',
                  style: const TextStyle(
                      color: _textSecond, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Language switcher
          Container(
            padding   : const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color       : _bgSurface,
              borderRadius: BorderRadius.circular(20),
              border      : Border.all(color: _border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: ['EN', 'BN', 'HI'].map((lang) {
                final active = lang == _selectedLang;
                return GestureDetector(
                  onTap: () async {
                    setState(() => _selectedLang = lang);
                    if (_isMicOn) {
                      await _stopAssemblyAI();
                      setState(() => _assemblyReady = false);
                      await _connectAssemblyAI();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding : const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color       : active ? _accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(lang,
                        style: TextStyle(
                          color        : active ? Colors.white : _textMuted,
                          fontSize     : 11,
                          fontWeight   : FontWeight.w700,
                          letterSpacing: 0.3,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── AI Avatar ─────────────────────────────────────────────────────────────
  Widget _buildAvatarSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height  : 195,
        decoration: BoxDecoration(
          color       : _bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _aiSpeaking ? _accent.withOpacity(0.5) : _border,
            width: 1.5,
          ),
          boxShadow: _aiSpeaking
              ? [BoxShadow(color: _accentGlow, blurRadius: 24, spreadRadius: 2)]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ScaleTransition(
                scale: _pulseAnim,
                child: Image.asset(widget.avatarConfig.imagePath, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin : Alignment.topCenter,
                      end   : Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.transparent, _bgDeep.withOpacity(0.85)],
                      stops : const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              if (_aiSpeaking)
                AnimatedBuilder(
                  animation: _waveAnim,
                  builder: (_, __) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: _accent.withOpacity(0.35 + _waveAnim.value * 0.45),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 12, left: 14, right: 14,
                child: Row(
                  children: [
                    _StatusDot(speaking: _aiSpeaking, thinking: _aiThinking, waveAnim: _waveAnim),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize      : MainAxisSize.min,
                        children: [
                          Text(widget.avatarConfig.name,
                              style: const TextStyle(
                                  color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(
                            _aiSpeaking ? 'Speaking' : _aiThinking ? 'Thinking...' : 'Listening',
                            style: TextStyle(
                              color: _aiSpeaking ? _accentSoft : _aiThinking ? _amber : _greenSoft,
                              fontSize  : 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_aiSpeaking) _SpeakingBars(ctrl: _speakBarsCtrl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Subtitle Bubble ───────────────────────────────────────────────────────
  Widget _buildSubtitleBubble() {
    final isAI    = _aiSpeaking || _aiThinking;
    final showTxt = isAI ? _aiQuestion : _spokenText;
    final hasTxt  = showTxt.isNotEmpty;

    if (!hasTxt) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width  : double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color       : _bgElevated,
            borderRadius: BorderRadius.circular(14),
            border      : Border.all(color: _border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: _isMicOn && _assemblyReady ? _green : _textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isMicOn && _assemblyReady
                    ? 'Listening for your answer...'
                    : _isMicOn ? 'Connecting to speech service...' : 'Microphone is off',
                style: const TextStyle(color: _textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width  : double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isAI ? _accent.withOpacity(0.08) : _green.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isAI ? _accent.withOpacity(0.25) : _green.withOpacity(0.25), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin : const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color       : isAI ? _accent.withOpacity(0.15) : _green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isAI ? Icons.smart_toy_rounded : Icons.mic_rounded,
                color: isAI ? _accentSoft : _greenSoft, size: 12,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    showTxt,
                    minFontSize: 11, maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color     : isAI ? _textPrimary : _textPrimary.withOpacity(0.9),
                      fontSize  : 13, height: 1.55, fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (!isAI && _interimText.isNotEmpty && _finalText.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 5, height: 5,
                            decoration: BoxDecoration(
                              color: _greenSoft.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text('listening...',
                              style: TextStyle(color: _greenSoft.withOpacity(0.5), fontSize: 11)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── User Video ────────────────────────────────────────────────────────────
  Widget _buildUserVideoSection() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color       : _bgCard,
            borderRadius: BorderRadius.circular(20),
            border      : Border.all(color: _border, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_cameraReady && _isCameraOn)
                  SizedBox.expand(
                    child: FittedBox(
                      fit  : BoxFit.cover,
                      child: SizedBox(
                        width : _cameraController!.value.previewSize!.height,
                        height: _cameraController!.value.previewSize!.width,
                        child : CameraPreview(_cameraController!),
                      ),
                    ),
                  )
                else
                  Container(
                    color: _bgCard,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color : _bgSurface,
                            shape : BoxShape.circle,
                            border: Border.all(color: _border, width: 1),
                          ),
                          child: Icon(
                            _cameraReady ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                            color: _textMuted, size: 28,
                          ),
                        ),
                        if (!_cameraReady) ...[
                          const SizedBox(height: 14),
                          const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin : Alignment.topCenter,
                        end   : Alignment.bottomCenter,
                        colors: [Colors.transparent, _bgDeep.withOpacity(0.7)],
                        stops : const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12, left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color       : Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_rounded, color: Colors.white70, size: 12),
                        SizedBox(width: 5),
                        Text('You',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                if (_spokenText.isNotEmpty && !_aiSpeaking && !_aiThinking)
                  Positioned(
                    bottom: 12, right: 14,
                    child: AnimatedBuilder(
                      animation: _micRingAnim,
                      builder: (_, __) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color       : _green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _green.withOpacity(0.3 + _micRingAnim.value * 0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5, height: 5,
                              decoration: BoxDecoration(
                                color: _greenSoft.withOpacity(0.6 + _micRingAnim.value * 0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('pause to send',
                                style: TextStyle(
                                    color: _greenSoft, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Control Bar ───────────────────────────────────────────────────────────
  Widget _buildControlBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding   : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color       : _bgElevated,
          borderRadius: BorderRadius.circular(28),
          border      : Border.all(color: _border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ControlButton(
              icon  : _isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              label : _isCameraOn ? 'Camera' : 'Off',
              active: _isCameraOn,
              onTap : _toggleCamera,
            ),
            _ControlButton(
              icon  : _isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              label : _isMicOn ? 'Mic' : 'Muted',
              active: _isMicOn,
              onTap : _toggleMic,
            ),
            _ControlButton(
              icon: Icons.more_horiz_rounded, label: 'More', active: true, onTap: () {},
            ),
            GestureDetector(
              onTap: _showEndDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color       : _red,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: _red.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.call_end_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 7),
                    Text('End',
                        style: TextStyle(
                            color: Colors.white, fontSize: 13,
                            fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── End Dialog ────────────────────────────────────────────────────────────
  void _showEndDialog() {
    showDialog(
      context     : context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side        : const BorderSide(color: _border, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding   : const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _red.withOpacity(0.1), shape: BoxShape.circle),
                child     : const Icon(Icons.call_end_rounded, color: _red, size: 26),
              ),
              const SizedBox(height: 16),
              const Text('End Interview?',
                  style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Your session will be saved and ended.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textSecond, fontSize: 13, height: 1.5)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding   : const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color       : _bgSurface,
                          borderRadius: BorderRadius.circular(14),
                          border      : Border.all(color: _border, width: 1),
                        ),
                        child: const Center(
                          child: Text('Continue',
                              style: TextStyle(
                                  color: _textSecond, fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context); // dialog বন্ধ

                        // Free plan → manually end করলেও ad দেখাও
                        await AdService.showInterstitialAd(
                          showAds: _usage?.showAds ?? true,
                        );

                        if (!mounted) return;
                        Navigator.pop(context); // interview screen বন্ধ
                      },
                      child: Container(
                        padding   : const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color       : _red,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: _red.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Center(
                          child: Text('End Session',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _loadUsage() async {
    try {
      final usage = await SubscriptionService.getUsage();
      setState(() => _usage = usage);
      // Free plan → interstitial preload করে রাখো
      if (usage.showAds) {
        await AdService.loadInterstitialAd();
      }
    } catch (_) {}
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────
class _StatusDot extends StatelessWidget {
  final bool              speaking;
  final bool              thinking;
  final Animation<double> waveAnim;
  const _StatusDot({required this.speaking, required this.thinking, required this.waveAnim});

  @override
  Widget build(BuildContext context) {
    if (speaking) {
      return AnimatedBuilder(
        animation: waveAnim,
        builder: (_, __) => Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color    : Color.lerp(_accent, _accentSoft, waveAnim.value),
            shape    : BoxShape.circle,
            boxShadow: [BoxShadow(color: _accent.withOpacity(0.5 + waveAnim.value * 0.3), blurRadius: 6)],
          ),
        ),
      );
    }
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        color    : thinking ? _amber : _green,
        shape    : BoxShape.circle,
        boxShadow: [BoxShadow(color: (thinking ? _amber : _green).withOpacity(0.4), blurRadius: 5)],
      ),
    );
  }
}

class _SpeakingBars extends StatelessWidget {
  final AnimationController ctrl;
  const _SpeakingBars({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        const heights = [0.4, 1.0, 0.6, 0.85, 0.5];
        return Row(
          mainAxisSize      : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(5, (i) {
            final phase = (ctrl.value + i * 0.18) % 1.0;
            final h     = 4.0 + phase * 12.0 * heights[i];
            return Container(
              width: 3, height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color       : _accentSoft.withOpacity(0.7 + phase * 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         active;
  final VoidCallback onTap;
  const _ControlButton({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46, height: 46,
            decoration: BoxDecoration(
              color : active ? _bgSurface : _red.withOpacity(0.12),
              shape : BoxShape.circle,
              border: Border.all(color: active ? _border : _red.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, color: active ? _textSecond : _red, size: 19),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                color        : active ? _textMuted : _red.withOpacity(0.7),
                fontSize     : 9,
                fontWeight   : FontWeight.w600,
                letterSpacing: 0.3,
              )),
        ],
      ),
    );
  }
}