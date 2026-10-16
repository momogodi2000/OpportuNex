import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ProvenanceTag {
  verified,
  deduced,
  aiGenerated,
  notSpecified,
  unverifiable,
  expired,
  expiringSoon,
}

class ProvenanceBadge extends StatelessWidget {
  final ProvenanceTag tag;
  final bool compact;

  const ProvenanceBadge({super.key, required this.tag, this.compact = false});

  String get _label {
    switch (tag) {
      case ProvenanceTag.verified:
        return 'Vérifié';
      case ProvenanceTag.deduced:
        return 'Déduit';
      case ProvenanceTag.aiGenerated:
        return 'Généré IA';
      case ProvenanceTag.notSpecified:
        return 'Non précisé';
      case ProvenanceTag.unverifiable:
        return 'Non vérifiable';
      case ProvenanceTag.expired:
        return 'Expiré';
      case ProvenanceTag.expiringSoon:
        return 'Échéance proche';
    }
  }

  String get _tooltip {
    switch (tag) {
      case ProvenanceTag.verified:
        return 'Information confirmée par une source officielle.';
      case ProvenanceTag.deduced:
        return 'Information déduite à partir du contexte.';
      case ProvenanceTag.aiGenerated:
        return 'Information extraite ou générée par intelligence artificielle.';
      case ProvenanceTag.notSpecified:
        return 'Aucune information fournie.';
      case ProvenanceTag.unverifiable:
        return 'Information impossible à vérifier indépendamment.';
      case ProvenanceTag.expired:
        return 'Cette opportunité a expiré.';
      case ProvenanceTag.expiringSoon:
        return 'La date limite approche.';
    }
  }

  Color get _color {
    switch (tag) {
      case ProvenanceTag.verified:
        return AppTheme.badgeVerified;
      case ProvenanceTag.deduced:
        return AppTheme.badgeDeduced;
      case ProvenanceTag.aiGenerated:
        return AppTheme.badgeAIGenerated;
      case ProvenanceTag.notSpecified:
        return AppTheme.badgeNotSpecified;
      case ProvenanceTag.unverifiable:
        return AppTheme.badgeUnverifiable;
      case ProvenanceTag.expired:
        return AppTheme.badgeExpired;
      case ProvenanceTag.expiringSoon:
        return AppTheme.badgeExpiringSoon;
    }
  }

  IconData get _icon {
    switch (tag) {
      case ProvenanceTag.verified:
        return Icons.check_circle;
      case ProvenanceTag.deduced:
        return Icons.psychology;
      case ProvenanceTag.aiGenerated:
        return Icons.auto_awesome;
      case ProvenanceTag.notSpecified:
        return Icons.help_outline;
      case ProvenanceTag.unverifiable:
        return Icons.warning_amber;
      case ProvenanceTag.expired:
        return Icons.error_outline;
      case ProvenanceTag.expiringSoon:
        return Icons.timer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _color.withOpacity(0.1);
    final foregroundColor = _color;

    final child = Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 12 : 16, color: foregroundColor),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              _label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(message: _tooltip, child: child);
  }
}
