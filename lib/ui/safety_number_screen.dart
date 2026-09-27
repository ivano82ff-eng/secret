import 'package:flutter/material.dart';

class SafetyNumberScreen extends StatelessWidget {
  const SafetyNumberScreen({super.key, required this.peerName});

  final String peerName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Число безопасности')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Text(
            peerName,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Text(
            'Сверки пока нет',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'Пока клиент не считает число безопасности по сессии Signal, '
            'сервер может подменить prekey и встать посередине. '
            'Этот экран — заглушка: он не блокирует переписку. '
            'Сверяйте число лично, когда появится libsignal.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('— — —   — — —   — — —'),
            ),
          ),
        ],
      ),
    );
  }
}
