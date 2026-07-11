import 'package:flutter/material.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/kpi_model.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../shared/models/task_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../projects/presentation/screens/projects_screen.dart';
import '../../../tasks/presentation/screens/tasks_screen.dart';
import '../../../kpi/presentation/screens/kpi_screen.dart';
import '../../../members/presentation/screens/members_screen.dart';
import '../../../time/presentation/screens/time_screen.dart';
import '../../../profit/presentation/screens/profit_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  KpiDashboardModel? _kpi;
  List<ProjectModel> _projects = [];
  List<TaskModel> _tasks = [];
  String _userName = '';
  String _userRole = '';
  String _userInitials = '';
  bool _loading = true;
  String? _error;

  // تعريف عناصر القائمة + الأدوار المسموح لها تشوف كل عنصر
  // roles: null = الكل، ['MANAGER'] = manager فقط، ['MANAGER','CHEF_PROJET'] = manager+chef
  static const _navDefs = [
    _NavDef(0, Icons.dashboard_outlined, 'Tableau de bord', 'Principal', null),
    _NavDef(1, Icons.folder_outlined, 'Projets', 'Principal', null),
    _NavDef(2, Icons.check_box_outlined, 'Mes tâches', 'Principal', null),
    _NavDef(3, Icons.bar_chart_rounded, 'Indicateurs KPI', 'Analyse', ['MANAGER']),
    _NavDef(6, Icons.monetization_on_outlined, 'Rentabilité', 'Analyse', ['MANAGER', 'CHEF_PROJET']),
    _NavDef(7, Icons.description_outlined, 'Rapports', 'Analyse', ['MANAGER', 'CHEF_PROJET']),
    _NavDef(4, Icons.people_outline, 'Ressources', 'Équipe', ['MANAGER', 'CHEF_PROJET']),
    _NavDef(5, Icons.access_time_rounded, 'Suivi des temps', 'Équipe', null),
    _NavDef(8, Icons.settings_outlined, 'Paramètres', 'Système', null),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await StorageService.getToken();
      final name = await StorageService.getUserName();
      final role = await StorageService.getUserRole();
      if (token != null) ApiService.setToken(token);

      final resolvedRole = role ?? 'MEMBRE';

      final projects = await ApiService.getProjects();
      final tasks = await ApiService.getMyTasks();

      // /kpi/dashboard مسموح غير لـ MANAGER، خاص نتجنبو نطلبوه للأدوار الأخرى
      KpiDashboardModel? kpi;
      if (resolvedRole == 'MANAGER') {
        try {
          kpi = await ApiService.getDashboard();
        } catch (_) {
          kpi = null; // ما نخليوش الصفحة كاملة تطيح بسبب الـ KPI وحدها
        }
      }

      final parts = (name ?? '').trim().split(' ');
      final initials = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : (name?.isNotEmpty == true ? name![0].toUpperCase() : 'U');

      setState(() {
        _userName = name ?? 'Utilisateur';
        _userRole = resolvedRole;
        _userInitials = initials;
        _kpi = kpi;
        _projects = projects;
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = apiErrorMessage(e, fallback: 'Impossible de charger les données. Vérifiez la connexion.');
      });
    }
  }

  // Filtre les éléments de nav selon le rôle
  List<_NavDef> get _visibleNav {
    return _navDefs.where((n) {
      if (n.roles == null) return true;
      return n.roles!.contains(_userRole);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      body: Row(children: [
        _buildSidebar(),
        Expanded(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(color: context.colors.accent))
              : _error != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.wifi_off_rounded, size: 48, color: context.colors.text3),
        const SizedBox(height: 16),
        Text(_error!,
            style: TextStyle(fontSize: 13, color: context.colors.text2)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Réessayer'),
          style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.accent,
              foregroundColor: Colors.white),
        ),
      ]),
    );
  }

  Widget _buildSidebar() {
    final visible = _visibleNav;
    final sections = ['Principal', 'Analyse', 'Équipe', 'Système'];

    return Container(
      width: 220,
      color: context.colors.bg2,
      child: Column(children: [
        // Logo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: context.colors.border, width: 0.5))),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.colors.accent, const Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.analytics_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ProjectFlow',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colors.text1)),
                  Text('Gestion de projets',
                      style: TextStyle(fontSize: 10, color: context.colors.text2)),
                ],
              ),
            ),
          ]),
        ),

        // Badge rôle
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: context.colors.border, width: 0.5))),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _roleColor(_userRole).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _roleColor(_userRole).withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_roleIcon(_userRole),
                  size: 12, color: _roleColor(_userRole)),
              const SizedBox(width: 5),
              Text(_userRole.replaceAll('_', ' '),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _roleColor(_userRole))),
            ]),
          ),
        ),

        // Navigation
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: [
              for (final section in sections) ...[
                if (visible.any((n) => n.section == section)) ...[
                  _sectionLabel(section),
                  ...visible
                      .where((n) => n.section == section)
                      .map((n) => _navRow(n)),
                ],
              ],
            ],
          ),
        ),

        // Utilisateur + Déconnexion
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              border:
                  Border(top: BorderSide(color: context.colors.border, width: 0.5))),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [context.colors.accent, const Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                child: Text(_userInitials,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_userName,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.colors.text1),
                      overflow: TextOverflow.ellipsis),
                  Text(_userRole.replaceAll('_', ' '),
                      style: TextStyle(
                          fontSize: 9, color: context.colors.text2)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.logout_rounded,
                  size: 15, color: context.colors.text2),
              padding: EdgeInsets.zero,
              tooltip: 'Déconnexion',
              onPressed: () async {
                await StorageService.logout();
                ApiService.clearToken();
                if (mounted) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              },
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 3),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: context.colors.text3,
              letterSpacing: 0.08)),
    );
  }

  Widget _navRow(_NavDef nav) {
    final isActive = _selectedIndex == nav.index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = nav.index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? context.colors.accent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: isActive
              ? Border(
                  left: BorderSide(color: context.colors.accent, width: 2))
              : null,
        ),
        child: Row(children: [
          Icon(nav.icon,
              size: 15,
              color: isActive ? context.colors.accentLight : context.colors.text2),
          const SizedBox(width: 9),
          Expanded(
            child: Text(nav.label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? context.colors.accentLight : context.colors.text2)),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
            kpi: _kpi,
            projects: _projects,
            tasks: _tasks,
            onRefresh: _loadData);
      case 1:
        return const ProjectsScreen();
      case 2:
        return const TasksScreen();
      case 3:
        return const KpiScreen();
      case 4:
        return const MembersScreen();
      case 5:
        return const TimeScreen();
      case 6:
        return const ProfitScreen();
      case 7:
        return const ReportsScreen();
      case 8:
        return const SettingsScreen();
      default:
        return DashboardScreen(
            kpi: _kpi,
            projects: _projects,
            tasks: _tasks,
            onRefresh: _loadData);
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'MANAGER': return context.colors.purple;
      case 'CHEF_PROJET': return context.colors.accent;
      default: return context.colors.blue;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'MANAGER': return Icons.admin_panel_settings_outlined;
      case 'CHEF_PROJET': return Icons.manage_accounts_outlined;
      default: return Icons.person_outline;
    }
  }
}

class _NavDef {
  final int index;
  final IconData icon;
  final String label;
  final String section;
  final List<String>? roles;
  const _NavDef(this.index, this.icon, this.label, this.section, this.roles);
}