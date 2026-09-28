import 'package:flutter/material.dart';

import '../session/notices.dart';

class InboundBanner extends StatelessWidget {
  const InboundBanner({
    super.key,
    required this.notice,
    required this.onOpen,
    required this.onDismiss,
  });

  final InboundNotice notice;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        key: const Key('inbound-banner'),
        color: const Color(0xFFFFFCF7),
        elevation: 1,
        shadowColor: const Color(0x331B3A31),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                const Icon(Icons.notifications_none, color: Color(0xFF1B3A31)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.senderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Text('Новое сообщение'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Скрыть',
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
