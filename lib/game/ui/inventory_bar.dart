import 'package:flutter/material.dart';

import '../engine/game_state.dart';
import '../spec/adventure_spec.dart';

/// Evidence found so far, plus the items the player is carrying.
class InventoryBar extends StatelessWidget {
  const InventoryBar({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final chips = <Widget>[];

        for (final e in state.spec.allEntities) {
          if (e.type == EntityType.evidence) {
            if (state.evidence.contains(e.id)) {
              chips.add(_chip(
                '${e.icon.isNotEmpty ? e.icon : '🔍'} ${e.name}',
                bg: const Color(0xFFFEF3C7),
                border: const Color(0xFFF59E0B),
                onTap: () => _show(context, e),
              ));
            } else if (state.spec.stageIndexOf(e.id) == state.stageIndex &&
                state.isVisible(e)) {
              chips.add(_chip(
                '?',
                bg: const Color(0xFFEDE9FE),
                border: const Color(0xFFD8CCF7),
              ));
            }
          } else if (e.type == EntityType.item &&
              state.inventory.contains(e.id)) {
            chips.add(_chip(
              '${e.icon.isNotEmpty ? e.icon : '🎒'} ${e.name}',
              bg: const Color(0xFFCCFBF1),
              border: const Color(0xFF14B8A6),
              onTap: () => _show(context, e),
            ));
          }
        }

        if (chips.isEmpty) {
          return const SizedBox(
            height: 44,
            child: Center(
              child: Text(
                'Clues and items you find will appear here',
                style: TextStyle(color: Color(0xFF7C6A99), fontSize: 12),
              ),
            ),
          );
        }

        return SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => chips[i],
          ),
        );
      },
    );
  }

  Widget _chip(
    String label, {
    required Color bg,
    required Color border,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 2),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF3B0764),
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _show(BuildContext context, EntitySpec item) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.name),
        content: Text(item.text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}