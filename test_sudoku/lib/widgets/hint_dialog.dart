import 'package:flutter/material.dart';

/// Smart hint dialog with visual highlighting
/// Shows "Last Remaining Cell" logic
class HintDialog extends StatefulWidget {
  final HintInfo hintInfo;
  final VoidCallback onConfirm;

  const HintDialog({
    super.key,
    required this.hintInfo,
    required this.onConfirm,
  });

  @override
  State<HintDialog> createState() => _HintDialogState();
}

class _HintDialogState extends State<HintDialog> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              locale == 'tr' ? 'Son Kalan Hücre' : 'Last Remaining Cell',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // PageView for hint steps
            SizedBox(
              height: 180,
              child: PageView(
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  // Step 1: Highlight area
                  _buildHintStep(
                    icon: Icons.grid_on,
                    color: Colors.blue,
                    title: locale == 'tr'
                        ? 'Bu hücrelere ve vurgulanan alanlara dikkat et'
                        : 'Focus on these cells and highlighted areas',
                  ),
                  // Step 2: Logic explanation
                  _buildHintStep(
                    icon: Icons.lightbulb_outline,
                    color: Colors.orange,
                    title: locale == 'tr'
                        ? 'Mümkün olan tek seçenek olduğundan bu hücre ${widget.hintInfo.correctValue} olmalı'
                        : 'This cell must be ${widget.hintInfo.correctValue} as it\'s the only possible option',
                  ),
                  // Step 3: Confirmation
                  _buildHintStep(
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    title: locale == 'tr'
                        ? 'Bu blokta 1 sayısını içerebilecek yalnızca bir hücre kaldı'
                        : 'Only one cell left that can contain ${widget.hintInfo.correctValue} in this block',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.blue
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _currentPage--);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: Text(locale == 'tr' ? 'Geri' : 'Back'),
                  )
                else
                  const SizedBox(width: 80),
                if (_currentPage < 2)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _currentPage++);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(locale == 'tr' ? 'İleri' : 'Next'),
                    iconAlignment: IconAlignment.end,
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(locale == 'tr' ? 'Bitti' : 'Done'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintStep({
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 48, color: color),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }
}

/// Hint information
class HintInfo {
  final int row;
  final int col;
  final int correctValue;
  final Set<int> highlightedCells; // Linear indices (row * 9 + col)
  final String reason;

  HintInfo({
    required this.row,
    required this.col,
    required this.correctValue,
    required this.highlightedCells,
    required this.reason,
  });
}
