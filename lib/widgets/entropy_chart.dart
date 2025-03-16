import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EntropyChart extends StatelessWidget {
  final List<double> positionEntropy;
  final double maxPossibleEntropy;

  const EntropyChart({
    Key? key,
    required this.positionEntropy,
    required this.maxPossibleEntropy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Position Entropy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Higher values indicate more randomness (max: ${maxPossibleEntropy.toStringAsFixed(2)})',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxPossibleEntropy * 1.1, // Add 10% padding
              gridData: FlGridData(
                show: true,
                horizontalInterval: 1.0,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[300],
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              barGroups: List.generate(
                positionEntropy.length,
                    (index) => BarChartGroupData(
                  x: index + 1,
                  barRods: [
                    BarChartRodData(
                      toY: positionEntropy[index],
                      width: 22,
                      color: _getEntropyColor(positionEntropy[index]),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        angle: 0,
                        child: Text(
                          'Pos ${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 1.0,
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Color _getEntropyColor(double entropyValue) {
    // Color gradient from red (low entropy) to green (high entropy)
    final ratio = entropyValue / maxPossibleEntropy;

    if (ratio < 0.5) {
      // Red to yellow gradient for lower entropy
      return Color.lerp(
        Colors.red,
        Colors.amber,
        ratio * 2,
      ) ?? Colors.red;
    } else {
      // Yellow to green gradient for higher entropy
      return Color.lerp(
        Colors.amber,
        Colors.green,
        (ratio - 0.5) * 2,
      ) ?? Colors.green;
    }
  }
}