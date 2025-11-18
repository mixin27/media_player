import 'package:flutter/material.dart';

class SpeedSelector extends StatelessWidget {
  final double currentSpeed;
  final List<double> availableSpeeds;
  final Function(double) onSpeedChanged;

  const SpeedSelector({
    super.key,
    required this.currentSpeed,
    required this.availableSpeeds,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      itemBuilder: (context) => availableSpeeds.map((speed) {
        return PopupMenuItem<double>(
          value: speed,
          child: Row(
            children: [
              Text('${speed}x'),
              const Spacer(),
              if (speed == currentSpeed) const Icon(Icons.check, size: 20),
            ],
          ),
        );
      }).toList(),
      onSelected: onSpeedChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${currentSpeed}x',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
