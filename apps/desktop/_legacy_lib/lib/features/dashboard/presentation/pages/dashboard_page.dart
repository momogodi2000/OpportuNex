import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../../domain/dashboard_models.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: state.when(
        data: (data) => _buildContent(context, data, ref, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Erreur: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(dashboardProvider.notifier).refreshAll(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardState data, WidgetRef ref, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).refreshAll(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tableau de bord',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Aperçu de vos opportunités et de l'activité du système",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildStatCards(context, data.counters, theme),
                  const SizedBox(height: 48),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildRecentActivity(context, data.recentActivity, theme),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildDeadlines(context, data.upcomingDeadlines, theme),
                            const SizedBox(height: 32),
                            _buildSourceHealth(context, data.sourceHealth, theme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, DashboardCounters counters, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 2.5,
          children: [
            _ModernStatCard(
              title: 'Opportunités',
              value: counters.totalOpportunities.toString(),
              icon: Icons.lightbulb_outline,
              color: const Color(0xFF3B82F6),
              trend: '+12%',
            ),
            _ModernStatCard(
              title: 'Candidatures',
              value: counters.pendingApplications.toString(),
              icon: Icons.work_outline,
              color: const Color(0xFF10B981),
              trend: '+3',
            ),
            _ModernStatCard(
              title: 'Sources Actives',
              value: counters.monitorsActive.toString(),
              icon: Icons.language,
              color: const Color(0xFF8B5CF6),
            ),
            _ModernStatCard(
              title: 'Nouvelles (24h)',
              value: counters.newThisWeek.toString(),
              icon: Icons.fiber_new,
              color: const Color(0xFFF59E0B),
            ),
          ],
        );
      }
    );
  }

  Widget _buildRecentActivity(BuildContext context, List<RecentActivity> activities, ThemeData theme) {
    return _ModernPanel(
      title: 'Activité Récente',
      icon: Icons.history,
      child: activities.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('Aucune activité récente')),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) => Divider(color: theme.colorScheme.onSurface.withOpacity(0.05)),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getActivityColor(context, activity.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getActivityIcon(activity.type), color: _getActivityColor(context, activity.type)),
                  ),
                  title: Text(activity.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('dd MMM yyyy HH:mm').format(activity.occurredAt),
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDeadlines(BuildContext context, List<UpcomingDeadline> deadlines, ThemeData theme) {
    return _ModernPanel(
      title: 'Échéances Proches',
      icon: Icons.timer_outlined,
      child: deadlines.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('Aucune échéance à venir')),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: deadlines.length,
              itemBuilder: (context, index) {
                final deadline = deadlines[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  title: Text(deadline.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${deadline.daysLeft} j',
                      style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSourceHealth(BuildContext context, List<SourceHealth> sources, ThemeData theme) {
    return _ModernPanel(
      title: 'État des Sources',
      icon: Icons.health_and_safety_outlined,
      child: sources.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('Aucune source surveillée')),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sources.length,
              itemBuilder: (context, index) {
                final source = sources[index];
                final isHealthy = source.status == 'ok';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  title: Text(source.name),
                  trailing: Icon(
                    isHealthy ? Icons.check_circle : Icons.error,
                    color: isHealthy ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                );
              },
            ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'new': return Icons.add_circle_outline;
      case 'save': return Icons.bookmark_border;
      case 'apply': return Icons.send_outlined;
      case 'monitor': return Icons.visibility_outlined;
      default: return Icons.info_outline;
    }
  }

  Color _getActivityColor(BuildContext context, String type) {
    switch (type) {
      case 'new': return const Color(0xFF3B82F6);
      case 'save': return const Color(0xFFF59E0B);
      case 'apply': return const Color(0xFF10B981);
      case 'monitor': return const Color(0xFF8B5CF6);
      default: return Colors.grey;
    }
  }
}

class _ModernPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ModernPanel({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.onSurface.withOpacity(0.05)),
          child,
        ],
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (trend != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          trend!,
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



