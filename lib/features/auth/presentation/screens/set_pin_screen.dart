import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';

/// 4-digit PIN setup / entry screen for quick re-login.
///
/// Modes:
///  - [PinScreenMode.set]    — first time setup: enter PIN twice to confirm
///  - [PinScreenMode.verify] — quick re-login: enter saved PIN to unlock
///  - [PinScreenMode.change] — change existing PIN (set mode + old-PIN check)
class SetPinScreen extends ConsumerStatefulWidget {
  final PinScreenMode mode;

  const SetPinScreen({super.key, this.mode = PinScreenMode.set});

  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

enum PinScreenMode { set, verify, change }

class _SetPinScreenState extends ConsumerState<SetPinScreen>
    with TickerProviderStateMixin {
  // Current 4-digit PIN being entered
  String _pin = '';

  // During [set] mode: first entry stored here until confirmed
  String _firstPin = '';

  // Confirm step — true when user has entered PIN once and needs to re-enter
  bool _isConfirmStep = false;

  String? _errorMessage;
  bool _success = false;

  // Shake animation for wrong PIN
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // Scale animation for success tick
  late AnimationController _successCtrl;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(_shakeCtrl);

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _successScale = CurvedAnimation(
      parent: _successCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  // ── PIN input handling ────────────────────────────────────────────────────

  void _onKeyTap(String digit) {
    if (_pin.length >= 4) return;
    final next = _pin + digit;
    setState(() {
      _pin = next;
      _errorMessage = null;
    });
    if (next.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), () => _onPinComplete(next));
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _onPinComplete(String pin) async {
    switch (widget.mode) {
      case PinScreenMode.set:
      case PinScreenMode.change:
        await _handleSetMode(pin);
        break;
      case PinScreenMode.verify:
        await _handleVerifyMode(pin);
        break;
    }
  }

  Future<void> _handleSetMode(String pin) async {
    if (!_isConfirmStep) {
      // First entry — ask to confirm
      setState(() {
        _firstPin = pin;
        _pin = '';
        _isConfirmStep = true;
      });
    } else {
      // Second entry — compare
      if (pin == _firstPin) {
        await ref.read(pinNotifierProvider.notifier).savePin(pin);
        setState(() => _success = true);
        _successCtrl.forward();
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) context.pop();
      } else {
        _shake();
        setState(() {
          _firstPin = '';
          _pin = '';
          _isConfirmStep = false;
          _errorMessage = 'PINs did not match. Try again.';
        });
      }
    }
  }

  Future<void> _handleVerifyMode(String pin) async {
    final isCorrect = await ref.read(pinNotifierProvider.notifier).verifyPin(pin);
    if (isCorrect) {
      setState(() => _success = true);
      _successCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          final authState = ref.read(authNotifierProvider).valueOrNull;
          if (authState is AuthStateAuthenticated) {
            context.go(authState.homeRoute);
            return;
          }
        }
        context.pop();
      }
    } else {
      _shake();
      setState(() {
        _pin = '';
        _errorMessage = 'Incorrect PIN. Please try again.';
      });
    }
  }

  void _shake() {
    _shakeCtrl.forward(from: 0);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              _buildTitle(),
              const SizedBox(height: AppSpacing.huge),
              _buildPinDots(),
              const SizedBox(height: AppSpacing.lg),
              _buildError(),
              const Spacer(),
              _buildKeypad(),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    String title;
    String subtitle;

    if (_success) {
      title = widget.mode == PinScreenMode.verify ? 'Unlocked!' : 'PIN Saved!';
      subtitle = '';
    } else if (widget.mode == PinScreenMode.verify) {
      title = 'Enter Your PIN';
      subtitle = 'Use your 4-digit PIN to unlock';
    } else if (_isConfirmStep) {
      title = 'Confirm PIN';
      subtitle = 'Re-enter your PIN to confirm';
    } else {
      title = widget.mode == PinScreenMode.change ? 'New PIN' : 'Set a PIN';
      subtitle = 'Choose a 4-digit PIN for quick access';
    }

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _success
              ? ScaleTransition(
                  key: const ValueKey('tick'),
                  scale: _successScale,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withOpacity(0.15),
                      border: Border.all(color: AppColors.success, width: 2),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.success, size: 36),
                  ),
                )
              : const Icon(
                  key: ValueKey('lock'),
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: AppTypography.headlineLarge),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPinDots() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(_shakeAnim.value, 0),
        child: child,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) {
          final filled = i < _pin.length;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _success
                  ? AppColors.success
                  : filled
                      ? AppColors.primary
                      : Colors.transparent,
              border: Border.all(
                color: _success
                    ? AppColors.success
                    : filled
                        ? AppColors.primary
                        : AppColors.border,
                width: 2,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildError() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _errorMessage != null
          ? Padding(
              key: ValueKey(_errorMessage),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
              child: Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          for (final row in _keypadLayout)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((key) => _KeypadKey(
                  label: key,
                  onTap: () {
                    if (key == '⌫') {
                      _onBackspace();
                    } else if (key.isNotEmpty) {
                      _onKeyTap(key);
                    }
                  },
                )).toList(),
              ),
            ),
          // Biometric / skip row
          if (widget.mode == PinScreenMode.verify)
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Use password instead',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static const _keypadLayout = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];
}

// ---------------------------------------------------------------------------
// Keypad key widget
// ---------------------------------------------------------------------------

class _KeypadKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _KeypadKey({required this.label, required this.onTap});

  @override
  State<_KeypadKey> createState() => _KeypadKeyState();
}

class _KeypadKeyState extends State<_KeypadKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.label.isEmpty) return const SizedBox(width: 72, height: 72);

    final isBackspace = widget.label == '⌫';

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.card,
          border: Border.all(
            color: _pressed ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Center(
          child: isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  color: AppColors.textSecondary,
                  size: AppSpacing.iconLg,
                )
              : Text(
                  widget.label,
                  style: AppTypography.headlineLarge.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}

