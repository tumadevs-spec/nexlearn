import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'subject_screen.dart';

const String _nexImage = 'assets/images/robots/nex.png';

const double _maxContentWidth = 560;

// ----------------------------------------------------------------
// Palette (same as the home screen)
// ----------------------------------------------------------------

const Color _violetDark = Color(0xFF3B0764);
const Color _violet = Color(0xFF7C3AED);
const Color _violetMid = Color(0xFF8B5CF6);
const Color _violetLight = Color(0xFFA78BFA);
const Color _clayWhite = Color(0xFFFBF8FF);
const Color _clayLilac = Color(0xFFE9DEFF);
const Color _inkSoft = Color(0xFF6B5B8E);

extension _Alpha on Color {
  Color op(double o) => withOpacity(o);
}

// ----------------------------------------------------------------
// EMOJI FILTER FOR TTS
// ----------------------------------------------------------------

final RegExp _emojiRegex = RegExp(
  r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]',
  unicode: true,
);

// ----------------------------------------------------------------
// PAGE TRANSITION
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
// CLAYMORPHISM CORE  (same recipe as the home screen)
// ============================================================================

class _Clay extends StatelessWidget {
  const _Clay({
    required this.child,
    this.radius = 28,
    this.borderRadius,
    this.color = _clayWhite,
    this.depth = 1.0,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.circle = false,
    this.lighten = .6,
    this.gloss = .55,
  });

  final Widget child;
  final double radius;
  final BorderRadius? borderRadius;
  final Color color;
  final double depth;
  final EdgeInsets padding;
  final double? width;
  final double? height;
  final bool circle;
  final double lighten;
  final double gloss;

