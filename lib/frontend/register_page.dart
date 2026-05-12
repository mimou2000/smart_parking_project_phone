import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';
import 'home_shell.dart';
import '../backend/firebase_service.dart';
import '../backend/app_locale.dart';

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

  String? _selectedBrand;
  String? _selectedModel;
  VehicleType _vehicleType = VehicleType.standard;

  // ════════════════════════════════════════════
  //  قاعدة بيانات السيارات العالمية
  // ════════════════════════════════════════════
  static const Map<String, List<String>> _carDatabase = {
    'Toyota': [
      'Corolla', 'Camry', 'Yaris', 'RAV4', 'Land Cruiser', 'Land Cruiser Prado',
      'Fortuner', 'Hilux', 'Innova', 'Avanza', 'Rush', 'Prius', 'C-HR',
      'Vitz', 'Auris', 'Sienna', 'Sequoia', 'Tundra', 'Tacoma', 'FJ Cruiser',
      'GR86', 'GR Yaris', 'GR Supra', 'Venza', 'Harrier', 'Alphard', 'Velfire',
      'Crown', 'Mark X', 'Verso', 'Aygo', 'Proace', 'HiAce', 'Land Cruiser 70',
    ],
    'Mercedes-Benz': [
      'A-Class', 'B-Class', 'C-Class', 'E-Class', 'S-Class', 'CLA', 'CLS',
      'GLA', 'GLB', 'GLC', 'GLE', 'GLS', 'G-Class', 'AMG GT', 'AMG C63',
      'AMG E63', 'AMG S63', 'AMG A45', 'AMG CLA45', 'AMG GLC63', 'AMG GLE63',
      'EQA', 'EQB', 'EQC', 'EQE', 'EQS', 'Maybach S-Class', 'Maybach GLS',
      'Sprinter', 'Vito', 'Viano', 'X-Class',
    ],
    'BMW': [
      '1 Series', '2 Series', '3 Series', '4 Series', '5 Series', '6 Series',
      '7 Series', '8 Series', 'X1', 'X2', 'X3', 'X4', 'X5', 'X6', 'X7',
      'M2', 'M3', 'M4', 'M5', 'M8', 'M135i', 'M240i', 'M340i', 'M550i',
      'iX1', 'iX3', 'iX', 'i4', 'i5', 'i7', 'Z4', 'XM',
    ],
    'Audi': [
      'A1', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'Q2', 'Q3', 'Q5', 'Q7', 'Q8',
      'TT', 'TTS', 'TTRS', 'R8', 'RS3', 'RS4', 'RS5', 'RS6', 'RS7',
      'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'SQ5', 'SQ7', 'SQ8',
      'e-tron', 'e-tron GT', 'Q4 e-tron', 'Q8 e-tron',
    ],
    'Honda': [
      'Civic', 'City', 'Accord', 'Jazz', 'Fit', 'HR-V', 'CR-V', 'Pilot',
      'Passport', 'Ridgeline', 'Odyssey', 'BR-V', 'WR-V', 'ZR-V',
      'Civic Type R', 'Integra', 'NSX',
    ],
    'Hyundai': [
      'Accent', 'Elantra', 'Sonata', 'Azera', 'i10', 'i20', 'i30',
      'Creta', 'Venue', 'Tucson', 'Santa Fe', 'Palisade', 'Staria',
      'H-1', 'Starex', 'Kona', 'Bayon', 'Veloster', 'i30 N',
      'IONIQ 5', 'IONIQ 6', 'NEXO',
    ],
    'Kia': [
      'Picanto', 'Rio', 'Cerato', 'Optima', 'K5', 'Stinger', 'Carnival', 'Sedona',
      'Stonic', 'Seltos', 'Sportage', 'Sorento', 'Telluride', 'Mohave',
      'Soul', 'Niro', 'EV6', 'EV9', 'K8',
    ],
    'Nissan': [
      'Micra', 'Sunny', 'Sentra', 'Altima', 'Maxima', 'Juke', 'Qashqai',
      'X-Trail', 'Rogue', 'Murano', 'Pathfinder', 'Armada', 'Patrol',
      'Navara', 'Frontier', 'GT-R', '370Z', '400Z', 'Leaf', 'Ariya', 'Note', 'Kicks',
    ],
    'Volkswagen': [
      'Polo', 'Golf', 'Golf GTI', 'Golf R', 'Jetta', 'Passat', 'Arteon',
      'T-Cross', 'T-Roc', 'Tiguan', 'Touareg', 'ID.3', 'ID.4', 'ID.5',
      'ID.6', 'ID.7', 'Caddy', 'Transporter', 'Crafter', 'Up', 'Scirocco', 'Touran',
    ],
    'Ford': [
      'Fiesta', 'Focus', 'Fusion', 'Mondeo', 'Mustang', 'Mustang Mach-E',
      'EcoSport', 'Escape', 'Edge', 'Explorer', 'Expedition', 'Ranger',
      'F-150', 'F-250', 'F-350', 'Bronco', 'Transit', 'Transit Connect',
      'Galaxy', 'S-Max', 'Puma', 'Kuga', 'Maverick',
    ],
    'Chevrolet': [
      'Spark', 'Sonic', 'Cruze', 'Malibu', 'Impala', 'Camaro', 'Corvette',
      'Trax', 'Equinox', 'Blazer', 'Traverse', 'Tahoe', 'Suburban',
      'Colorado', 'Silverado', 'Captiva', 'Trailblazer',
    ],
    'Renault': [
      'Clio', 'Sandero', 'Logan', 'Symbol', 'Megane', 'Talisman', 'Laguna',
      'Zoe', 'Arkana', 'Captur', 'Kadjar', 'Duster', 'Koleos', 'Espace',
      'Kangoo', 'Trafic', 'Master', 'Megane RS', 'Alpine A110',
    ],
    'Peugeot': [
      '107', '108', '208', '308', '408','406', '508', '2008', '3008', '5008',
      'Partner', 'Traveller', 'Expert', 'Boxer', 'Rifter', 'e-208', 'e-2008',
    ],
    'Dacia': [
      'Logan', 'Sandero', 'Duster', 'Jogger', 'Spring', 'Dokker', 'Lodgy',
    ],
    'Mitsubishi': [
      'Mirage', 'Attrage', 'Lancer', 'Galant', 'Eclipse Cross', 'ASX',
      'Outlander', 'Pajero', 'Pajero Sport', 'L200', 'Triton', 'Delica',
    ],
    'Mazda': [
      'Mazda2', 'Mazda3', 'Mazda6', 'MX-5 Miata', 'MX-30',
      'CX-3', 'CX-30', 'CX-5', 'CX-60', 'CX-80', 'CX-9', 'BT-50',
    ],
    'Subaru': [
      'Impreza', 'WRX', 'WRX STI', 'Legacy', 'Outback', 'Forester',
      'XV', 'Crosstrek', 'Ascent', 'BRZ', 'Levorg',
    ],
    'Lexus': [
      'IS', 'ES', 'GS', 'LS', 'RC', 'LC', 'UX', 'NX', 'RX', 'GX', 'LX',
      'RC F', 'GS F', 'IS 500',
    ],
    'Porsche': [
      '911 Carrera', '911 Turbo', '911 GT3', '911 GT3 RS',
      'Boxster', 'Cayman', '718', 'Panamera', 'Macan', 'Cayenne', 'Taycan',
    ],
    'Ferrari': [
      '296 GTB', '296 GTS', 'Roma', 'Roma Spider', 'Portofino',
      'SF90 Stradale', '812 Superfast', '812 GTS', 'F8 Tributo', 'F8 Spider', 'Purosangue',
    ],
    'Lamborghini': [
      'Huracan', 'Huracan EVO', 'Huracan Sterrato', 'Urus', 'Revuelto', 'Sian',
    ],
    'Maserati': [
      'Ghibli', 'Quattroporte', 'GranTurismo', 'GranCabrio', 'Levante', 'Grecale', 'MC20',
    ],
    'Alfa Romeo': [
      'Giulia', 'Stelvio', 'Tonale', '4C', 'GTV', 'Spider', 'Brera',
    ],
    'Fiat': [
      '500', '500X', '500L', 'Punto', 'Tipo', 'Bravo', 'Doblo', 'Ducato', 'Freemont',
    ],
    'Jeep': [
      'Renegade', 'Compass', 'Cherokee', 'Grand Cherokee',
      'Wrangler', 'Gladiator', 'Wagoneer', 'Grand Wagoneer',
    ],
    'Land Rover': [
      'Defender', 'Discovery', 'Discovery Sport', 'Freelander',
      'Range Rover', 'Range Rover Sport', 'Range Rover Velar', 'Range Rover Evoque',
    ],
    'Volvo': [
      'S60', 'S90', 'V60', 'V90', 'C40', 'XC40', 'XC60', 'XC90', 'EX30', 'EX90',
    ],
    'Tesla': [
      'Model S', 'Model 3', 'Model X', 'Model Y', 'Cybertruck', 'Roadster',
    ],
    'Infiniti': [
      'Q50', 'Q60', 'Q70', 'QX30', 'QX50', 'QX55', 'QX60', 'QX80',
    ],
    'Acura': [
      'ILX', 'TLX', 'RLX', 'RDX', 'MDX', 'ZDX', 'NSX',
    ],
    'Cadillac': [
      'CT4', 'CT5', 'XT4', 'XT5', 'XT6', 'Escalade', 'Lyriq',
    ],
    'Dodge': [
      'Challenger', 'Charger', 'Durango', 'Journey', 'Dart', 'Viper',
    ],
    'RAM': ['1500', '2500', '3500', 'ProMaster'],
    'Chrysler': ['Pacifica', '300', 'Voyager'],
    'Lincoln': ['Corsair', 'Nautilus', 'Aviator', 'Navigator'],
    'Buick': ['Encore', 'Encore GX', 'Envision', 'Enclave'],
    'GMC': ['Terrain', 'Acadia', 'Yukon', 'Sierra', 'Canyon'],
    'SEAT': ['Ibiza', 'Leon', 'Arona', 'Ateca', 'Tarraco', 'Mii', 'Alhambra'],
    'Skoda': ['Fabia', 'Scala', 'Octavia', 'Superb', 'Kamiq', 'Karoq', 'Kodiaq', 'Enyaq'],
    'Opel': ['Corsa', 'Astra', 'Insignia', 'Mokka', 'Crossland', 'Grandland', 'Zafira', 'Vivaro', 'Combo'],
    'Citroen': ['C1', 'C3', 'C4', 'C5 Aircross', 'Berlingo', 'SpaceTourer', 'C3 Aircross'],
    'Suzuki': ['Alto', 'Swift', 'Baleno', 'Ciaz', 'Vitara', 'S-Cross', 'Jimny', 'Ertiga', 'Celerio'],
    'Isuzu': ['D-Max', 'MU-X', 'Trooper', 'Rodeo', 'Forward'],
    'Chery': ['Tiggo 4', 'Tiggo 7', 'Tiggo 8', 'Arrizo 5', 'Arrizo 6', 'Omoda 5'],
    'MG': ['MG3', 'MG5', 'MG6', 'ZS', 'HS', 'RX5', 'Marvel R'],
    'Geely': ['Emgrand', 'Atlas', 'Coolray', 'Tugella', 'Azkarra'],
    'BYD': ['Atto 3', 'Han', 'Tang', 'Song', 'Seal', 'Dolphin', 'Atto 2'],
    'Haval': ['H2', 'H6', 'Jolion', 'Dargo', 'F7'],
    'JAC': ['J4', 'J7', 'S3', 'S4', 'S7', 'T8'],
    'Bentley': ['Continental GT', 'Flying Spur', 'Bentayga', 'Mulsanne'],
    'Rolls-Royce': ['Ghost', 'Phantom', 'Wraith', 'Dawn', 'Cullinan', 'Spectre'],
    'Aston Martin': ['Vantage', 'DB11', 'DBS', 'DBX', 'Valkyrie'],
    'McLaren': ['570S', '600LT', '720S', '765LT', 'Artura', 'GT', 'P1'],
    'Genesis': ['G70', 'G80', 'G90', 'GV70', 'GV80'],
    'Rivian': ['R1T', 'R1S'],
    'Lucid': ['Air', 'Gravity'],
    'Polestar': ['Polestar 2', 'Polestar 3', 'Polestar 4'],
  };

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

    if ([name, email, pass, confirm, plate].any((s) => s.isEmpty) ||
        _selectedBrand == null || _selectedModel == null) {
      setState(() => _errorMsg = tr('err_fill_all'));
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMsg = tr('err_passwords_no_match'));
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorMsg = tr('err_password_short'));
      return;
    }

    setState(() { _loading = true; _errorMsg = null; });
    try {
      await FirebaseService.register(
        email:       email,
        password:    pass,
        name:        name,
        plate:       plate,
        carType:     _selectedBrand!,
        carModel:    _selectedModel!,
        vehicleType: _vehicleType,
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
    if (e.contains('email-already-in-use')) return tr('err_email_in_use');
    if (e.contains('invalid-email'))        return tr('err_invalid_email');
    if (e.contains('weak-password'))        return tr('err_weak_password');
    if (e.contains('network'))              return tr('err_network');
    return tr('err_generic');
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
      resizeToAvoidBottomInset: true,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(position: _slide, child: _buildCard()),
            ),
          ),
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

          _sectionLabel(tr('personal_info'), FontAwesomeIcons.user),
          const SizedBox(height: 12),
          _buildField(label: tr('full_name'),       icon: FontAwesomeIcons.userPen,  ctrl: _nameCtrl,    hint: tr('name_hint'),    isPassword: false),
          const SizedBox(height: 14),
          _buildField(label: tr('email'),  icon: FontAwesomeIcons.envelope, ctrl: _emailCtrl,   hint: "user@example.com", isPassword: false),
          const SizedBox(height: 14),
          _buildField(label: tr('password'),        icon: FontAwesomeIcons.lock,     ctrl: _passCtrl,    hint: "••••••••",         isPassword: true,  showToggle: true, showValue: _showPass,    onToggle: () => setState(() => _showPass = !_showPass)),
          const SizedBox(height: 14),
          _buildField(label: tr('confirm_password'), icon: FontAwesomeIcons.lockOpen, ctrl: _confirmCtrl, hint: "••••••••",         isPassword: true,  showToggle: true, showValue: _showConfirm, onToggle: () => setState(() => _showConfirm = !_showConfirm)),
          const SizedBox(height: 22),

          _sectionLabel(tr('vehicle_info'), FontAwesomeIcons.car),
          const SizedBox(height: 12),
          _buildField(label: tr('plate_number'), icon: FontAwesomeIcons.idCard, ctrl: _plateCtrl, hint: tr('plate_hint'), isPassword: false),
          const SizedBox(height: 14),
          _buildVehicleTypeSelector(),
          const SizedBox(height: 14),
          _buildCarSection(),

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

  // ════════════════════════════════════════════
  //  قسم الماركة والطراز — Autocomplete مدمج
  // ════════════════════════════════════════════
  Widget _buildCarSection() {
    final allBrands = _carDatabase.keys.toList();
    final models    = _selectedBrand != null ? (_carDatabase[_selectedBrand!] ?? <String>[]) : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── ماركة السيارة ──
        Text(tr('car_brand'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.dark)),
        const SizedBox(height: 7),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) return allBrands;
            return allBrands.where(
                  (b) => b.toLowerCase().contains(textEditingValue.text.toLowerCase()),
            );
          },
          onSelected: (String brand) {
            setState(() {
              _selectedBrand = brand;
              _selectedModel = null;
            });
          },
          fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
            return TextField(
              controller: ctrl,
              focusNode: focusNode,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, color: C.dark),
              onChanged: (val) {
                // إذا غيّر المستخدم النص بعد الاختيار، أعد تعيين الماركة
                if (_selectedBrand != null && val != _selectedBrand) {
                  setState(() {
                    _selectedBrand = null;
                    _selectedModel = null;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: tr('car_brand_hint'),
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: C.white,
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: C.border, width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: C.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                prefixIcon: const Icon(FontAwesomeIcons.carSide, size: 15, color: C.muted),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220, maxWidth: double.infinity),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          child: Text(option,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 14, color: C.dark)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 14),

        // ── طراز السيارة ──
        Text(tr('car_model'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.dark)),
        const SizedBox(height: 7),

        if (_selectedBrand == null)
        // حقل معطّل حتى يتم اختيار الماركة
          TextField(
            enabled: false,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: tr('choose_brand_first'),
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: C.border, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              prefixIcon: const Icon(FontAwesomeIcons.tags, size: 14, color: C.muted),
            ),
          )
        else
          Autocomplete<String>(
            key: ValueKey(_selectedBrand), // إعادة بناء عند تغيير الماركة
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return models;
              return models.where(
                    (m) => m.toLowerCase().contains(textEditingValue.text.toLowerCase()),
              );
            },
            onSelected: (String model) {
              setState(() => _selectedModel = model);
            },
            fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
              return TextField(
                controller: ctrl,
                focusNode: focusNode,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14, color: C.dark),
                onChanged: (val) {
                  if (_selectedModel != null && val != _selectedModel) {
                    setState(() => _selectedModel = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: tr('search_model_hint'),
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  filled: true,
                  fillColor: C.white,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: C.border, width: 1.5)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: C.primary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  prefixIcon: const Icon(FontAwesomeIcons.tags, size: 14, color: C.muted),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220, maxWidth: double.infinity),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            child: Text(option,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 14, color: C.dark)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

        // ── بادج تأكيد الاختيار ──
        if (_selectedBrand != null && _selectedModel != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: C.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: C.primary.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$_selectedBrand  •  $_selectedModel',
                  style: const TextStyle(
                      fontSize: 13, color: C.primary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                const Icon(FontAwesomeIcons.circleCheck, size: 13, color: C.primary),
              ],
            ),
          ),
        ],
      ],
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
                colors: [C.primary, C.secondary]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: C.primary.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: const Icon(FontAwesomeIcons.squareParking, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 12),
        const Text("SmartParking",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.dark)),
        const SizedBox(height: 3),
        Text(tr('app_subtitle'),
            style: const TextStyle(fontSize: 12, color: C.muted)),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(tr('register_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: C.dark)),
        const SizedBox(height: 5),
        Text(tr('register_subtitle'),
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
                style: const TextStyle(
                    fontSize: 12, color: C.error, fontWeight: FontWeight.w700)),
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
        Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: C.dark)),
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
    required String label,
    required IconData icon,
    required TextEditingController ctrl,
    required String hint,
    required bool isPassword,
    bool showToggle = false,
    bool showValue = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: C.dark)),
        const SizedBox(height: 7),
        TextField(
          controller: ctrl,
          obscureText: isPassword && !showValue,
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: C.dark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: C.white,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: C.border, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: C.primary, width: 1.5)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            prefixIcon: Icon(icon, size: 15, color: C.muted),
            suffixIcon: showToggle
                ? IconButton(
                icon: Icon(
                    showValue
                        ? FontAwesomeIcons.eye
                        : FontAwesomeIcons.eyeSlash,
                    size: 14,
                    color: C.muted),
                onPressed: onToggle)
                : null,
          ),
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
          gradient: _loading
              ? null
              : const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [C.primary, C.secondary]),
          color: _loading ? C.border : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _loading
              ? []
              : [
            BoxShadow(
                color: C.primary.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5))
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
                      valueColor:
                      AlwaysStoppedAnimation(Colors.white))),
              const SizedBox(width: 10),
              Text(tr('creating_account'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ] else ...[
              const Icon(FontAwesomeIcons.userPlus,
                  color: Colors.white, size: 16),
              const SizedBox(width: 10),
              Text(tr('create_account_btn'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
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
          child: Text(tr('login_link'),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: C.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: C.primary)),
        ),
        const SizedBox(width: 5),
        Text(tr('has_account'),
            style: const TextStyle(fontSize: 13, color: C.muted)),
      ],
    );
  }

  // ════════════════════════════════════════════
  //  اختيار نوع المركبة
  // ════════════════════════════════════════════
  Widget _buildVehicleTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(tr('vehicle_type_label'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.dark)),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: VehicleType.values.map((type) {
            final bool selected = _vehicleType == type;
            return GestureDetector(
              onTap: () => setState(() => _vehicleType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(colors: [C.primary, C.secondary])
                      : null,
                  color: selected ? null : C.light,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? Colors.transparent : C.border,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _vehicleTypeLabel(type),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? C.white : C.muted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _vehicleTypeIcon(type),
                      size: 14,
                      color: selected ? C.white : _vehicleTypeColor(type),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _vehicleTypeLabel(VehicleType type) {
    switch (type) {
      case VehicleType.standard:   return tr('vehicle_standard');
      case VehicleType.vip:        return tr('vehicle_vip');
      case VehicleType.motorcycle: return tr('vehicle_motorcycle');
      case VehicleType.electric:   return tr('vehicle_electric');
      case VehicleType.disabled:   return tr('vehicle_disabled');
    }
  }

  IconData _vehicleTypeIcon(VehicleType type) {
    switch (type) {
      case VehicleType.standard:   return FontAwesomeIcons.car;
      case VehicleType.vip:        return FontAwesomeIcons.crown;
      case VehicleType.motorcycle: return FontAwesomeIcons.motorcycle;
      case VehicleType.electric:   return FontAwesomeIcons.bolt;
      case VehicleType.disabled:   return FontAwesomeIcons.wheelchair;
    }
  }

  Color _vehicleTypeColor(VehicleType type) {
    switch (type) {
      case VehicleType.standard:   return C.muted;
      case VehicleType.vip:        return Colors.amber.shade700;
      case VehicleType.motorcycle: return Colors.orange;
      case VehicleType.electric:   return Colors.green;
      case VehicleType.disabled:   return Colors.blue;
    }
  }
}
