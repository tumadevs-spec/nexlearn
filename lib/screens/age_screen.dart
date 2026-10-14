import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'subject_screen.dart';

const String _nexImage = 'assets/images/robots/nex.png';
const double _maxContentWidth = 540;

// ----------------------------------------------------------------
// Unified Theme Palette (Identical to HomeScreen)
// ----------------------------------------------------------------

const Color _violetDark = Color(0xFF3B0764);
const Color _violet = Color(0xFF7C3AED);
const Color _violetMid = Color(0xFF8B5CF6);
const Color _violetLight = Color(0xFFA78BFA);

extension _Alpha on Color {
  Color op(double o) => withOpacity(o);
}

// ----------------------------------------------------------------
// TTS EMOJI FILTER
// ----------------------------------------------------------------

final RegExp _emojiRegex = RegExp(
  r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]',
  unicode: true,
);

// ----------------------------------------------------------------
// PAGE ROUTE TRANSITION
// ----------------------------------------------------------------

Route<T> _fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// ============================================================================
// FUTURISTIC GLASS CONTAINER
// ============================================================================

class _FuturisticCard extends StatelessWidget {
  const _FuturisticCard({
    required this.child,
    this.radius = 22,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.isGlowing = false,
    this.backgroundColor,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double? width;
  final double? height;
  final bool isGlowing;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.op(0.92),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isGlowing ? _violet : _violetLight.op(0.35),
          width: isGlowing ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isGlowing ? _violet.op(0.28) : _violet.op(0.10),
            blurRadius: isGlowing ? 26 : 18,
            spreadRadius: isGlowing ? 2 : 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.op(0.8),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ============================================================================
// FUTURISTIC PRESSABLE
// ============================================================================

class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.label,
    required this.onTap,
    required this.builder,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Widget Function(BuildContext context, bool pressed, bool active) builder;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  void _activate() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bool active = _hovered || _focused;

    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activate();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: widget.label,
        excludeSemantics: true,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: _activate,
          child: AnimatedScale(
            scale: _pressed
                ? 0.96
                : active
                    ? 1.03
                    : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutBack,
            child: widget.builder(context, _pressed, active),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// AGE SCREEN - REDESIGNED
// ============================================================================

class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> with TickerProviderStateMixin {
  // TTS
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  bool _isSpeaking = false;
  bool _isTyping = false;
  int _speechId = 0;

  // Flow: 0 = starting, 1 = name, 2 = age, 3 = class, 4 = ready
  int _step = 0;
  bool _busy = false;

  // Profile data
  final TextEditingController _nameController = TextEditingController();
  String? _savedName;
  int? _selectedAge;
  int? _selectedClass;

  // Chat
  final List<_ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  // Animations (Float, Particle, Pulse)
  late final AnimationController _floatController;
  late final AnimationController _particleController;
  late final AnimationController _pulseController;
  late final List<_AIParticle> _particles;

  @override
  void initState() {
    super.initState();

    _particles = _generateParticles();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    );

    _initializeTts();

    // Start Chat after brief intro
    WidgetsBinding.instance.addPostFrameCallback((_) => _startChat());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _floatController.stop();
      _pulseController.stop();
      _particleController.stop();
    } else {
      if (!_floatController.isAnimating) _floatController.repeat(reverse: true);
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      if (!_particleController.isAnimating) _particleController.repeat();
    }
  }

  // ----------------------------------------------------------------
  // TTS Logic
  // ----------------------------------------------------------------

  Future<void> _initializeTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.36);
      await _tts.setPitch(1.15);
      await _tts.setVolume(0.9);
      await _tts.awaitSpeakCompletion(true);
      _ttsReady = true;
    } catch (_) {
      _ttsReady = false;
    }
  }

  Future<void> _speak(String text) async {
    final String clean = text.replaceAll(_emojiRegex, '').replaceAll('\n', ' ').trim();
    if (clean.isEmpty) return;

    final int id = ++_speechId;
    try {
      if (!_ttsReady) await _initializeTts();
      await _tts.stop();
      if (mounted) setState(() => _isSpeaking = true);
      await _tts.speak(clean);
    } catch (_) {}

    if (mounted && id == _speechId) {
      setState(() => _isSpeaking = false);
    }
  }

  Future<void> _stopSpeaking() async {
    _speechId++;
    try {
      await _tts.stop();
    } catch (_) {}
    if (mounted) setState(() => _isSpeaking = false);
  }

  String get _lastRobotText {
    for (final message in _messages.reversed) {
      if (!message.isUser) return message.text;
    }
    return "Hi, I'm NEXI!";
  }

  // ----------------------------------------------------------------
  // Chat Sequence Handlers
  // ----------------------------------------------------------------

  Future<void> _addRobotMessage(String text) async {
    if (!mounted) return;
    setState(() => _isTyping = true);
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(text: text, isUser: false));
    });

    _scrollToBottom();
    unawaited(_speak(text));
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _startChat() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _step = 1);
    await _addRobotMessage("Hi! 👋 I'm NEXI. What's your name?");
  }

  Future<void> _submitName() async {
    if (_busy) return;
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      _showToast('Tell NEXI your name!');
      return;
    }

    _busy = true;
    try {
      await _stopSpeaking();
      _savedName = name;
      _addUserMessage(name);
      _nameController.clear();
      setState(() => _step = 2);
      await _addRobotMessage('Awesome to meet you, $name!\nHow old are you?');
    } finally {
      _busy = false;
    }
  }

  void _selectAge(int age) {
    _stopSpeaking();
    setState(() => _selectedAge = age);
  }

  Future<void> _submitAge() async {
    if (_busy) return;
    if (_selectedAge == null) {
      _showToast('Please select your age!');
      return;
    }

    _busy = true;
    try {
      await _stopSpeaking();
      _addUserMessage('$_selectedAge years old');
      setState(() => _step = 3);
      await _addRobotMessage('Super! Which class or grade are you in?');
    } finally {
      _busy = false;
    }
  }

  void _selectClass(int classNumber) {
    _stopSpeaking();
    setState(() => _selectedClass = classNumber);
  }

  Future<void> _submitClass() async {
    if (_busy) return;
    if (_selectedClass == null) {
      _showToast('Please select your class!');
      return;
    }

    _busy = true;
    try {
      await _stopSpeaking();
      _addUserMessage('Class $_selectedClass');
      await _saveProfile();
      setState(() => _step = 4);
      await _addRobotMessage("You're all set, $_savedName! 🚀 Ready to launch?");
    } finally {
      _busy = false;
    }
  }

  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profile_completed', true);
      await prefs.setString('player_name', _savedName ?? 'Explorer');
      await prefs.setInt('player_age', _selectedAge ?? 7);
      await prefs.setInt('player_class', _selectedClass ?? 1);
      await prefs.setInt('player_level', _selectedClass ?? 1);
    } catch (e) {
      debugPrint('Profile save error: $e');
    }
  }

  Future<void> _finish() async {
    await _stopSpeaking();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      _fadeSlideRoute<void>(
        SubjectScreen(classNumber: _selectedClass ?? 1),
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _violetDark,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _nameController.dispose();
    _scrollController.dispose();
    _floatController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient + Ambient Blobs (Matches HomeScreen)
          const RepaintBoundary(child: _AIBackground()),

          // Floating Particles
          RepaintBoundary(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _AIParticlePainter(
                      particles: _particles,
                      progress: _particleController.value,
                    ),
                  );
                },
              ),
            ),
          ),

          // Futuristic Circuit Lines & Accents
          const Positioned.fill(
            child: RepaintBoundary(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CircuitTracePainter(),
                ),
              ),
            ),
          ),

          // Safe Area Interactive Column
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                          child: Column(
                            children: [
                              Expanded(child: _buildChatList()),
                              _buildInteractiveDock(constraints.maxHeight * 0.52),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // TOP BAR (Futuristic Back + Progress Energy Bar + Audio Speaker)
  // ----------------------------------------------------------------

  Widget _buildTopBar() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: Row(
            children: [
              if (Navigator.canPop(context)) ...[
                _Pressable(
                  label: 'Back',
                  onTap: () => Navigator.maybePop(context),
                  builder: (context, pressed, active) {
                    return _FuturisticCard(
                      width: 44,
                      height: 44,
                      radius: 14,
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: _violetDark,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
              ],

              // Glowing AI Energy Progress Bar
              Expanded(
                child: _AIProgressBar(value: _step.clamp(0, 4) / 4),
              ),

              const SizedBox(width: 12),

              // TTS Read Aloud Button
              _Pressable(
                label: _isSpeaking ? 'Mute' : 'Read aloud',
                onTap: () {
                  if (_isSpeaking) {
                    _stopSpeaking();
                  } else {
                    _speak(_lastRobotText);
                  }
                },
                builder: (context, pressed, active) {
                  return _FuturisticCard(
                    width: 44,
                    height: 44,
                    radius: 14,
                    isGlowing: _isSpeaking,
                    backgroundColor: _isSpeaking ? const Color(0xFFEDE9FE) : null,
                    child: Center(
                      child: Icon(
                        _isSpeaking ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        color: _violet,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // CHAT LIST
  // ----------------------------------------------------------------

  Widget _buildChatList() {
    return ListView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      children: [
        _buildRobotHeroCard(),
        const SizedBox(height: 18),
        for (final message in _messages)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildChatBubble(message),
          ),
        if (_isTyping)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildTypingBubble(),
          ),
      ],
    );
  }

  // ----------------------------------------------------------------
  // ROBOT HERO HEADER (NEX Avatar with glowing halo ring)
  // ----------------------------------------------------------------

  Widget _buildRobotHeroCard() {
    final String stepBadge = _step >= 1 && _step <= 3
        ? 'STEP 0$_step'
        : _step == 4
            ? 'MISSION READY'
            : 'AI SETUP';

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final double offset = math.sin(_floatController.value * math.pi) * 4.5;
        return Transform.translate(
          offset: Offset(0, -offset),
          child: child,
        );
      },
      child: _FuturisticCard(
        radius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            // NEX Avatar with glowing halo ring
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final double pulse = 1.0 + math.sin(_pulseController.value * math.pi) * 0.08;
                    return Transform.scale(
                      scale: pulse,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _violetLight.op(0.25),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                    ),
                    border: Border.all(color: _violetLight.op(0.6), width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      _nexImage,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.smart_toy_rounded,
                        color: _violet,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            // AI Mission Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'NEXI',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 10,
                          color: _violetDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _violetLight.op(0.4)),
                        ),
                        child: Text(
                          stepBadge,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 7,
                            color: _violet,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Let’s set up your player profile!',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _violetDark.op(0.85),
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

  // ----------------------------------------------------------------
  // CHAT BUBBLES
  // ----------------------------------------------------------------

  Widget _buildChatBubble(_ChatMessage message) {
    if (message.isUser) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 290),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6D28D9),
                    _violet,
                    _violetMid,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
                border: Border.all(color: Colors.white.op(0.5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: _violet.op(0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFDDD6FE),
              border: Border.all(color: _violetLight),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: _violetDark,
              size: 18,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEDE9FE),
            border: Border.all(color: _violetLight.op(0.6)),
          ),
          child: ClipOval(
            child: Image.asset(
              _nexImage,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.smart_toy_rounded,
                color: _violet,
                size: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 290),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.op(0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: _violetLight.op(0.4), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: _violet.op(0.09),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _violetDark,
                height: 1.38,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Typing indicator
  Widget _buildTypingBubble() {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEDE9FE),
            border: Border.all(color: _violetLight.op(0.5)),
          ),
          child: const Icon(Icons.smart_toy_rounded, color: _violet, size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.op(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _violetLight.op(0.4)),
            boxShadow: [
              BoxShadow(
                color: _violet.op(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const _FuturisticTypingDots(),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------
  // BOTTOM INTERACTIVE DOCK
  // ----------------------------------------------------------------

  Widget _buildInteractiveDock(double maxHeight) {
    final bool visible = _step >= 1 && !_isTyping;

    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: visible
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white.op(0.94),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _violet.op(0.16),
                    blurRadius: 28,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_step),
                      child: _buildDockContent(),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity, height: 0),
    );
  }

  Widget _buildDockContent() {
    switch (_step) {
      case 1:
        return _buildNameInputView();
      case 2:
        return _buildAgeSelectionView();
      case 3:
        return _buildClassSelectionView();
      case 4:
        return _buildReadyLaunchView();
      default:
        return const SizedBox.shrink();
    }
  }

  // ----------------------------------------------------------------
  // STEP 1: NAME INPUT
  // ----------------------------------------------------------------

  Widget _buildNameInputView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENTER YOUR PLAYER NAME',
          style: GoogleFonts.pressStart2p(
            fontSize: 8.5,
            color: _violetDark,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF9FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _violetLight.op(0.4), width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: _violet.op(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [LengthLimitingTextInputFormatter(18)],
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _violetDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your name...',
                    hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF8B80A5),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    prefixIcon: const Icon(
                      Icons.person_rounded,
                      color: _violet,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  ),
                  onSubmitted: (_) => _submitName(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _Pressable(
              label: 'Submit Name',
              onTap: _submitName,
              builder: (context, pressed, active) {
                return Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D28D9), _violet, _violetMid],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.op(0.6), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: _violet.op(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // ----------------------------------------------------------------
  // STEP 2: AGE INPUT (6 - 11)
  // ----------------------------------------------------------------

  Widget _buildAgeSelectionView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'SELECT YOUR AGE',
              style: GoogleFonts.pressStart2p(
                fontSize: 8.5,
                color: _violetDark,
              ),
            ),
            const Spacer(),
            Text(
              'Ages 6 to 11',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _violetMid,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final int age = index + 6;
            final bool isSelected = _selectedAge == age;

            return _ChoiceTile(
              label: 'Age $age',
              caption: 'YEARS',
              value: '$age',
              selected: isSelected,
              onTap: () => _selectAge(age),
            );
          },
        ),
        const SizedBox(height: 14),
        _FuturisticGradientButton(
          text: 'CONTINUE',
          icon: Icons.arrow_forward_rounded,
          onTap: _submitAge,
        ),
      ],
    );
  }

  // ----------------------------------------------------------------
  // STEP 3: CLASS / GRADE INPUT (1 - 6)
  // ----------------------------------------------------------------

  Widget _buildClassSelectionView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'CHOOSE YOUR CLASS',
              style: GoogleFonts.pressStart2p(
                fontSize: 8.5,
                color: _violetDark,
              ),
            ),
            const Spacer(),
            Text(
              'Standard 1 - 6',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _violetMid,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final int classNum = index + 1;
            final bool isSelected = _selectedClass == classNum;

            return _ChoiceTile(
              label: 'Class $classNum',
              caption: 'GRADE',
              value: '$classNum',
              selected: isSelected,
              onTap: () => _selectClass(classNum),
            );
          },
        ),
        const SizedBox(height: 14),
        _FuturisticGradientButton(
          text: 'SAVE & CONTINUE',
          icon: Icons.arrow_forward_rounded,
          onTap: _submitClass,
        ),
      ],
    );
  }

  // ----------------------------------------------------------------
  // STEP 4: READY TO LAUNCH
  // ----------------------------------------------------------------

  Widget _buildReadyLaunchView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _violetLight.op(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: _violet, size: 16),
              const SizedBox(width: 8),
              Text(
                'ADVENTURE UNLOCKED',
                style: GoogleFonts.pressStart2p(
                  fontSize: 8,
                  color: _violetDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _FuturisticGradientButton(
          text: 'ENTER THE WORLD',
          icon: Icons.rocket_launch_rounded,
          onTap: _finish,
        ),
      ],
    );
  }
}

// ============================================================================
// SELECTION TILE (Age & Class options)
// ============================================================================

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.caption,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String caption;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      label: label,
      selected: selected,
      onTap: onTap,
      builder: (context, pressed, active) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6D28D9), _violet, _violetMid],
                  )
                : null,
            color: selected ? null : Colors.white.op(0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? Colors.white.op(0.8) : _violetLight.op(0.35),
              width: selected ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: selected ? _violet.op(0.36) : _violet.op(0.08),
                blurRadius: selected ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  caption,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: selected ? Colors.white.op(0.85) : const Color(0xFF7E729C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 16,
                    color: selected ? Colors.white : _violetDark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// FUTURISTIC GRADIENT BUTTON
// ============================================================================

class _FuturisticGradientButton extends StatelessWidget {
  const _FuturisticGradientButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      label: text,
      onTap: onTap,
      builder: (context, pressed, active) {
        return Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6D28D9),
                _violet,
                _violetMid,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.op(0.65),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: _violet.op(0.34),
                blurRadius: active ? 28 : 22,
                spreadRadius: active ? 2 : 0,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.op(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: GoogleFonts.pressStart2p(
                  fontSize: 9.5,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// AI ENERGY PROGRESS BAR
// ============================================================================

class _AIProgressBar extends StatelessWidget {
  const _AIProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Container(
          height: 18,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE).op(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _violetLight.op(0.35)),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: math.max(0.06, v.clamp(0.0, 1.0)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  gradient: const LinearGradient(
                    colors: [_violetLight, _violet],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _violet.op(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// BACKGROUND: LIGHT LAVENDER GRADIENT + GLOW BLOBS
// ============================================================================

class _AIBackground extends StatelessWidget {
  const _AIBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5F3FF),
            Color(0xFFEDE9FE),
            Color(0xFFF3E8FF),
            Color(0xFFFFFFFF),
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _GlowBlob(
            alignment: Alignment(-1.15, -0.85),
            size: 260,
            color: Color(0xFFC4B5FD),
          ),
          _GlowBlob(
            alignment: Alignment(1.15, -0.45),
            size: 240,
            color: Color(0xFFA78BFA),
          ),
          _GlowBlob(
            alignment: Alignment(0.85, 0.95),
            size: 280,
            color: Color(0xFFE9D5FF),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final Color color;

  const _GlowBlob({
    required this.alignment,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.op(0.24),
            boxShadow: [
              BoxShadow(
                color: color.op(0.28),
                blurRadius: 90,
                spreadRadius: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PARTICLES & CIRCUIT TRACES
// ============================================================================

class _AIParticle {
  const _AIParticle({
    required this.x,
    required this.y,
    required this.loops,
    required this.radius,
    required this.opacity,
    required this.phase,
  });

  final double x;
  final double y;
  final int loops;
  final double radius;
  final double opacity;
  final double phase;
}

List<_AIParticle> _generateParticles() {
  final math.Random r = math.Random(42);
  return List.generate(28, (_) {
    return _AIParticle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      loops: 1 + r.nextInt(2),
      radius: 0.8 + r.nextDouble() * 1.6,
      opacity: 0.12 + r.nextDouble() * 0.14,
      phase: r.nextDouble() * math.pi * 2,
    );
  });
}

class _AIParticlePainter extends CustomPainter {
  final List<_AIParticle> particles;
  final double progress;

  _AIParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    for (final p in particles) {
      final double y = ((p.y - progress * p.loops) % 1.0) * size.height;
      final double x = p.x * size.width + math.sin(progress * 2 * math.pi * p.loops + p.phase) * 5;

      paint.color = _violet.op(p.opacity);
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AIParticlePainter old) => old.progress != progress;
}

class _CircuitTracePainter extends CustomPainter {
  const _CircuitTracePainter();

  static const List<List<double>> _traces = [
    [0.02, 0.18, 0.06, 0.18, 0.08, 0.15, 0.13, 0.15],
    [0.88, 0.12, 0.92, 0.12, 0.935, 0.15, 0.98, 0.15],
    [0.02, 0.72, 0.06, 0.72, 0.08, 0.69, 0.12, 0.69],
    [0.88, 0.76, 0.92, 0.76, 0.935, 0.73, 0.98, 0.73],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..color = _violetMid.op(0.12);

    final Paint dot = Paint()..color = _violetMid.op(0.24);

    for (final p in _traces) {
      Offset at(int i) => Offset(size.width * p[i * 2], size.height * p[i * 2 + 1]);

      final Path path = Path()..moveTo(at(0).dx, at(0).dy);
      for (int i = 1; i < 4; i++) {
        path.lineTo(at(i).dx, at(i).dy);
      }

      canvas.drawPath(path, line);
      canvas.drawCircle(at(3), 2.2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// TYPING DOTS
// ============================================================================

class _FuturisticTypingDots extends StatefulWidget {
  const _FuturisticTypingDots();

  @override
  State<_FuturisticTypingDots> createState() => _FuturisticTypingDotsState();
}

class _FuturisticTypingDotsState extends State<_FuturisticTypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final double t = (_ctrl.value + i * 0.2) % 1.0;
            final double bump = math.sin(t * math.pi);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, -4 * bump),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _violet.op(0.4 + 0.6 * bump),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ----------------------------------------------------------------
// CHAT MESSAGE MODEL
// ----------------------------------------------------------------

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}