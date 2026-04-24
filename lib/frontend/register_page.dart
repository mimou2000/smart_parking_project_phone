import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';
import 'home_shell.dart';
import '../backend/firebase_service.dart';

// ════════════════════════════════════════════
//  صفحة إنشاء الحساب — Firebase Auth
// ════════════════════════════════════════════
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  bool _showPass    = false;
  bool _showConfirm = false;
  bool _loading     = false;
  String? _errorMsg;

  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _plateCtrl   = TextEditingController();

  String? _selectedCarType;
  final List<String> _carTypes = ['سيدان', 'SUV', 'هاتشباك', 'بيك أب', 'كوبيه', 'ميني فان', 'رياضية'];

  late final AnimationController _anim;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _anim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name    = _nameCtrl.text.trim();
    final email   = _emailCtrl.text.trim();
    final pass    = _passCtrl.text;
    final confirm = _confirmCtrl.text;
    final plate   = _plateCtrl.text.trim();

    if ([name, email, pass, confirm, plate].any((s) => s.isEmpty) || _selectedCarType == null) {
      setState(() => _errorMsg = 'يرجى تعبئة جميع الحقول');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMsg = 'كلمتا المرور غير متطابقتين');
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorMsg = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    setState(() { _loading = true; _errorMsg = null; });
    try {
      await FirebaseService.register(
        email:   email,
        password: pass,
        name:    name,
        plate:   plate,
        carType: _selectedCarType!,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } catch (e) {
      setState(() => _errorMsg = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String e) {
    if (e.contains('email-already-in-use')) return 'هذا البريد مسجّل مسبقاً';
    if (e.contains('invalid-email'))        return 'صيغة البريد الإلكتروني غير صحيحة';
    if (e.contains('weak-password'))        return 'كلمة المرور ضعيفة جداً';
    if (e.contains('network'))              return 'تحقق من اتصالك بالإنترنت';
    return 'حدث خطأ، حاول مجدداً';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [C.panelDark1, C.panelDark2, C.panelDark3],
            stops: [0.0, 0.5, 1.0],
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
                        child: SlideTransition(position: _slide, child: _buildCard()),
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

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 40, offset: const Offset(0, 12))],
      ),
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBrand(),
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 24),

          _sectionLabel("المعلومات الشخصية", FontAwesomeIcons.user),
          const SizedBox(height: 12),
          _buildField(label: "الاسم الكامل",         icon: FontAwesomeIcons.userPen,  ctrl: _nameCtrl,    hint: "محمد أحمد",         isPassword: false),
          const SizedBox(height: 14),
          _buildField(label: "البريد الإلكتروني",    icon: FontAwesomeIcons.envelope, ctrl: _emailCtrl,   hint: "user@example.com",  isPassword: false),
          const SizedBox(height: 14),
          _buildField(label: "كلمة المرور",          icon: FontAwesomeIcons.lock,     ctrl: _passCtrl,    hint: "••••••••",          isPassword: true,  showToggle: true, showValue: _showPass,    onToggle: () => setState(() => _showPass = !_showPass)),
          const SizedBox(height: 14),
          _buildField(label: "تأكيد كلمة المرور",   icon: FontAwesomeIcons.lockOpen,  ctrl: _confirmCtrl, hint: "••••••••",          isPassword: true,  showToggle: true, showValue: _showConfirm, onToggle: () => setState(() => _showConfirm = !_showConfirm)),
          const SizedBox(height: 22),

          _sectionLabel("معلومات السيارة", FontAwesomeIcons.car),
          const SizedBox(height: 12),
          _buildField(label: "رقم لوحة السيارة", icon: FontAwesomeIcons.idCard, ctrl: _plateCtrl, hint: "123 ABC", isPassword: false),
          const SizedBox(height: 14),
          _buildCarTypeDropdown(),

          if (_errorMsg != null) ...[
            const SizedBox(height: 14),
            _buildErrorBanner(_errorMsg!),
          ],

          const SizedBox(height: 24),
          _buildRegisterBtn(),
          const SizedBox(height: 16),
          _buildLoginLink(),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("SmartParking", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.dark)),
            Text("نظام الإدارة الذكي", style: TextStyle(fontSize: 11, color: C.muted)),
          ],
        ),
        const SizedBox(width: 12),
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.primary, C.secondary]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(FontAwesomeIcons.squareParking, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text("إنشاء حساب جديد",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: C.dark)),
        SizedBox(height: 5),
        Text("أدخل بياناتك للانضمام إلى المنصة",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: C.muted)),
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

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.dark)),
        const SizedBox(width: 8),
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [C.primary, C.secondary]),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 13, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label, required IconData icon,
    required TextEditingController ctrl, required String hint,
    required bool isPassword, bool showToggle = false,
    bool showValue = false, VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.dark)),
        const SizedBox(height: 7),
        TextField(
          controller: ctrl, obscureText: isPassword && !showValue,
          textAlign: TextAlign.right, textDirection: TextDirection.ltr,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: C.dark),
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            filled: true, fillColor: C.white,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.border, width: 1.5)),
            focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            prefixIcon: Icon(icon, size: 15, color: C.muted),
            suffixIcon: showToggle
                ? IconButton(icon: Icon(showValue ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash, size: 14, color: C.muted), onPressed: onToggle)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCarTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text("نوع السيارة", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.dark)),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: _selectedCarType, isExpanded: true,
          alignment: AlignmentDirectional.centerEnd,
          decoration: InputDecoration(
            filled: true, fillColor: C.white,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.border, width: 1.5)),
            focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            prefixIcon: const Icon(FontAwesomeIcons.carSide, size: 15, color: C.muted),
          ),
          hint: const Text("اختر نوع السيارة", textAlign: TextAlign.right, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          icon: const Icon(FontAwesomeIcons.chevronDown, size: 13, color: C.muted),
          dropdownColor: C.white,
          style: const TextStyle(fontSize: 14, color: C.dark, fontFamily: 'Tajawal'),
          items: _carTypes.map((type) => DropdownMenuItem<String>(
              value: type, alignment: AlignmentDirectional.centerEnd,
              child: Text(type, textAlign: TextAlign.right))).toList(),
          onChanged: (val) => setState(() => _selectedCarType = val),
        ),
      ],
    );
  }

  Widget _buildRegisterBtn() {
    return GestureDetector(
      onTap: _loading ? null : _handleRegister,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: _loading ? null : const LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [C.primary, C.secondary]),
          color: _loading ? C.border : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _loading ? [] : [BoxShadow(color: C.primary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading) ...[
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white))),
              const SizedBox(width: 10),
              const Text("جاري إنشاء الحساب...", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ] else ...[
              const Icon(FontAwesomeIcons.userPlus, color: Colors.white, size: 16),
              const SizedBox(width: 10),
              const Text("إنشاء الحساب", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text("تسجيل الدخول",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.primary,
                  decoration: TextDecoration.underline, decorationColor: C.primary)),
        ),
        const SizedBox(width: 5),
        const Text("لديك حساب بالفعل؟", style: TextStyle(fontSize: 13, color: C.muted)),
      ],
    );
  }
}
