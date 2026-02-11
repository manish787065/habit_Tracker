import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/gamification_provider.dart';
import '../../domain/gamification_types.dart';

class PointListenerWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const PointListenerWrapper({super.key, required this.child});

  @override
  ConsumerState<PointListenerWrapper> createState() => _PointListenerWrapperState();
}

class _PointListenerWrapperState extends ConsumerState<PointListenerWrapper> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  final List<_EmojiAnimation> _activeEmojis = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    for (var anim in _activeEmojis) {
      anim.dispose();
    }
    super.dispose();
  }

  void _spawnEmojis() {
    final theme = ref.read(gamificationProvider);
    final emoji = theme.emoji;
    
    setState(() {
      for (int i = 0; i < 6; i++) {
        final anim = _EmojiAnimation(
          emoji: emoji,
          onComplete: (item) {
            if (mounted) {
              setState(() => _activeEmojis.remove(item));
            }
          },
          vsync: this,
        );
        _activeEmojis.add(anim);
        anim.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<User?>(authProvider, (previous, next) {
      if (previous != null && next != null) {
        final nextPoints = next.points ?? 0;
        final prevPoints = previous.points ?? 0;
        final diff = nextPoints - prevPoints;
        if (diff > 0) {
          _showReward(diff);
          _confettiController.play();
          _spawnEmojis();
        }
      }
    });

    return Stack(
      children: [
        widget.child,
        // Mess-free sparkle
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.amber, Colors.orangeAccent],
            numberOfParticles: 6, 
            gravity: 0.2,
          ),
        ),
        // Flying themed items
        ..._activeEmojis.map((e) => e.build(context)),
      ],
    );
  }

  void _showReward(int amount) {
    final theme = ref.read(gamificationProvider);
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "+$amount ${theme.emoji} earned!",
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.8),
        width: 180,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _EmojiAnimation {
  final String emoji;
  final Function(_EmojiAnimation) onComplete;
  final TickerProvider vsync;
  late AnimationController _controller;
  late Animation<Offset> _position;
  late Animation<double> _opacity;

  _EmojiAnimation({required this.emoji, required this.onComplete, required this.vsync}) {
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000 + (DateTime.now().millisecond % 500)),
      vsync: vsync,
    );

    final randomX = (DateTime.now().microsecondsSinceEpoch % 200 - 100) / 50.0;
    
    _position = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset(randomX, -1.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onComplete(this);
      }
    });
  }

  void start() => _controller.forward();
  void dispose() => _controller.dispose();

  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Align(
          alignment: Alignment.center,
          child: FractionalTranslation(
            translation: _position.value,
            child: Opacity(
              opacity: _opacity.value,
              child: Text(emoji, style: const TextStyle(fontSize: 45)),
            ),
          ),
        );
      },
    );
  }
}