  @override
  Widget build(BuildContext context) {
    final BorderRadius? br =
        circle ? null : (borderRadius ?? BorderRadius.circular(radius));
    final BoxShape shape = circle ? BoxShape.circle : BoxShape.rectangle;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: br,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, lighten)!,
            color,
            Color.lerp(color, _violet, .16)!,
          ],
          stops: const [0, .5, 1],
        ),
        border: Border.all(color: Colors.white.op(.75), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _violet.op(.26),
            offset: Offset(10 * depth, 14 * depth),
            blurRadius: 28 * depth,
          ),
          BoxShadow(
            color: Colors.white.op(.95),
            offset: Offset(-8 * depth, -8 * depth),
            blurRadius: 18 * depth,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: shape,
                  borderRadius: br,
                  gradient: RadialGradient(
                    center: const Alignment(-.55, -.65),
                    radius: .9,
                    colors: [
                      Colors.white.op(gloss),
                      Colors.white.op(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: shape,
                  borderRadius: br,
                  gradient: RadialGradient(
                    center: const Alignment(.8, .9),
                    radius: .8,
                    colors: [
                      _violetDark.op(.10),
                      _violetDark.op(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

// ============================================================================
// PRESSABLE  (hover / press / focus / semantics wrapper for clay buttons)
// ============================================================================

class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.label,
    required this.onTap,
    required this.builder,
    this.selected = false,
    this.radius = 20,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final double radius;
  final Widget Function(BuildContext context, bool pressed, bool active)
      builder;

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
                ? .96
                : active
                    ? 1.03
                    : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutBack,
            child: Stack(
              fit: StackFit.passthrough,
              clipBehavior: Clip.none,
              children: [
                widget.builder(context, _pressed, active),
                if (_focused)
                  Positioned(
                    left: -4,
                    top: -4,
                    right: -4,
                    bottom: -4,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(widget.radius + 4),
                          border: Border.all(color: _violetDark, width: 2.5),
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
}

// ============================================================================
// AGE SCREEN
// ============================================================================

class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen>
    with SingleTickerProviderStateMixin {
  // ==========================================================================
  // TTS
  // ==========================================================================

  final FlutterTts _tts = FlutterTts();

  bool _ttsReady = false;
  bool _isSpeaking = false;
  bool _isTyping = false;

  int _speechId = 0;

  // ==========================================================================
  // FLOW
  //
  // 0 = starting, 1 = name, 2 = age, 3 = class, 4 = ready
  // ==========================================================================

  int _step = 0;
  bool _busy = false;

  // ==========================================================================
  // PROFILE
  // ==========================================================================

  final TextEditingController _nameController = TextEditingController();

  String? _savedName;
  int? _selectedAge;
  int? _selectedClass;

  // ==========================================================================
  // CHAT
  // ==========================================================================

  final List<_ChatMessage> _messages = [];

  final ScrollController _scrollController = ScrollController();

  // ==========================================================================
  // ROBOT ANIMATION
  // ==========================================================================

  late final AnimationController _animationController;
  late final Animation<double> _robotFloat;

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _robotFloat = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _initializeTts();

    // NEX starts talking automatically.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startChat());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _animationController.stop();
    } else if (!_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    }
  }

  // ==========================================================================
  // TTS
  // ==========================================================================

  Future<void> _initializeTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.34);
      await _tts.setPitch(1.12);
      await _tts.setVolume(0.85);
      await _tts.awaitSpeakCompletion(true);

      try {
        await _tts.setQueueMode(1);
      } catch (_) {}

      _ttsReady = true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');

      try {
        await _tts.setLanguage('en-GB');
        await _tts.setSpeechRate(0.34);
        await _tts.setPitch(1.12);
        await _tts.setVolume(0.85);
        await _tts.awaitSpeakCompletion(true);

        _ttsReady = true;
      } catch (e2) {
        debugPrint('TTS fallback error: $e2');
      }
    }
  }

  Future<void> _speak(String text) async {
    final String clean =
        text.replaceAll(_emojiRegex, '').replaceAll('\n', ' ').trim();

    if (clean.isEmpty) return;

    final int id = ++_speechId;

    try {
      if (!_ttsReady) {
        await _initializeTts();
      }

      await _tts.stop();

      if (mounted) {
        setState(() => _isSpeaking = true);
      }

      await _tts.speak(clean);
    } catch (e) {
      debugPrint('TTS speaking error: $e');
    }

    if (mounted && id == _speechId) {
      setState(() => _isSpeaking = false);
    }
  }

  Future<void> _stopSpeaking() async {
    _speechId++;

    try {
      await _tts.stop();
    } catch (_) {}

    if (mounted) {
      setState(() => _isSpeaking = false);
    }
  }

  String get _lastRobotText {
    for (final message in _messages.reversed) {
      if (!message.isUser) {
        return message.text;
      }
    }

    return 'Hi!';
  }

  // ==========================================================================
  // CHAT MESSAGES
  // ==========================================================================

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

    // Let NEX speak in the background.
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
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  // ==========================================================================
  // STEP 0 — START
  // ==========================================================================

  Future<void> _startChat() async {
    await Future.delayed(const Duration(milliseconds: 450));

    if (!mounted) return;

    setState(() => _step = 1);

    await _addRobotMessage("Hi! 👋 What's your name?");
  }

  // ==========================================================================
  // STEP 1 — NAME
  // ==========================================================================

  Future<void> _submitName() async {
    if (_busy) return;

    final String name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('Tell me your name!');
      return;
    }

    _busy = true;

    try {
      await _stopSpeaking();

      _savedName = name;

      _addUserMessage(name);

      _nameController.clear();

      setState(() => _step = 2);

      await _addRobotMessage('Nice to meet you, $name!\nHow old are you?');
    } finally {
      _busy = false;
    }
  }

  // ==========================================================================
  // STEP 2 — AGE
  // ==========================================================================

  void _selectAge(int age) {
    _stopSpeaking();

    setState(() => _selectedAge = age);
  }

  Future<void> _submitAge() async {
    if (_busy) return;

    if (_selectedAge == null) {
      _showMessage('Choose your age!');
      return;
    }

    _busy = true;

    try {
      await _stopSpeaking();

      _addUserMessage('$_selectedAge years old');

      setState(() => _step = 3);

      await _addRobotMessage('Nice!\nWhat class are you in?');
    } finally {
      _busy = false;
    }
  }

  // ==========================================================================
  // STEP 3 — CLASS
  // ==========================================================================

  void _selectClass(int classNumber) {
    _stopSpeaking();

    setState(() => _selectedClass = classNumber);
  }

  Future<void> _submitClass() async {
    if (_busy) return;

    if (_selectedClass == null) {
      _showMessage('Choose your class!');
      return;
    }

    _busy = true;

    try {
      await _stopSpeaking();

      _addUserMessage('Class $_selectedClass');

      await _saveProfile();

      setState(() => _step = 4);

      await _addRobotMessage("You're ready, $_savedName! 🚀");
    } finally {
      _busy = false;
    }
  }

  // ==========================================================================
  // SAVE PROFILE
  // ==========================================================================

  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('profile_completed', true);
      await prefs.setString('player_name', _savedName!);
      await prefs.setInt('player_age', _selectedAge!);
      await prefs.setInt('player_class', _selectedClass!);

      // Keep old key for compatibility.
      await prefs.setInt('player_level', _selectedClass!);
    } catch (e) {
      debugPrint('Profile save error: $e');
    }
  }

  // ==========================================================================
  // STEP 4 — ENTER WORLD
  // ==========================================================================

  Future<void> _finish() async {
    await _stopSpeaking();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      _fadeSlideRoute<void>(
        SubjectScreen(classNumber: _selectedClass!),
      ),
    );
  }

  // ==========================================================================
  // SNACKBAR
  // ==========================================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _violetDark,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: _AgeBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _maxContentWidth,
                          ),
                          child: Column(
                            children: [
                              Expanded(child: _buildChat()),
                              _buildDock(constraints.maxHeight * .5),
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

  // ==========================================================================
  // HEADER  (back + clay progress + read aloud, no brand bar, like home)
  // ==========================================================================

  Widget _buildHeader() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              if (Navigator.canPop(context)) ...[
                _Pressable(
                  label: 'Back',
                  radius: 16,
                  onTap: () => Navigator.maybePop(context),
                  builder: (context, pressed, active) {
                    return _Clay(
                      width: 46,
                      height: 46,
                      radius: 16,
                      depth: pressed ? .25 : .5,
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: _violetDark,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 14),
              ],

              // Name > Age > Class > World
              Expanded(
                child: _ClayProgress(value: _step.clamp(0, 4) / 4),
              ),

              const SizedBox(width: 14),

              _Pressable(
                label: _isSpeaking ? 'Stop voice' : 'Read aloud',
                radius: 16,
                onTap: () {
                  if (_isSpeaking) {
                    _stopSpeaking();
                  } else {
                    _speak(_lastRobotText);
                  }
                },
                builder: (context, pressed, active) {
                  return _Clay(
                    width: 46,
                    height: 46,
                    radius: 16,
                    depth: (pressed || _isSpeaking) ? .25 : .5,
                    color: _isSpeaking ? _clayLilac : _clayWhite,
                    child: Center(
                      child: Icon(
                        _isSpeaking
                            ? Icons.stop_rounded
                            : Icons.volume_up_rounded,
                        color: _violetDark,
                        size: 22,
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

  // ==========================================================================
  // CHAT LIST
  // ==========================================================================

  Widget _buildChat() {
    return ListView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      padding: const EdgeInsets.fromLTRB(18, 14, 22, 20),
      children: [
        _buildRobotHeader(),
        const SizedBox(height: 24),
        for (final message in _messages)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _PopIn(
              fromRight: message.isUser,
              child: _buildMessage(message),
            ),
          ),
        if (_isTyping)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _buildTypingIndicator(),
          ),
      ],
    );
  }

  // ==========================================================================
  // ROBOT HEADER  (clay avatar + clay NEX card)
  // ==========================================================================

  Widget _buildRobotHeader() {
    final String? stepLabel = _step >= 1 && _step <= 3
        ? 'STEP $_step/3'
        : _step == 4
            ? 'READY!'
            : null;

    return AnimatedBuilder(
      animation: _robotFloat,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _robotFloat.value),
          child: child,
        );
      },
      child: Row(
        children: [
          _Clay(
            circle: true,
            width: 86,
            height: 86,
            depth: .8,
            color: _clayLilac,
            padding: const EdgeInsets.all(8),
            child: const _NexImage(
              iconSize: 44,
              iconColor: _violet,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: _Clay(
              radius: 26,
              depth: .7,
              padding: const EdgeInsets.fromLTRB(16, 13, 14, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'NEX',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 10,
                          color: _violetDark,
                        ),
                      ),
                      const Spacer(),
                      if (stepLabel != null) _TagChip(stepLabel),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Let's build your adventure! ✨",
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _violetDark.op(.85),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // CHAT MESSAGE  (NEX = white clay, child = violet clay)
  // ==========================================================================

  Widget _buildMessage(_ChatMessage message) {
    if (message.isUser) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: _Clay(
                depth: .6,
                color: _violet,
                lighten: .32,
                gloss: .3,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                child: Text(
                  message.text,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          _Clay(
            width: 34,
            height: 34,
            radius: 12,
            depth: .3,
            color: _clayLilac,
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                size: 19,
                color: _violetDark,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _MiniAvatar(),
        const SizedBox(width: 10),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 285),
            child: _Clay(
              depth: .6,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 13,
              ),
              child: Text(
                message.text,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: _violetDark,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TYPING INDICATOR
  // ==========================================================================

  Widget _buildTypingIndicator() {
    return const Row(
      children: [
        _MiniAvatar(),
        SizedBox(width: 10),
        _Clay(
          radius: 22,
          depth: .5,
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: _TypingDots(),
        ),
      ],
    );
  }

  // ==========================================================================
  // INPUT DOCK  (big clay panel that rises from the bottom)
  // ==========================================================================

  Widget _buildDock(double maxHeight) {
    final bool visible = _step >= 1 && !_isTyping;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: visible
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFF3EEFF)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(36),
                ),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _violet.op(.18),
                    blurRadius: 32,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  // Let clay shadows breathe outside the scroll viewport.
                  clipBehavior: Clip.none,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_step),
                      child: _buildCurrentInput(),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity, height: 0),
    );
  }

  // ==========================================================================
  // CURRENT INPUT
  // ==========================================================================

  Widget _buildCurrentInput() {
    switch (_step) {
      case 1:
        return _buildNameInput();

      case 2:
        return _buildAgeInput();

      case 3:
        return _buildClassInput();

      case 4:
        return Column(
          children: [
            Transform.rotate(
              angle: -.03,
              child: const _TagChip('LEVEL 1 UNLOCKED', large: true),
            ),
            const SizedBox(height: 18),
            _gameButton(
              text: 'ENTER THE WORLD',
              icon: Icons.arrow_forward_rounded,
              onTap: _finish,
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================================================
  // NAME INPUT  (pressed-in clay field + clay send)
  // ==========================================================================

  Widget _buildNameInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE6DDFB), Color(0xFFF6F2FF)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _violet.op(.14),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.white,
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _violetDark,
              ),
              decoration: InputDecoration(
                hintText: 'Type your name...',
                hintStyle: GoogleFonts.dmSans(
                  color: _inkSoft,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.person_outline_rounded,
                  color: _violet,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 5,
                ),
              ),
              onSubmitted: (_) => _submitName(),
            ),
          ),
        ),

        const SizedBox(width: 14),

        _sendButton(onTap: _submitName),
      ],
    );
  }

  // ==========================================================================
  // AGE INPUT — ONLY AGES 6 TO 11
  // ==========================================================================

  Widget _buildAgeInput() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(4, 2, 10, 14),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6, // 6, 7, 8, 9, 10, 11
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            final int age = index + 6;

            return _choiceTile(
              label: 'Age $age',
              caption: 'AGE',
              value: '$age',
              selected: _selectedAge == age,
              radius: 22,
              valueSize: 16,
              onTap: () => _selectAge(age),
            );
          },
        ),
        const SizedBox(height: 10),
        _gameButton(
          text: 'CONTINUE',
          icon: Icons.arrow_forward_rounded,
          onTap: _submitAge,
        ),
      ],
    );
  }

  // ==========================================================================
  // CLASS INPUT
  // ==========================================================================

  Widget _buildClassInput() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(4, 2, 10, 14),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final int number = index + 1;

            return _choiceTile(
              label: 'Class $number',
              caption: 'CLASS',
              value: '$number',
              selected: _selectedClass == number,
              radius: 24,
              valueSize: 18,
              onTap: () => _selectClass(number),
            );
          },
        ),
        const SizedBox(height: 10),
        _gameButton(
          text: 'SAVE & CONTINUE',
          icon: Icons.arrow_forward_rounded,
          onTap: _submitClass,
        ),
      ],
    );
  }

  // ==========================================================================
  // CLAY CHOICE TILE  (shared by age + class)
  // Unselected = puffy white clay. Selected = violet clay, pressed in.
  // ==========================================================================

  Widget _choiceTile({
    required String label,
    required String caption,
    required String value,
    required bool selected,
    required double radius,
    required double valueSize,
    required VoidCallback onTap,
  }) {
    return _Pressable(
      label: label,
      selected: selected,
      radius: radius,
      onTap: onTap,
      builder: (context, pressed, active) {
        return _Clay(
          radius: radius,
          depth: pressed
              ? .25
              : selected
                  ? .4
                  : .7,
          color: selected ? _violet : _clayWhite,
          lighten: selected ? .32 : .6,
          gloss: selected ? .3 : .55,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  caption,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .9,
                    color: selected ? Colors.white.op(.9) : _inkSoft,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.pressStart2p(
                    fontSize: valueSize,
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

  // ==========================================================================
  // SEND BUTTON  (clay)
  // ==========================================================================

  Widget _sendButton({required VoidCallback onTap}) {
    return _Pressable(
      label: 'Send',
      radius: 20,
      onTap: onTap,
      builder: (context, pressed, active) {
        return _Clay(
          width: 56,
          height: 56,
          radius: 20,
          depth: pressed ? .3 : .7,
          color: _violet,
          lighten: .32,
          gloss: .3,
          child: const Center(
            child: Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // GAME BUTTON  (squishy clay, same as the home "LET'S PLAY")
  // ==========================================================================

  Widget _gameButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _Pressable(
      label: text,
      radius: 26,
      onTap: onTap,
      builder: (context, pressed, active) {
        return _Clay(
          width: double.infinity,
          height: 62,
          radius: 26,
          depth: pressed
              ? .3
              : active
                  ? 1.0
                  : .8,
          color: _violet,
          lighten: .32,
          gloss: .32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.op(.24),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _tts.stop();
    _nameController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

// ============================================================================
// CHAT MESSAGE
// ============================================================================

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

// ============================================================================
// BACKGROUND  (pastel gradient, soft clay blobs, faint circuit traces)
// ============================================================================

class _AgeBackground extends StatelessWidget {
  const _AgeBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF6F2FF),
            Color(0xFFEFE8FF),
            Color(0xFFF4EBFF),
            Color(0xFFFCFAFF),
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _CircuitTracePainter()),
            ),
          ),
          _ClayBlob(
            alignment: Alignment(-1.25, -0.8),
            size: 230,
            color: Color(0xFFE4D9FF),
          ),
          _ClayBlob(
            alignment: Alignment(1.3, -0.1),
            size: 190,
            color: Color(0xFFDCCEFF),
          ),
          _ClayBlob(
            alignment: Alignment(-1.1, 0.9),
            size: 210,
            color: Color(0xFFF0E5FF),
          ),
        ],
      ),
    );
  }
}

class _ClayBlob extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final Color color;

  const _ClayBlob({
    required this.alignment,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: _Clay(
          circle: true,
          width: size,
          height: size,
          color: color,
          depth: 1.3,
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _CircuitTracePainter extends CustomPainter {
  const _CircuitTracePainter();

  static const List<List<double>> _traces = [
    [.025, .20, .065, .20, .08, .17, .14, .17],
    [.86, .12, .91, .12, .925, .15, .975, .15],
    [.03, .70, .07, .70, .085, .67, .125, .67],
    [.875, .74, .92, .74, .935, .71, .975, .71],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = _violetMid.op(.14);

    final Paint dot = Paint()..color = _violetMid.op(.28);

    for (final p in _traces) {
      Offset at(int i) => Offset(size.width * p[i * 2], size.height * p[i * 2 + 1]);

      final Path path = Path()..moveTo(at(0).dx, at(0).dy);
      for (int i = 1; i < 4; i++) {
        path.lineTo(at(i).dx, at(i).dy);
      }

      canvas.drawPath(path, line);
      canvas.drawCircle(at(3), 2.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// CLAY PROGRESS BAR  (Name > Age > Class > World)
// ============================================================================

class _ClayProgress extends StatelessWidget {
  const _ClayProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Semantics(
          label: 'Progress',
          value: '${(v * 100).round()} percent',
          excludeSemantics: true,
          child: Container(
            height: 20,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE2D8FA), Color(0xFFF3EEFF)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _violet.op(.12)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.white,
                  offset: Offset(0, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: math.max(.08, v.clamp(0.0, 1.0)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_violetLight, _violet],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _violet.op(.35),
                        offset: const Offset(0, 2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
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
// TAG CHIP  (small clay sticker)
// ============================================================================

class _TagChip extends StatelessWidget {
  const _TagChip(this.text, {this.large = false});

  final String text;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: _Clay(
        radius: 18,
        color: _clayLilac,
        depth: .3,
        gloss: .4,
        padding: EdgeInsets.symmetric(
          horizontal: large ? 16 : 10,
          vertical: large ? 9 : 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (large) ...[
              const Icon(Icons.auto_awesome_rounded, size: 16, color: _violet),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: GoogleFonts.dmSans(
                color: _violetDark,
                fontSize: large ? 13 : 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// NEX IMAGE
// ============================================================================

class _NexImage extends StatelessWidget {
  const _NexImage({required this.iconSize, required this.iconColor});

  final double iconSize;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        _nexImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Icon(
            Icons.smart_toy_rounded,
            color: iconColor,
            size: iconSize,
          );
        },
      ),
    );
  }
}

// ============================================================================
// MINI AVATAR  (clay)
// ============================================================================

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar();

  @override
  Widget build(BuildContext context) {
    return const _Clay(
      circle: true,
      width: 36,
      height: 36,
      depth: .3,
      color: _clayLilac,
      padding: EdgeInsets.all(5),
      child: _NexImage(iconSize: 18, iconColor: _violet),
    );
  }
}

// ============================================================================
// TYPING DOTS
// ============================================================================

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'NEX is typing',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final double t = (_controller.value + i * .18) % 1.0;
              final double bump = math.max(0.0, math.sin(t * 2 * math.pi));

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.5),
                child: Transform.translate(
                  offset: Offset(0, -5 * bump),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-.4, -.4),
                        colors: [
                          Colors.white,
                          _violetLight,
                          _violet.op(.55 + .45 * bump),
                        ],
                        stops: const [0, .4, 1],
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ============================================================================
// POP-IN MESSAGE ANIMATION
// ============================================================================

class _PopIn extends StatelessWidget {
  const _PopIn({required this.child, required this.fromRight});

  final Widget child;
  final bool fromRight;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset((fromRight ? 14 : -14) * (1 - t), 8 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}