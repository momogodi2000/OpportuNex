import 'package:flutter/material.dart';

class MatchScorePanel extends StatelessWidget {
  final int score;

  const MatchScorePanel({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    Color scoreColor;
    String eligibilityLabel;

    if (score < 40) {
      scoreColor = const Color(
        0xFF0D1B3E,
      ); // Blue for low? Or maybe use Red/Orange. Spec: blue 0-39
      eligibilityLabel = 'Peu probable';
    } else if (score < 70) {
      scoreColor = const Color(0xFFF97316); // Orange 40-69
      eligibilityLabel = 'Incertain';
    } else {
      scoreColor = const Color(0xFF22C55E); // Green 70-100
      eligibilityLabel = 'Probable';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score de correspondance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    color: scoreColor,
                  ),
                ),
                Text(
                  '$score%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              eligibilityLabel,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scoreColor,
              ),
            ),
          ),
          SizedBox(height: 32),
          Text(
            'Points forts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF22C55E),
            ),
          ),
          SizedBox(height: 8),
          _buildListItem(
            Icons.check_circle,
            Colors.green,
            'Expérience correspondante',
          ),
          _buildListItem(
            Icons.check_circle,
            Colors.green,
            'Localisation valide',
          ),
          SizedBox(height: 16),
          Text(
            'Écarts',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          SizedBox(height: 8),
          _buildListItem(Icons.cancel, Colors.red, 'Langue requise manquante'),
          SizedBox(height: 16),
          Text(
            'À vérifier',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFF97316),
            ),
          ),
          SizedBox(height: 8),
          _buildListItem(
            Icons.warning,
            Colors.orange,
            'Diplôme spécifique exigé',
          ),
          SizedBox(height: 32),
          Text(
            'Détails des critères',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildProgressBar(context, 'Expérience', 0.8),
          _buildProgressBar(context, 'Compétences', 0.6),
          _buildProgressBar(context, 'Langue', 0.3),
        ],
      ),
    );
  }

  Widget _buildListItem(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    String label,
    double progress,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12)),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            color: Theme.of(context).colorScheme.primary,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
