import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dartboard_provider.dart';

class DartboardSetupScreen extends StatefulWidget {
  const DartboardSetupScreen({super.key});

  @override
  State<DartboardSetupScreen> createState() => _DartboardSetupScreenState();
}

class _DartboardSetupScreenState extends State<DartboardSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _serialController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _isConnecting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _connectDartboard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    final dartboardProvider = context.read<DartboardProvider>();

    final success = await dartboardProvider.connectToScolia(
      name: _nameController.text.trim(),
      serialNumber: _serialController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Connection successful, navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Connection failed, show error and offer emulator
      setState(() {
        _isConnecting = false;
        _errorMessage = dartboardProvider.error ?? 'Failed to connect to Scolia service';
      });

      _showEmulatorDialog();
    }
  }

  void _showEmulatorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_errorMessage ?? 'Unable to connect to the Scolia dartboard service.'),
            const SizedBox(height: 16),
            const Text('Would you like to use the dartboard emulator instead?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _useEmulator();
            },
            child: const Text('Use Emulator'),
          ),
        ],
      ),
    );
  }

  void _useEmulator() {
    final dartboardProvider = context.read<DartboardProvider>();
    dartboardProvider.useEmulator(
      name: _nameController.text.trim().isEmpty
          ? 'Dartboard Emulator'
          : _nameController.text.trim(),
      serialNumber: _serialController.text.trim().isEmpty
          ? 'EMU-001'
          : _serialController.text.trim(),
    );

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 12),
            const Text('Dartboard Setup'),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Column(
        children: [
          Image.asset(
            'assets/images/connect_dartboard_icon.png',
            width: double.infinity,
            height: 540,
            fit: BoxFit.cover,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  Text(
                    'Connect Your Dartboard',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Enter your Scolia dartboard details to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Dartboard Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Dartboard Name',
                      hintText: 'My Dartboard',
                      prefixIcon: Icon(Icons.label),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a dartboard name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Serial Number
                  TextFormField(
                    controller: _serialController,
                    decoration: const InputDecoration(
                      labelText: 'Scolia Dartboard Serial Number',
                      hintText: 'ABC-123-XYZ',
                      prefixIcon: Icon(Icons.pin),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the serial number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // API Key
                  TextFormField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Scolia API Key',
                      hintText: 'Your API key',
                      prefixIcon: Icon(Icons.key),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your API key';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Connect Button (hidden when error is shown)
                  if (_errorMessage == null)
                    ElevatedButton(
                      onPressed: _isConnecting ? null : _connectDartboard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isConnecting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Connect Dartboard',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
