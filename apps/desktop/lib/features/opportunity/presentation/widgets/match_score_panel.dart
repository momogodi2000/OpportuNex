import 'package:flutter/material.dart';

class MatchScorePanel extends StatelessWidget {
  final int score;

  const MatchScorePanel({Key? key, required this.score}) : super(key: key);

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
          const Text(
            'Score de correspondance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 32),
          const Text(
            'Points forts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF22C55E),
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          const Text(
            'Écarts',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 8),
          _buildListItem(Icons.cancel, Colors.red, 'Langue requise manquante'),
          const SizedBox(height: 16),
          const Text(
            'À vérifier',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFF97316),
            ),
          ),
          const SizedBox(height: 8),
          _buildListItem(
            Icons.warning,
            Colors.orange,
            'Diplôme spécifique exigé',
          ),
          const SizedBox(height: 32),
          const Text(
            'Détails des critères',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildProgressBar('Expérience', 0.8),
          _buildProgressBar('Compétences', 0.6),
          _buildProgressBar('Langue', 0.3),
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
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            color: const Color(0xFF0D1B3E),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
