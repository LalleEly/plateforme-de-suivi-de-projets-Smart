import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = l10n.errorFillAllFields);
      return;
    }
    if (!_isLogin &&
        (_firstNameCtrl.text.isEmpty || _lastNameCtrl.text.isEmpty)) {
      setState(() => _error = l10n.errorFillAllFields);
      return;
    }
    if (!_isLogin && password.length < 6) {
      setState(() => _error = l10n.errorPasswordTooShort);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _isLogin
          ? await ApiService.login(email, password)
          : await ApiService.register(
              _firstNameCtrl.text.trim(),
              _lastNameCtrl.text.trim(),
              email,
              password,
            );

      await StorageService.saveUser(
        token: user.accessToken,
        userId: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.globalRole,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        // Une DioException sans reponse HTTP (timeout, DNS, CORS, reseau) n'a
        // rien a voir avec des identifiants invalides — l'afficher comme tel
        // evite d'induire l'utilisateur en erreur (ex. lors du reveil a froid
        // d'un backend sur offre gratuite, qui peut prendre 30-50s).
        if (e is DioException && e.response == null) {
          _error = 'Impossible de contacter le serveur. Il est peut-être en '
              'train de démarrer (offre gratuite) — réessayez dans '
              'quelques instants.';
        } else {
          _error = _isLogin ? l10n.errorLoginFailed : l10n.errorRegisterFailed;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: context.colors.bg2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLogin ? l10n.loginTitle : l10n.registerTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: context.colors.text1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLogin ? l10n.loginSubtitle : l10n.registerSubtitle,
                        style: TextStyle(
                            fontSize: 13, color: context.colors.text2),
                      ),
                      const SizedBox(height: 24),
                      _buildTabs(),
                      const SizedBox(height: 20),
                      if (_error != null) ...[
                        _buildError(),
                        const SizedBox(height: 14),
                      ],
                      if (!_isLogin) ...[
                        Row(children: [
                          Expanded(
                              child: _field(l10n.fieldFirstName, _firstNameCtrl,
                                  TextInputType.name)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _field(l10n.fieldLastName, _lastNameCtrl,
                                  TextInputType.name)),
                        ]),
                        const SizedBox(height: 14),
                      ],
                      _field(l10n.fieldEmail, _emailCtrl,
                          TextInputType.emailAddress),
                      const SizedBox(height: 14),
                      _fieldPassword(),
                      if (_isLogin) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _loading
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ForgotPasswordScreen()),
                                    ),
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap),
                            child: Text(l10n.forgotPasswordLink,
                                style: TextStyle(
                                    fontSize: 12, color: context.colors.accent)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.accent,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            textStyle: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(_isLogin
                                  ? l10n.loginButton
                                  : l10n.registerButton),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.restrictedAccessNotice,
                  style: TextStyle(fontSize: 11, color: context.colors.text2),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final l10n = AppLocalizations.of(context)!;
    return Column(children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.colors.accent, const Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.analytics_rounded,
            color: Colors.white, size: 28),
      ),
      const SizedBox(height: 12),
      Text(l10n.appTitle,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.colors.text1)),
      const SizedBox(height: 4),
      Text(l10n.appTagline,
          style: TextStyle(fontSize: 12, color: context.colors.text2)),
    ]);
  }

  Widget _buildTabs() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.bg3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colors.border),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(children: [
        _tab(l10n.tabLogin, true),
        _tab(l10n.tabRegister, false),
      ]),
    );
  }

  Widget _tab(String label, bool isLoginTab) {
    final isActive = (_isLogin == isLoginTab);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _isLogin = isLoginTab;
          _error = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? context.colors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : context.colors.text2,
              )),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.red.withOpacity(0.1),
        border: Border.all(color: context.colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, color: context.colors.red, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(_error!,
              style: TextStyle(fontSize: 12, color: context.colors.red)),
        ),
      ]),
    );
  }

  Widget _field(
      String label, TextEditingController ctrl, TextInputType type) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(fontSize: 11, color: context.colors.text2)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: TextStyle(fontSize: 13, color: context.colors.text1),
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
              borderSide:
                  BorderSide(color: context.colors.accent, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        ),
      ),
    ]);
  }

  Widget _fieldPassword() {
    final l10n = AppLocalizations.of(context)!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.fieldPassword,
          style: TextStyle(fontSize: 11, color: context.colors.text2)),
      const SizedBox(height: 5),
      TextField(
        controller: _passwordCtrl,
        obscureText: _obscure,
        style: TextStyle(fontSize: 13, color: context.colors.text1),
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
              borderSide:
                  BorderSide(color: context.colors.accent, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: context.colors.text2,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
    ]);
  }
}