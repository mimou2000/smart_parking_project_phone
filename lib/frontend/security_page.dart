import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';
import '../backend/firebase_service.dart';
import '../backend/app_locale.dart';

// ════════════════════════════════════════════
//  صفحة الأمان — تغيير كلمة المرور
// ════════════════════════════════════════════
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _friendlyError(String e) {
    if (e.contains('wrong-password') || e.contains('invalid-credential')) {
      return tr('err_invalid_creds');
    }
    if (e.contains('weak-password')) return tr('err_weak_password');
    if (e.contains('too-many-requests')) return tr('err_too_many');
    if (e.contains('network')) return tr('err_network');
    return tr('password_change_failed');
  }

  Future<void> _handleChange() async {
    final current = _currentCtrl.text;
    final newPass = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() => _errorMsg = tr('err_fill_all'));
      return;
    }
    if (newPass != confirm) {
      setState(() => _errorMsg = tr('err_passwords_no_match'));
      return;
    }
    if (newPass.length < 6) {
      setState(() => _errorMsg = tr('err_password_short'));
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await FirebaseService.changePassword(
        currentPassword: current,
        newPassword: newPass,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: C.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            tr('password_changed'),
            style: const TextStyle(
                fontFamily: 'Tajawal', fontWeight: FontWeight.w700),
          ),
        ),
      );
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMsg = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.notifier,
      builder: (context, locale, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: C.light,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isRtl = AppLocale.isRtl;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [C.panelDark1, C.panelDark2, C.panelDark3],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isRtl
                        ? FontAwesomeIcons.arrowRight
                        : FontAwesomeIcons.arrowLeft,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
              Text(
                tr('security_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [C.primary, C.secondary]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(FontAwesomeIcons.shieldHalved,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr('change_password'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: C.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _passwordField(
            label: tr('current_password'),
            ctrl: _currentCtrl,
            show: _showCurrent,
            onToggle: () => setState(() => _showCurrent = !_showCurrent),
            icon: FontAwesomeIcons.lock,
          ),
          const SizedBox(height: 14),
          _passwordField(
            label: tr('new_password'),
            ctrl: _newCtrl,
            show: _showNew,
            onToggle: () => setState(() => _showNew = !_showNew),
            icon: FontAwesomeIcons.key,
          ),
          const SizedBox(height: 14),
          _passwordField(
            label: tr('confirm_new_password'),
            ctrl: _confirmCtrl,
            show: _showConfirm,
            onToggle: () => setState(() => _showConfirm = !_showConfirm),
            icon: FontAwesomeIcons.lockOpen,
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: C.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: C.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(FontAwesomeIcons.circleXmark,
                      size: 13, color: C.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: C.error,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          GestureDetector(
            onTap: _loading ? null : _handleChange,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: _loading
                    ? null
                    : const LinearGradient(
                        colors: [C.primary, C.secondary]),
                color: _loading ? C.border : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _loading
                    ? []
                    : [
                        BoxShadow(
                          color: C.primary.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        )
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_loading) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      tr('loading'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else ...[
                    const Icon(FontAwesomeIcons.shieldHalved,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      tr('change_password'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController ctrl,
    required bool show,
    required VoidCallback onToggle,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: C.dark),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: ctrl,
          obscureText: !show,
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 14, color: C.dark),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: C.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: C.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: C.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            prefixIcon: Icon(icon, size: 14, color: C.muted),
            suffixIcon: IconButton(
              icon: Icon(
                show ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
                size: 14,
                color: C.muted,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}
