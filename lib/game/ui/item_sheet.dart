import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/game_state.dart';
import '../spec/adventure_spec.dart';

/// Lets the child choose which item to use on a target.
class ItemSheet extends StatefulWidget {
  const ItemSheet({
    super.key,
    required this.title,
    required this.text,
    required this.items,
    required this.onUse,
  });

  final String title;
  final String text;
  final List<EntitySpec> items;
  final UseResult Function(String itemId) onUse;

  @override
  State<ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<ItemSheet> {
  static const violet = Color(0xFF7C3AED);
  static const deepViolet = Color(0xFF3B0764);

  String? _feedback;
  bool _correct = false;

  void _use(String itemId) {
    final result = widget.onUse(itemId);
    setState(() {
      _feedback = result.message;
      _correct = result.correct;
    });

    if (result.correct) {
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8CCF7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: deepViolet,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF665477)),
            ),
            const SizedBox(height: 14),
            const Text(
              'Which item will you use?',
              textAlign: TextAlign.center,
              style: TextStyle(color: deepViolet, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final item in widget.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: _correct ? null : () => _use(item.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: deepViolet,
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: violet, width: 2),
                  ),
                  child: Text(
                    '${item.icon.isNotEmpty ? item.icon : '🎒'}  ${item.name}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            if (_feedback != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _correct
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _feedback!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _correct
                        ? const Color(0xFF166534)
                        : const Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}