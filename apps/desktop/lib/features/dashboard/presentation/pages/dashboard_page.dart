import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stat_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: state.when(
        data: (data) => _buildContent(context, data, ref),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF22C55E)),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Erreur: ${err.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(dashboardProvider.notifier).refreshAll(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DashboardState data,
    WidgetRef ref,
  ) {
    final isBrandNew = data.counters.totalOpportunities == 0;

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).refreshAll(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),

            if (isBrandNew)
              _buildOnboardingCard(context)
            else ...[
              _buildStatsRow(data),
              const SizedBox(height: 32),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickActions(context),
                        const SizedBox(height: 32),
                        _buildRecentActivity(data.recentActivity),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUpcomingDeadlines(data.upcomingDeadlines),
                        const SizedBox(height: 24),
                        _buildSourceHealth(data.sourceHealth),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final today = dateFormat.format(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bonjour, Utilisateur 👋',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B3E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              today.capitalize(),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOnboardingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.rocket_launch,
            size: 64,
            color: const Color(0xFFF97316).withOpacity(0.8),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bienvenue sur OpportuNex !',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B3E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Commencez par lancer votre première recherche pour trouver des opportunités correspondantes à votre profil.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search),
            label: const Text('Nouvelle recherche'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(DashboardState data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            StatCard(
              icon: Icons.article_rounded,
              label: 'Total Opportunités',
              value: data.counters.totalOpportunities,
              backgroundColor: const Color(0xFF0D1B3E),
            ),
            StatCard(
              icon: Icons.fiber_new_rounded,
              label: 'Nouvelles',
              value: data.counters.newThisWeek,
              trend: '+${data.counters.newThisWeek} cette semaine',
              backgroundColor: const Color(0xFF22C55E),
            ),
            StatCard(
              icon: Icons.bookmark_rounded,
              label: 'Sauvegardées',
              value: data.counters.savedCount,
              backgroundColor: const Color(0xFFF97316),
            ),
            StatCard(
              icon: Icons.send_rounded,
              label: 'Candidatures en cours',
              value: data.counters.pendingApplications,
              backgroundColor: Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3E),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.search,
                label: 'Nouvelle recherche',
                onTap: () => context.go('/search'),
                color: const Color(0xFF22C55E),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.send,
                label: 'Voir mes candidatures',
                onTap: () => context.go('/applications'),
                color: const Color(0xFF0D1B3E),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.notifications_active,
                label: 'Configurer une veille',
                onTap: () => context.go('/monitors'),
                color: const Color(0xFFF97316),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(List activityList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activité récente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3E),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activityList.length > 5 ? 5 : activityList.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            itemBuilder: (context, index) {
              final activity = activityList[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getActivityColor(
                    activity.type,
                  ).withOpacity(0.1),
                  child: Icon(
                    _getActivityIcon(activity.type),
                    color: _getActivityColor(activity.type),
                  ),
                ),
                title: Text(
                  activity.description,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  DateFormat(
                    'dd MMM à HH:mm',
                    'fr_FR',
                  ).format(activity.occurredAt),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingDeadlines(List deadlines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prochaines échéances',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3E),
          ),
        ),
        const SizedBox(height: 16),
        if (deadlines.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Center(child: Text('Aucune échéance proche')),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: deadlines.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final deadline = deadlines[index];
              final isUrgent = deadline.daysLeft <= 3;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUrgent
                        ? Colors.red.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deadline.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(deadline.deadline),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'J-${deadline.daysLeft}',
                          style: TextStyle(
                            color: isUrgent
                                ? Colors.red
                                : const Color(0xFFF97316),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSourceHealth(List sources) {
    return ExpansionTile(
      title: const Text(
        'État des sources',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E)),
      ),
      collapsedBackgroundColor: Colors.white,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      children: sources.map((s) {
        final isOk = s.status == 'ok';
        return ListTile(
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOk ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          title: Text(s.name, style: const TextStyle(fontSize: 14)),
          trailing: Text(
            '${(s.reliability * 100).toStringAsFixed(0)}% fiable',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        );
      }).toList(),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'search':
        return Icons.search;
      case 'save':
        return Icons.bookmark;
      case 'apply':
        return Icons.send;
      case 'monitor':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'search':
        return const Color(0xFF22C55E);
      case 'save':
        return const Color(0xFFF97316);
      case 'apply':
        return Colors.purple;
      case 'monitor':
        return const Color(0xFF0D1B3E);
      default:
        return Colors.grey;
    }
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
