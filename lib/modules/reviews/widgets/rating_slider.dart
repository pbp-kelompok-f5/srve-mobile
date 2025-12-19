import 'package:flutter/material.dart';

class RatingSlider extends StatelessWidget {
  final String label;
  final double value;
  final Function(double) onChanged;

  const RatingSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("${value.toInt()} / 5", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}