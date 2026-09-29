import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../transport/canonical_user_id.dart';

Future<void> showAddContactSheet(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final nameController = TextEditingController();
  var errorText = '';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Добавить по коду',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Формат: 456 N 634. Это адрес собеседника с сервера.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Код',
                    errorText: errorText.isEmpty ? null : errorText,
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя (необязательно)',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final canonical = canonicalizeUserId(controller.text);
                    if (canonical == null) {
                      setState(() {
                        errorText = 'Нужен код вида 456 N 634';
                      });
                      return;
                    }
                    final directory = await ref.read(
                      contactDirectoryProvider.future,
                    );
                    await directory.add(
                      userId: canonical,
                      displayName: nameController.text.trim().isEmpty
                          ? null
                          : nameController.text.trim(),
                    );
                    ref.invalidate(contactDirectoryProvider);
                    ref.invalidate(chatListProvider);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Добавить'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  controller.dispose();
  nameController.dispose();
}
