import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';
import 'login_page.dart';
import '../backend/firebase_service.dart';
import '../backend/app_locale.dart';

// ════════════════════════════════════════════
//  صفحة الأمان وكلمة المرور
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
  String? _successMsg;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_currentCtrl.text.isEmpty) return 'يرجى إدخال كلمة المرور الحالية';
    if (_newCtrl.text.length < 6) {
      return 'كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل';
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      return 'كلمة المرور الجديدة غير متطابقة';
    }
    if (_newCtrl.text == _currentCtrl.text) {
      return 'كلمة المرور الجديدة يجب أن تختلف عن الحالية';
    }
    return null;
  }

  String _friendlyError(String e) {
    if (e.contains('wrong-password') || e.contains('invalid-credential')) {
      return 'كلمة المرور الحالية غير صحيحة';
    }
    if (e.contains('weak-password')) return 'كلمة المرور الجديدة ضعيفة';
    if (e.contains('requires-recent-login')) {
      return 'يرجى تسجيل الدخول من جديد لأسباب أمنية';
    }
    if (e.contains('network')) return 'تحقق من اتصالك بالإنترنت';
    return 'حدث خطأ، حاول مجدداً';
  }

  Future<void> _handleChange() async {
    final err = _validate();
    if (err != null) {
      setState(() {
        _errorMsg = err;
        _successMsg = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
      _successMsg = null;
    });
    try {
      await FirebaseService.changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _successMsg = tr('security_password_changed');
        _currentCtrl.clear();
        _newCtrl.clear();
        _confirmCtrl.clear();
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = _friendlyError(e.toString());
      });
    }
  }

  Future<void> _handleSendReset() async {
    final email = FirebaseService.currentUser?.email;
    if (email == null) return;
    try {
      await FirebaseService.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: C.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Text('تم إرسال رابط الاستعادة إلى بريدك',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: C.error,
        behavior: SnackBarBehavior.floating,
        content: Text(_friendlyError(e.toString()),
            style: const TextStyle(fontFamily: 'Tajawal')),
      ));
    }
  }

  Future<void> _handleSignOutAll() async {
    await FirebaseService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.notifier,
      builder: (context, locale, _) {
        final email = FirebaseService.currentUser?.email ?? '—';
        return Scaffold(
          backgroundColor: C.light,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(email),
                const SizedBox(height: 16),
                _buildPasswordCard(),
                const SizedBox(height: 12),
                _buildAccountActions(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String email) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [C.panelDark1, C.panelDark2, C.panelDark3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 36),
                  Text(tr('security_title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(
                          AppLocale.current.languageCode == 'ar'
                              ? FontAwesomeIcons.arrowRight
                              : FontAwesomeIcons.arrowLeft,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [C.primary, C.secondary]),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(FontAwesomeIcons.shieldHalved,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              Text(email,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(FontAwesomeIcons.lock, size: 14, color: C.primary),
              Text(tr('security_change_password'),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: C.dark)),
            ],
          ),
          const SizedBox(height: 14),
          _buildField(
            label: tr('security_current_password'),
            ctrl: _currentCtrl,
            show: _showCurrent,
            onToggle: () => setState(() => _showCurrent = !_showCurrent),
            hint: '••••••••',
          ),
          const SizedBox(height: 14),
          _buildField(
            label: tr('security_new_password'),
            ctrl: _newCtrl,
            show: _showNew,
            onToggle: () => setState(() => _showNew = !_showNew),
            hint: '••••••••',
          ),
          const SizedBox(height: 14),
          _buildField(
            label: tr('security_confirm_new_password'),
            ctrl: _confirmCtrl,
            show: _showConfirm,
            onToggle: () => setState(() => _showConfirm = !_showConfirm),
            hint: '••••••••',
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            _banner(_errorMsg!, C.error, FontAwesomeIcons.circleXmark),
          ],
          if (_successMsg != null) ...[
            const SizedBox(height: 12),
            _banner(_successMsg!, C.success, FontAwesomeIcons.circleCheck),
          ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loading ? null : _handleChange,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: _loading
                    ? null
                    : const LinearGradient(colors: [C.primary, C.secondary]),
                color: _loading ? C.border : null,
                borderRadius: BorderRadius.circular(10),
                boxShadow: _loading
                    ? []
                    : [
                        BoxShadow(
                            color: C.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_loading) ...[
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white))),
                    const SizedBox(width: 10),
                    Text(tr('loading'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ] else ...[
                    const Icon(FontAwesomeIcons.check,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Text(tr('security_update'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController ctrl,
    required bool show,
    required VoidCallback onToggle,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: C.dark)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: !show,
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 14, color: C.dark),
          decoration: InputDecoration(
            hintText: hint,
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
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            prefixIcon:
                const Icon(FontAwesomeIcons.lock, size: 14, color: C.muted),
            suffixIcon: IconButton(
              icon: Icon(
                  show ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
                  size: 14,
                  color: C.muted),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _banner(String msg, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(msg,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 13, color: color),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          _actionTile(
            icon: FontAwesomeIcons.envelope,
            color: C.accent,
            label: tr('security_reset_email'),
            onTap: _handleSendReset,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _actionTile(
            icon: FontAwesomeIcons.rightFromBracket,
            color: C.error,
            label: tr('security_signout_all'),
            onTap: _handleSignOutAll,
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
                AppLocale.current.languageCode == 'ar'
                    ? FontAwesomeIcons.angleLeft
                    : FontAwesomeIcons.angleRight,
                size: 12,
                color: C.muted),
            Row(children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const SizedBox(width: 12),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 14, color: color),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
