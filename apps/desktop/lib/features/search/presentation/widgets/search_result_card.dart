import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/search_models.dart';

class SearchResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onSave;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.result,
    required this.onSave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (result.isNew) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF22C55E,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NOUVEAU',
                                  style: TextStyle(
                                    color: Color(0xFF22C55E),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1B3E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                result.category,
                                style: const TextStyle(
                                  color: Color(0xFF0D1B3E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1B3E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.organization,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildMatchScore(),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildIconText(Icons.location_on_outlined, result.location),
                  const SizedBox(width: 16),
                  if (result.deadline != null) _buildDeadline(result.deadline!),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          result.provenanceDeadline,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      result.isSaved ? Icons.favorite : Icons.favorite_border,
                      color: result.isSaved ? Colors.red : Colors.grey,
                    ),
                    onPressed: onSave,
                    tooltip: 'Sauvegarder',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D1B3E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Voir détails'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
      ],
    );
  }

  Widget _buildDeadline(DateTime deadline) {
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    Color color = const Color(0xFF22C55E); // Green > 14
    if (daysLeft < 7) {
      color = Colors.red;
    } else if (daysLeft <= 14) {
      color = const Color(0xFFF97316); // Orange
    }

    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          DateFormat('dd MMM yyyy').format(deadline),
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchScore() {
    Color scoreColor = const Color(0xFF22C55E);
    if (result.score < 0.5) {
      scoreColor = const Color(0xFFF97316);
    } else if (result.score < 0.8) {
      scoreColor = Colors.blue;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scoreColor, width: 3),
      ),
      child: Center(
        child: Text(
          '${(result.score * 100).toInt()}%',
          style: TextStyle(
            color: scoreColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
