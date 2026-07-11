import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _role = '';
  ThemeMode _theme = ThemeMode.dark;
  bool _saved = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _changingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Synchronise avec le theme reellement applique (persiste par ProjectFlowApp) :
    // sans ca, ce champ restait bloque sur ThemeMode.dark et affichait "Sombre"
    // comme actif meme quand Clair/Systeme etait la vraie preference active.
    final current = ProjectFlowApp.of(context)?.themeMode;
    if (current != null && current != _theme) {
      setState(() => _theme = current);
    }
  }

  Future<void> _loadUser() async {
    final name = await StorageService.getUserName();
    final email = await StorageService.getUserEmail();
    final role = await StorageService.getUserRole();
    final parts = (name ?? '').trim().split(' ');
    setState(() {
      _firstName = parts.isNotEmpty ? parts[0] : '';
      _lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _email = email ?? '';
      _role = role ?? 'MEMBRE';
      _firstNameCtrl.text = _firstName;
      _lastNameCtrl.text = _lastName;
      _emailCtrl.text = _email;
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newName = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();
    await StorageService.saveUser(
      token: (await StorageService.getToken()) ?? '',
      userId: (await StorageService.getUserId()) ?? 0,
      email: _email,
      fullName: newName,
      role: _role,
    );
    setState(() {
      _firstName = _firstNameCtrl.text.trim();
      _lastName = _lastNameCtrl.text.trim();
      _saved = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.settingsSavedSnack),
        ]),
        backgroundColor: context.colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  void _setTheme(ThemeMode mode) {
    setState(() => _theme = mode);
    ProjectFlowApp.of(context)?.setTheme(mode);
  }

  void _setLocale(Locale locale) {
    ProjectFlowApp.of(context)?.setLocale(locale);
  }

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context)!;
    final oldPwd = _oldPasswordCtrl.text.trim();
    final newPwd = _newPasswordCtrl.text.trim();

    if (oldPwd.isEmpty || newPwd.isEmpty) {
      _snack(l10n.errorFillAllFields, context.colors.red);
      return;
    }
    if (newPwd.length < 6) {
      _snack(l10n.errorPasswordTooShort, context.colors.red);
      return;
    }

    setState(() => _changingPassword = true);
    try {
      await ApiService.changePassword(oldPwd, newPwd);
      _snack(l10n.passwordUpdatedSuccess, context.colors.green);
      _oldPasswordCtrl.clear();
      _newPasswordCtrl.clear();
    } catch (e) {
      _snack(l10n.currentPasswordIncorrect, context.colors.red);
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'MANAGER': return context.colors.purple;
      case 'CHEF_PROJET': return context.colors.accent;
      default: return context.colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTopBar(),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(children: [
                _buildAccount(),
                const SizedBox(height: 12),
                _buildPassword(),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(children: [
                _buildAppearance(),
                const SizedBox(height: 12),
                _buildLanguage(),
                const SizedBox(height: 12),
                _buildSecurity(),
                const SizedBox(height: 12),
                _buildInfo(),
              ])),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildTopBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          border: Border(bottom: BorderSide(color: context.colors.border, width: 0.5))),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.settingsTitle,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.text1)),
          Text(l10n.settingsSubtitle,
              style: TextStyle(fontSize: 10, color: context.colors.text2)),
        ]),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _save,
          icon: Icon(_saved ? Icons.check : Icons.save_outlined, size: 14),
          label: Text(_saved ? l10n.savedButton : l10n.saveSettingsButton),
          style: ElevatedButton.styleFrom(
            backgroundColor: _saved ? context.colors.green : context.colors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          ),
        ),
      ]),
    );
  }

  Widget _buildAccount() {
    final l10n = AppLocalizations.of(context)!;
    return _card(l10n.myAccountSection, Column(children: [
      Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [context.colors.accent, const Color(0xFF4F46E5)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle),
          child: Center(child: Text(
              _firstName.isNotEmpty ? _firstName[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: Colors.white))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '$_firstName $_lastName'.trim().isEmpty ? 'Utilisateur' : '$_firstName $_lastName'.trim(),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.text1)),
          const SizedBox(height: 4),
          Text(_email,
              style: TextStyle(fontSize: 11, color: context.colors.text2)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _roleColor(_role).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _roleColor(_role).withOpacity(0.4))),
            child: Text(_role.replaceAll('_', ' '),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: _roleColor(_role))),
          ),
        ])),
      ]),
      const SizedBox(height: 14),
      Divider(color: context.colors.border),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _inputField(l10n.fieldFirstName, _firstNameCtrl)),
        const SizedBox(width: 10),
        Expanded(child: _inputField(l10n.fieldLastName, _lastNameCtrl)),
      ]),
      const SizedBox(height: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.emailNotEditable,
            style: TextStyle(fontSize: 11, color: context.colors.text2)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
              color: context.colors.bg4,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colors.border)),
          child: Text(_email,
              style: TextStyle(fontSize: 12, color: context.colors.text3)),
        ),
      ]),
      const SizedBox(height: 4),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.localOnlyNotice,
          style: TextStyle(fontSize: 9, color: context.colors.text3.withOpacity(0.7)),
        ),
      ),
    ]));
  }

  Widget _buildPassword() {
    final l10n = AppLocalizations.of(context)!;
    return _card(l10n.changePasswordSection, Column(children: [
      _inputField(l10n.fieldCurrentPassword, _oldPasswordCtrl, isPassword: true, obscure: _obscureOld,
          onToggle: () => setState(() => _obscureOld = !_obscureOld)),
      const SizedBox(height: 10),
      _inputField(l10n.fieldNewPassword, _newPasswordCtrl, isPassword: true, obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew)),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _changingPassword ? null : _changePassword,
          style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.bg3,
              foregroundColor: context.colors.text1,
              side: BorderSide(color: context.colors.border),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 12)),
          child: _changingPassword
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: context.colors.text1, strokeWidth: 2))
              : Text(l10n.updatePasswordButton),
        ),
      ),
    ]));
  }

  Widget _buildAppearance() {
    final l10n = AppLocalizations.of(context)!;
    return _card(l10n.appearanceSection, Column(children: [
      Text(l10n.themeLabel,
          style: TextStyle(fontSize: 11, color: context.colors.text2)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _themeOption(l10n.themeDark, ThemeMode.dark,
            const Color(0xFF0D1117), const Color(0xFF30363D))),
        const SizedBox(width: 8),
        Expanded(child: _themeOption(l10n.themeLight, ThemeMode.light,
            const Color(0xFFF6F8FA), const Color(0xFFD0D7DE))),
        const SizedBox(width: 8),
        Expanded(child: GestureDetector(
          onTap: () => _setTheme(ThemeMode.system),
          child: Column(children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _theme == ThemeMode.system
                          ? context.colors.accent : context.colors.border,
                      width: _theme == ThemeMode.system ? 2 : 1),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0D1117), Color(0xFFF6F8FA)],
                      stops: [0.5, 0.5])),
            ),
            const SizedBox(height: 6),
            Text(l10n.themeSystem,
                style: TextStyle(
                    fontSize: 11,
                    color: _theme == ThemeMode.system
                        ? context.colors.accentLight : context.colors.text2,
                    fontWeight: _theme == ThemeMode.system
                        ? FontWeight.w600 : FontWeight.normal)),
          ]),
        )),
      ]),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: context.colors.bg3,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.colors.border, width: 0.5)),
        child: Row(children: [
          Icon(Icons.info_outline, size: 14, color: context.colors.text2),
          const SizedBox(width: 8),
          Expanded(child: Text(
            l10n.themeAppliesNotice,
            style: TextStyle(fontSize: 10, color: context.colors.text2),
          )),
        ]),
      ),
    ]));
  }

  Widget _buildLanguage() {
    final l10n = AppLocalizations.of(context)!;
    final current = Localizations.localeOf(context).languageCode;
    return _card(l10n.languageSection, Column(children: [
      Text(l10n.languageLabel,
          style: TextStyle(fontSize: 11, color: context.colors.text2)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _languageOption(l10n.languageFrench, 'fr', current)),
        const SizedBox(width: 8),
        Expanded(child: _languageOption(l10n.languageArabic, 'ar', current)),
      ]),
    ]));
  }

  Widget _languageOption(String label, String code, String current) {
    final isActive = current == code;
    return GestureDetector(
      onTap: () => _setLocale(Locale(code)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: isActive ? context.colors.accent.withOpacity(0.12) : context.colors.bg3,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isActive ? context.colors.accent : context.colors.border,
                width: isActive ? 1.5 : 1)),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                color: isActive ? context.colors.accentLight : context.colors.text2,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _themeOption(String label, ThemeMode mode, Color bg, Color borderColor) {
    final isActive = _theme == mode;
    return GestureDetector(
      onTap: () => _setTheme(mode),
      child: Column(children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isActive ? context.colors.accent : borderColor,
                  width: isActive ? 2 : 1)),
          child: Center(child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 16, height: 3,
                  decoration: BoxDecoration(
                      color: mode == ThemeMode.dark
                          ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Container(width: 8, height: 3,
                  decoration: BoxDecoration(
                      color: mode == ThemeMode.dark
                          ? const Color(0xFF21262D) : const Color(0xFFE8EAED),
                      borderRadius: BorderRadius.circular(2))),
            ],
          )),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(
            fontSize: 11,
            color: isActive ? context.colors.accentLight : context.colors.text2,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ]),
    );
  }

  Widget _buildSecurity() {
    final l10n = AppLocalizations.of(context)!;
    return _card(l10n.securitySection, Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: context.colors.bg3,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.colors.border, width: 0.5)),
        child: Row(children: [
          Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: context.colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.verified_user_outlined,
                  color: context.colors.green, size: 16)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.accountSecure,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: context.colors.text1)),
              Text(l10n.jwtActive,
                  style: TextStyle(fontSize: 10, color: context.colors.text2)),
            ],
          )),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: context.colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(l10n.activeStatus,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                      color: context.colors.green))),
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: context.colors.bg2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: context.colors.border)),
                title: Text(l10n.logoutDialogTitle,
                    style: TextStyle(color: context.colors.text1)),
                content: Text(
                    l10n.logoutDialogContent,
                    style: TextStyle(color: context.colors.text2, fontSize: 13)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel,
                          style: TextStyle(color: context.colors.text2))),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.red),
                      child: Text(l10n.logoutButton)),
                ],
              ),
            );
            if (confirm == true && mounted) {
              await StorageService.logout();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            }
          },
          icon: const Icon(Icons.logout_rounded, size: 14),
          label: Text(l10n.logoutButton),
          style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.red,
              side: BorderSide(color: context.colors.red.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 12)),
        ),
      ),
    ]));
  }

  Widget _buildInfo() {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      l10n.comingSoonGoogle,
      l10n.comingSoonPushNotif,
      l10n.comingSoonEmailChange,
      l10n.comingSoonExport,
    ];
    return _card(l10n.comingSoonSection, Column(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: context.colors.amber.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.colors.amber.withOpacity(0.25))),
        child: Column(children: items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Icon(Icons.schedule_rounded, size: 12, color: context.colors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text(item,
                style: TextStyle(fontSize: 11, color: context.colors.text2))),
          ]),
        )).toList()),
      ),
    ]));
  }

  Widget _card(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: context.colors.text2, letterSpacing: 0.07)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController ctrl, {
    TextInputType type = TextInputType.text,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: context.colors.text2)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        keyboardType: type,
        obscureText: isPassword && obscure,
        style: TextStyle(fontSize: 12, color: context.colors.text1),
        decoration: InputDecoration(
          filled: true,
          fillColor: context.colors.bg3,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.colors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.colors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.colors.accent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 16, color: context.colors.text2),
                  onPressed: onToggle)
              : null,
        ),
      ),
    ]);
  }
}
