import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme_toggle.dart';

Future<void> copyUserId(BuildContext context, String userId) async {
  await Clipboard.setData(ClipboardData(text: userId));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Идентификатор скопирован')));
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key, required this.userId, required this.onContinue});

  final String userId;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Align(alignment: Alignment.topRight, child: ThemeToggle()),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.lock_outline, size: 40, color: scheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Ваш идентификатор',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Это идентификатор, который вы отправляете собеседнику. Идентификатор устройства — не адрес.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          child: SelectableText(
                            userId,
                            key: const Key('user-id-value'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        key: const Key('copy-user-id'),
                        onPressed: () => copyUserId(context, userId),
                        icon: const Icon(Icons.copy),
                        label: const Text('Скопировать'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        key: const Key('enter-chats'),
                        onPressed: onContinue,
                        child: const Text('К чатам'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

