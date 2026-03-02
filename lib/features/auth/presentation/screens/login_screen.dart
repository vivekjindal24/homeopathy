import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

/// Dark-themed login screen.
///
/// Design spec:
///  - Background: #060C18 with radial gradient top-right
///  - Card: #111E35 with 1px border rgba(255,255,255,0.08)
///  - Input fields: #0D1628 bg, #00D2B4 focused border
///  - CTA button: linear gradient #00D2B4 → #3882FF, radius 12 px
///  - Fonts: Outfit labels, JetBrains Mono for phone number
class LoginScreen extends ConsumerStatefulWidget {
  /// When non-null, a banner is shown at the top (e.g. "Session expired").
  final String? message;
  const LoginScreen({super.key, this.message});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  // -- Tab / form state
  late TabController _tabController;
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();

  // -- Controllers
  final _emailCtrl = TextEditingController();
  final _passwordEmailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordPhoneCtrl = TextEditingController();

  // -- UI state
  bool _obscureEmailPwd = true;
  bool _obscurePhonePwd = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Show banner message passed via navigation
    if (widget.message == 'session_expired') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _errorMessage = 'Your session has expired. Please sign in again.');
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordEmailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordPhoneCtrl.dispose();
    super.dispose();
  }

  // ── Navigation listener ──────────────────────────────────────────────────

  void _onAuthStateChange(AsyncValue<AuthState>? prev, AsyncValue<AuthState> next) {
    next.whenData((s) {
      if (s is AuthStateAuthenticated && mounted) {
        context.go(s.homeRoute);
      } else if (s is AuthStateError) {
        setState(() => _errorMessage = s.message);
      }
    });
  }

  // ── Submissions ──────────────────────────────────────────────────────────

  Future<void> _submitEmail() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      final err = await ref.read(authNotifierProvider.notifier).signInWithEmail(
            _emailCtrl.text.trim(),
            _passwordEmailCtrl.text,
          );
      if (err != null && mounted) setState(() => _errorMessage = err);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPhone() async {
    if (!(_phoneFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      final err = await ref.read(authNotifierProvider.notifier).signInWithPhone(
            _phoneCtrl.text.trim(),
            _passwordPhoneCtrl.text,
          );
      if (err != null && mounted) setState(() => _errorMessage = err);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, _onAuthStateChange);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            _RadialGradientBackground(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    _buildLogoHeader(),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildCard(_isLoading),
                    const SizedBox(height: AppSpacing.lg),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sections ─────────────────────────────────────────────────────────────

  Widget _buildLogoHeader() {
    return Column(
      children: [
        // Logo mark
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
              stops: [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_pharmacy_rounded,
            size: 38,
            color: AppColors.textInverse,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppConstants.clinicName,
          style: AppTypography.headlineLarge.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Staff & Doctor Portal',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCard(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error banner
          if (_errorMessage != null) ...[
            _ErrorBanner(message: _errorMessage!),
            const SizedBox(height: AppSpacing.lg),
          ],
          // Tab bar: Email | Phone
          _buildTabBar(),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 260,
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildEmailForm(isLoading),
                _buildPhoneForm(isLoading),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Remember me
          _buildRememberMe(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() => _errorMessage = null),
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelLarge,
        labelColor: AppColors.textInverse,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: const [
          Tab(text: 'Email'),
          Tab(text: 'Phone'),
        ],
      ),
    );
  }

  Widget _buildEmailForm(bool isLoading) {
    return Form(
      key: _emailFormKey,
      child: Column(
        children: [
          _LoginField(
            label: 'Email address',
            hint: 'doctor@clinic.in',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: AppValidators.email,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          _LoginField(
            label: 'Password',
            hint: '••••••••',
            controller: _passwordEmailCtrl,
            obscureText: _obscureEmailPwd,
            prefixIcon: Icons.lock_outline_rounded,
            validator: AppValidators.password,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => isLoading ? null : _submitEmail(),
            trailingIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscureEmailPwd = !_obscureEmailPwd),
              icon: Icon(
                _obscureEmailPwd
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: AppSpacing.iconMd,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _GradientButton(
            label: 'Sign In',
            isLoading: isLoading,
            onPressed: isLoading ? null : _submitEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm(bool isLoading) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        children: [
          _LoginField(
            label: 'Mobile Number',
            hint: '98765 43210',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            prefixText: '+91 ',
            useMono: true,
            validator: AppValidators.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _IndianPhoneFormatter(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _LoginField(
            label: 'Password',
            hint: '••••••••',
            controller: _passwordPhoneCtrl,
            obscureText: _obscurePhonePwd,
            prefixIcon: Icons.lock_outline_rounded,
            validator: AppValidators.password,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => isLoading ? null : _submitPhone(),
            trailingIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePhonePwd = !_obscurePhonePwd),
              icon: Icon(
                _obscurePhonePwd
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: AppSpacing.iconMd,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _GradientButton(
            label: 'Sign In',
            isLoading: isLoading,
            onPressed: isLoading ? null : _submitPhone,
          ),
        ],
      ),
    );
  }

  Widget _buildRememberMe() {
    return GestureDetector(
      onTap: () => setState(() => _rememberMe = !_rememberMe),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: _rememberMe ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: _rememberMe ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
            child: _rememberMe
                ? const Icon(Icons.check_rounded,
                    size: 13, color: AppColors.textInverse)
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Remember me',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Accounts are managed by the clinic administrator.',
          style: AppTypography.labelSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppConstants.clinicCity,
          style: AppTypography.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// Background with radial gradient glow in the top-right corner.
class _RadialGradientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Solid dark background
          Container(color: AppColors.background),
          // Teal radial glow — top right
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Faint blue glow — bottom left
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Branded text field with design-spec styling.
class _LoginField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final String? prefixText;
  final bool useMono;
  final Widget? trailingIcon;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const _LoginField({
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.prefixText,
    this.useMono = false,
    this.trailingIcon,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          inputFormatters: inputFormatters,
          style: useMono
              ? AppTypography.monoMedium.copyWith(
                  color: AppColors.textPrimary, letterSpacing: 1.5)
              : AppTypography.bodyMedium,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textDisabled,
            ),
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon,
                    size: AppSpacing.iconMd, color: AppColors.textSecondary)
                : null,
            prefixText: prefixText,
            prefixStyle: AppTypography.monoMedium.copyWith(
              color: AppColors.primary,
            ),
            suffixIcon: trailingIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorStyle: AppTypography.labelSmall
                .copyWith(color: AppColors.error, letterSpacing: 0),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }
}

/// Gradient CTA button per design spec.
class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null || isLoading
              ? const LinearGradient(
                  colors: [AppColors.border, AppColors.border],
                )
              : const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppColors.primary, AppColors.secondary],
                ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: onPressed == null || isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.textInverse,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(AppColors.textInverse),
                  ),
                )
              : Text(label,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  )),
        ),
      ),
    );
  }
}

/// Error/info banner shown inside the card.
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats 10-digit Indian phone numbers as "XXXXX XXXXX".
class _IndianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      return oldValue; // block > 10 digits
    }
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 5) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
