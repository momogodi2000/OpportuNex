import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

String applicationStatusLabel(AppLocalizations l, String status) => switch (status) {
      'discovered' => l.stDiscovered,
      'to_review' => l.stToReview,
      'preparing' => l.stPreparing,
      'ready' => l.stReady,
      'submitted' => l.stSubmitted,
      'interview' => l.stInterview,
      'accepted' => l.stAccepted,
      'rejected' => l.stRejected,
      'withdrawn' => l.stWithdrawn,
      'expired' => l.stExpired,
      'archived' => l.stArchived,
      _ => status,
    };

IconData applicationStatusIcon(String status) => switch (status) {
      'discovered' => Icons.lightbulb_outline,
      'to_review' => Icons.rate_review_outlined,
      'preparing' => Icons.edit_note,
      'ready' => Icons.task_alt,
      'submitted' => Icons.send_outlined,
      'interview' => Icons.record_voice_over_outlined,
      'accepted' => Icons.emoji_events_outlined,
      'rejected' => Icons.cancel_outlined,
      'withdrawn' => Icons.undo,
      'expired' => Icons.event_busy,
      'archived' => Icons.inventory_2_outlined,
      _ => Icons.circle_outlined,
    };

String priorityLabel(AppLocalizations l, String p) => switch (p) {
      'high' => l.prioHigh,
      'low' => l.prioLow,
      _ => l.prioMedium,
    };

String docTypeLabel(AppLocalizations l, String t) => switch (t) {
      'cover_letter' => l.docCoverLetter,
      'scholarship_statement' => l.docScholarship,
      'grant_proposal' => l.docGrant,
      'project_summary' => l.docProjectSummary,
      'application_email' => l.docEmail,
      'cv_suggestions' => l.docCvSuggestions,
      'interview_prep' => l.docInterview,
      _ => t,
    };
