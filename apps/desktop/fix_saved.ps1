$content = Get-Content lib\features\saved\presentation\pages\saved_page.dart -Raw
$content = $content -replace "Text\(\"Erreur: \\\\\\"\)", "Text("Erreur: $e")"
$content = $content -replace "Widget _buildSavedCard\(BuildContext context\) \{", "Widget _buildSavedCard(BuildContext context, dynamic item) {"
Set-Content lib\features\saved\presentation\pages\saved_page.dart $content
