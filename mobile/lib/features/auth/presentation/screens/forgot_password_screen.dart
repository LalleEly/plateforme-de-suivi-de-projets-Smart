import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool _codeSent = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = l10n.errorEmailRequired);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await ApiService.forgotPassword(email);
      setState(() {
        _codeSent = true;
        _info = l10n.infoCodeSent;
      });
    } catch (e) {
      setState(() => _error = l10n.errorSendCodeFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (code.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _error = l10n.errorFillAllFields);
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _error = l10n.errorPasswordTooShort);
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _error = l10n.errorPasswordMismatch);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await ApiService.resetPassword(code, newPassword);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = l10n.errorResetCodeInvalid);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(
        backgroundColor: context.colors.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.text1),
        title: Text(l10n.forgotPasswordAppBarTitle,
            style: TextStyle(color: context.colors.text1, fontSize: 16)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
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
                    _codeSent ? l10n.newPasswordStepTitle : l10n.resetPasswordStepTitle,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.colors.text1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _codeSent ? l10n.resetCodePrompt : l10n.resetEmailPrompt,
                    style: TextStyle(fontSize: 13, color: context.colors.text2),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    _buildBanner(_error!, context.colors.red),
                    const SizedBox(height: 14),
                  ],
                  if (_info != null && _error == null) ...[
                    _buildBanner(_info!, context.colors.accent),
                    const SizedBox(height: 14),
                  ],
                  if (!_codeSent) ..._buildEmailStep() else ..._buildResetStep(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmailStep() {
    final l10n = AppLocalizations.of(context)!;
    return [
      _field(l10n.fieldEmail, _emailCtrl, TextInputType.emailAddress),
      const SizedBox(height: 22),
      _buildSubmitButton(l10n.sendCodeButton, _sendCode),
    ];
  }

  List<Widget> _buildResetStep() {
    final l10n = AppLocalizations.of(context)!;
    return [
      _field(l10n.fieldResetCode, _codeCtrl, TextInputType.number),
      const SizedBox(height: 14),
      _fieldPassword(l10n.fieldNewPassword, _newPasswordCtrl),
      const SizedBox(height: 14),
      _fieldPassword(l10n.fieldConfirmPassword, _confirmPasswordCtrl),
      const SizedBox(height: 22),
      _buildSubmitButton(l10n.resetPasswordButton, _resetPassword),
      const SizedBox(height: 12),
      TextButton(
        onPressed: _loading
            ? null
            : () => setState(() {
                  _codeSent = false;
                  _error = null;
                  _info = null;
                }),
        child: Text(l10n.resendCodeLink,
            style: TextStyle(fontSize: 12, color: context.colors.text2)),
      ),
    ];
  }

  Widget _buildSubmitButton(String label, Future<void> Function() onSubmit) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(label),
      ),
    );
  }

  Widget _buildBanner(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(Icons.info_outline, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12, color: color)),
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

  Widget _fieldPassword(String label, TextEditingController ctrl) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: context.colors.text2)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
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
