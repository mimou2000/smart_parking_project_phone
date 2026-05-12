import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';
import 'register_page.dart';
import 'home_shell.dart';
import '../backend/firebase_service.dart';
import '../backend/app_locale.dart';
import '../backend/guest_service.dart';

// ════════════════════════════════════════════
//  صفحة تسجيل الدخول — Firebase Auth
// ════════════════════════════════════════════
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _showPass = false;
  bool _remember = false;
  bool _loading  = false;
  String? _errorMsg;

  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  late final AnimationController _anim;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _anim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMsg = tr('err_fill_all'));
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await FirebaseService.signIn(email, pass);
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeShell()));
    } catch (e) {
      setState(() => _errorMsg = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String e) {
    if (e.contains('invalid-credential') || e.contains('wrong-password')) return tr('err_invalid_creds');
    if (e.contains('user-not-found')) return tr('err_user_not_found');
    if (e.contains('too-many-requests')) return tr('err_too_many');
    if (e.contains('network')) return tr('err_network');
    return tr('err_generic');
  }

  void _handleGuestLogin() {
    GuestService.enterGuestMode();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.notifier,
      builder: (context, locale, _) => _buildContent(),
    );
  }

  Widget _buildContent() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            colors: [C.panelDark1, C.panelDark2, C.panelDark3],
            stops:  [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slide,
                          child: _buildFormCard(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 40, offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLangSelector(),
          const SizedBox(height: 12),
          _buildBrand(),
          const SizedBox(height: 22),
          _buildHeader(),
          const SizedBox(height: 24),
          _buildField(label: tr('email'), icon: FontAwesomeIcons.envelope,
              ctrl: _emailCtrl, hint: "user@example.com", isPassword: false),
          const SizedBox(height: 16),
          _buildField(label: tr('password'), icon: FontAwesomeIcons.lock,
              ctrl: _passCtrl, hint: "••••••••", isPassword: true),
          const SizedBox(height: 14),
          _buildOptions(),
          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            _buildErrorBanner(_errorMsg!),
          ],
          const SizedBox(height: 20),
          _buildLoginBtn(),
          const SizedBox(height: 14),
          _buildGuestBtn(),
          const SizedBox(height: 16),
          _buildSignupLink(),
        ],
      ),
    );
  }

  // ══ Dropdown اختيار اللغة ══
  Widget _buildLangSelector() {
    final currentCode = AppLocale.current.languageCode;

    const langs = [
      {'code': 'ar', 'label': 'العربية',  'short': 'AR'},
      {'code': 'fr', 'label': 'Français', 'short': 'FR'},
      {'code': 'en', 'label': 'English',  'short': 'EN'},
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: C.light,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: C.border, width: 1.5),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentCode,
            isDense: true,
            icon: const Icon(FontAwesomeIcons.chevronDown, size: 10, color: C.muted),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: C.dark,
              fontFamily: 'Tajawal',
            ),
            onChanged: (code) async {
              if (code == null) return;
              await AppLocale.setLanguage(code);
              if (mounted) setState(() {});
            },
            items: langs.map((l) {
              return DropdownMenuItem<String>(
                value: l['code'],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أيقونة الاختصار
                    Container(
                      width: 26,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [C.primary, C.secondary]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l['short']!,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'Tajawal',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(l['label']!,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Tajawal')),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [C.primary, C.secondary],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: C.primary.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: const Icon(FontAwesomeIcons.squareParking, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 12),
        const Text("SmartParking",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.dark)),
        const SizedBox(height: 3),
        Text(tr('app_subtitle'), style: const TextStyle(fontSize: 12, color: C.muted)),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(tr('login_welcome'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: C.dark)),
        const SizedBox(height: 5),
        Text(tr('login_subtitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: C.muted)),
      ],
    );
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: C.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Expanded(
            child: Text(msg,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, color: C.error, fontWeight: FontWeight.w700)),
          ),
          const Icon(FontAwesomeIcons.circleXmark, size: 13, color: C.error),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController ctrl,
    required String hint,
    required bool isPassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.dark)),
        const SizedBox(height: 7),
        TextField(
          controller:    ctrl,
          obscureText:   isPassword && !_showPass,
          textAlign:     TextAlign.right,
          textDirection: TextDirection.ltr,
          onSubmitted:   (_) => _handleLogin(),
          style: const TextStyle(fontSize: 14, color: C.dark),
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            filled:    true,
            fillColor: C.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: C.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: C.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            prefixIcon: Icon(icon, size: 15, color: C.muted),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(_showPass ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
                  size: 14, color: C.muted),
              onPressed: () => setState(() => _showPass = !_showPass),
            )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: _showForgotPasswordDialog,
          child: Text(tr('forgot_password'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.primary)),
        ),
        Row(
          children: [
            Text(tr('remember_me'), style: const TextStyle(fontSize: 12, color: C.muted)),
            const SizedBox(width: 6),
            SizedBox(
              width: 20, height: 20,
              child: Checkbox(
                value: _remember,
                activeColor: C.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: const BorderSide(color: C.border, width: 1.5),
                onChanged: (v) => setState(() => _remember = v!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final ctrl = TextEditingController();
    bool sending = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(tr('forgot_dialog_title'),
              textAlign: TextAlign.start,
              style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
          content: TextField(
            controller: ctrl,
            textAlign: TextAlign.start,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: tr('forgot_dialog_hint'),
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: C.primary),
              onPressed: sending
                  ? null
                  : () async {
                final email = ctrl.text.trim();
                if (email.isEmpty) return;
                setDialogState(() => sending = true);
                try {
                  await FirebaseService.sendPasswordResetEmail(email);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: C.success,
                    content: Text(tr('reset_sent'),
                        style: const TextStyle(fontFamily: 'Tajawal')),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                } catch (e) {
                  setDialogState(() => sending = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: C.error,
                    content: Text(_friendlyError(e.toString()),
                        style: const TextStyle(fontFamily: 'Tajawal')),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              child: sending
                  ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text(tr('send_btn'),
                  style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginBtn() {
    return GestureDetector(
      onTap: _loading ? null : _handleLogin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: _loading ? null : const LinearGradient(
            begin: Alignment.centerRight, end: Alignment.centerLeft,
            colors: [C.primary, C.secondary],
          ),
          color: _loading ? C.border : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _loading ? [] :
          [BoxShadow(color: C.primary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading) ...[
              const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white))),
              const SizedBox(width: 10),
              Text(tr('logging_in'),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ] else ...[
              const Icon(Icons.login_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(tr('login_btn'),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuestBtn() {
    return GestureDetector(
      onTap: _handleGuestLogin,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: C.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FontAwesomeIcons.userSecret, size: 15, color: C.muted),
            const SizedBox(width: 8),
            Text(tr('guest_login'),
                style: const TextStyle(color: C.muted, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RegisterPage())),
          child: Text(tr('signup_link'),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: C.primary,
                  decoration: TextDecoration.underline, decorationColor: C.primary)),
        ),
        const SizedBox(width: 5),
        Text(tr('no_account'), style: const TextStyle(fontSize: 13, color: C.muted)),
      ],
    );
  }
}