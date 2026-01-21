import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dartboard_provider.dart';
import '../../providers/setup_wizard_provider.dart';
import '../../widgets/wizard_progress_indicator.dart';
import '../../widgets/custom_button.dart';

class RegisterBoardScreen extends StatefulWidget {
  const RegisterBoardScreen({super.key});

  @override
  State<RegisterBoardScreen> createState() => _RegisterBoardScreenState();
}

class _RegisterBoardScreenState extends State<RegisterBoardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serialController = TextEditingController();

  @override
  void dispose() {
    _serialController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final dartboardProvider = context.read<DartboardProvider>();
    final wizardProvider = context.read<SetupWizardProvider>();

    if (authProvider.bearerToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Authentication required. Please login first.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final success = await dartboardProvider.registerDartboard(
      authProvider.bearerToken!,
      _serialController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      await wizardProvider.completeSetup();
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dartboardProvider.error ?? 'Failed to register dartboard'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dartboardProvider = context.watch<DartboardProvider>();
    final wizardProvider = context.watch<SetupWizardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Dartboard'),
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
                  Icons.developer_board,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Register Your Dartboard',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter your dartboard\'s serial number to connect it to your account. You can only register one dartboard per account.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _serialController,
                  decoration: const InputDecoration(
                    labelText: 'Serial Number',
                    hintText: 'Enter dartboard serial number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the serial number';
                    }
                    if (value.trim().length < 4) {
                      return 'Serial number is too short';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.onTertiaryContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Where to find your serial number:',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Check the back of your Scolia dartboard\n'
                        '• Look for a sticker with a QR code\n'
                        '• The serial number is printed below the QR code',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Register Dartboard',
                  onPressed: dartboardProvider.isLoading ? null : _handleRegister,
                  isLoading: dartboardProvider.isLoading,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Back',
                  onPressed: dartboardProvider.isLoading
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
