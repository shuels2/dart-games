import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/setup_wizard_provider.dart';
import '../../widgets/wizard_progress_indicator.dart';
import '../../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _obscureToken = true;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final wizardProvider = context.read<SetupWizardProvider>();

    final success = await authProvider.setToken(_tokenController.text.trim());

    if (!mounted) return;

    if (success) {
      wizardProvider.nextStep();
      Navigator.of(context).pushReplacementNamed('/register-board');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Invalid bearer token'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final wizardProvider = context.watch<SetupWizardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to Scolia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            wizardProvider.previousStep();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WizardProgressIndicator(
                  currentStep: wizardProvider.currentStep,
                  totalSteps: wizardProvider.totalSteps,
                  stepLabels: const ['Welcome', 'Login', 'Register Board'],
                ),
                const SizedBox(height: 48),
                Icon(
                  Icons.login,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Connect Your Scolia Account',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter your Scolia bearer token to connect your account. You can find this token in your Scolia account settings.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    labelText: 'Bearer Token',
                    hintText: 'Paste your bearer token here',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureToken ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureToken = !_obscureToken;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureToken,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your bearer token';
                    }
                    return null;
                  },
                  maxLines: 1,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your token is stored securely and never shared.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Continue',
                  onPressed: authProvider.isLoading ? null : _handleLogin,
                  isLoading: authProvider.isLoading,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Back',
                  onPressed: authProvider.isLoading
                      ? null
                      : () {
                          wizardProvider.previousStep();
                          Navigator.of(context).pop();
                        },
                  isOutlined: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
