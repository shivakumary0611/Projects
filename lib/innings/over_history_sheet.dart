import 'package:cric_snap/database/databaseHelper.dart';
import 'package:flutter/material.dart';

class DeliveryEvent {
  final String label;
  final Color color;
  final int overIndex;

  const DeliveryEvent({
    required this.label,
    required this.color,
    required this.overIndex,
  });

  factory DeliveryEvent.fromMap(Map<String, dynamic> map) {
    return DeliveryEvent(
      label: map['label'] as String? ?? '',
      color: Color(map['colorValue'] as int? ?? 0xFF475569),
      overIndex: map['overIndex'] as int? ?? 0,
    );
  }
}

Future<void> showOverHistorySheet({
  required BuildContext context,
  required String inningsId,
}) async {
  final rows = await DatabaseHelper.instance.getDeliveryEventsByInnings(
    inningsId,
  );
  if (!context.mounted) return;

  final grouped = <int, List<DeliveryEvent>>{};
  for (final row in rows) {
    final event = DeliveryEvent.fromMap(row);
    grouped.putIfAbsent(event.overIndex, () => []).add(event);
  }
  final overIndexes = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Over History',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Each row shows the result markers and total for that over.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: overIndexes.isEmpty
                      ? const Center(child: Text('No balls recorded yet.'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: overIndexes.length,
                          itemBuilder: (context, index) {
                            final overIndex = overIndexes[index];
                            final events = grouped[overIndex]!;
                            return _OverHistoryCard(
                              overIndex: overIndex,
                              events: events,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _OverHistoryCard extends StatelessWidget {
  final int overIndex;
  final List<DeliveryEvent> events;

  const _OverHistoryCard({
    required this.overIndex,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final score = _scoreForEvents(events);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Over ${overIndex + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  '$score runs',
                  style: const TextStyle(
                    color: Color(0xFFC2410C),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${events.length} result marker${events.length == 1 ? '' : 's'}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          DeliveryTrail(events: events),
        ],
      ),
    );
  }
}

class DeliveryTrail extends StatelessWidget {
  final List<DeliveryEvent> events;
  final bool dark;

  const DeliveryTrail({
    super.key,
    required this.events,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Row(
        children: List.generate(6, (index) {
          return Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dark ? Colors.white24 : const Color(0xFFE2E8F0),
            ),
          );
        }),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: events.map((event) {
        return Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: event.color,
            boxShadow: [
              BoxShadow(
                color: event.color.withValues(alpha: 0.24),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              event.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

int _scoreForEvents(List<DeliveryEvent> events) {
  var total = 0;
  for (final event in events) {
    final label = event.label;
    if (label.startsWith('+')) {
      total += int.tryParse(label.substring(1)) ?? 0;
      continue;
    }
    total += int.tryParse(label) ?? 0;
  }
  return total;
}
