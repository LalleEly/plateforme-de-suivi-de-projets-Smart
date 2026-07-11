import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_error.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/models/kpi_model.dart';
import '../../../../shared/models/member_model.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../shared/models/task_model.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  final KpiDashboardModel? kpi;
  final List<ProjectModel> projects;
  final List<TaskModel> tasks;
  final Future<void> Function() onRefresh;

  const DashboardScreen({
    super.key,
    required this.kpi,
    required this.projects,
    required this.tasks,
    required this.onRefresh,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = '';
  String _userRole = '';
  List<MemberKpiModel> _teamLoad = [];
  bool _teamLoadLoading = false;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await ApiService.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    _loadUnreadCount();
  }

  @override
  void didUpdateWidget(DashboardScreen old) {
    super.didUpdateWidget(old);
    // إذا تبدلت قائمة المشاريع (مثلا بعد refresh)، أعد تحميل charge équipe
    if (old.projects.length != widget.projects.length) {
      _loadTeamLoad();
    }
  }

  Future<void> _loadUser() async {
    final name = await StorageService.getUserName();
    final role = await StorageService.getUserRole();
    setState(() {
      _userName = name ?? '';
      _userRole = role ?? '';
    });
    if (_canCreateProject) _loadTeamLoad();
  }

  // ── يجمع KPI الأعضاء من كل المشاريع لي عند المستخدم ──────
  Future<void> _loadTeamLoad() async {
    if (widget.projects.isEmpty) return;
    setState(() => _teamLoadLoading = true);

    final Map<int, MemberKpiModel> merged = {};
    // نحدّو 5 مشاريع باش ما نزيدوش طلبات بزاف فديما واحدة
    final projectsToCheck = widget.projects.take(5).toList();

    for (final project in projectsToCheck) {
      try {
        final kpis = await ApiService.getMemberKpis(project.id);
        for (final k in kpis) {
          if (merged.containsKey(k.userId)) {
            final prev = merged[k.userId]!;
            merged[k.userId] = MemberKpiModel(
              userId: k.userId,
              memberName: k.memberName,
              tasksAssigned: prev.tasksAssigned + k.tasksAssigned,
              tasksCompleted: prev.tasksCompleted + k.tasksCompleted,
              loggedHours: prev.loggedHours + k.loggedHours,
              workload: ((prev.workload + k.workload) / 2),
              efficiency: ((prev.efficiency + k.efficiency) / 2),
              overloaded: prev.overloaded || k.overloaded,
            );
          } else {
            merged[k.userId] = k;
          }
        }
      } catch (_) {
        // إيلا مشروع معين رجّع 403 (ماشي ديال هاد المستخدم)، تجاهلو وكمل البقية
        continue;
      }
    }

    final list = merged.values.toList()
      ..sort((a, b) => b.workload.compareTo(a.workload));

    if (mounted) {
      setState(() {
        _teamLoad = list.take(4).toList();
        _teamLoadLoading = false;
      });
    }
  }

  bool get _canCreateProject =>
      _userRole == 'MANAGER' || _userRole == 'CHEF_PROJET';

  Color get _roleColor =>
      _userRole == 'MANAGER' ? context.colors.purple : context.colors.blue;

  IconData get _roleIcon => _userRole == 'MANAGER'
      ? Icons.admin_panel_settings_outlined
      : Icons.person_outline;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTopBar(),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async {
            await widget.onRefresh();
            if (_canCreateProject) await _loadTeamLoad();
          },
          color: context.colors.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              if (_userRole.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: _roleColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _roleColor.withOpacity(0.4))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_roleIcon, size: 12, color: _roleColor),
                        const SizedBox(width: 5),
                        Text(_userRole.replaceAll('_', ' '),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _roleColor)),
                      ],
                    ),
                  ),
                ),
              if (widget.kpi != null) ...[
                _buildKpiCards(),
                const SizedBox(height: 12),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildProjects()),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(children: [
                    // Charge équipe غير لـ MANAGER/CHEF_PROJET (نفس صلاحية /kpi/members)
                    if (_canCreateProject) ...[
                      _buildTeamLoad(),
                      const SizedBox(height: 12),
                    ],
                    _buildAlerts(),
                  ])),
                ],
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildTopBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          border:
              Border(bottom: BorderSide(color: context.colors.border, width: 0.5))),
      child: Row(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                _userName.isNotEmpty
                    ? l10n.dashboardGreeting(_userName)
                    : l10n.dashboardTitle,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.colors.text1)),
            Text('Juin 2025',
                style: TextStyle(fontSize: 10, color: context.colors.text2)),
          ],
        ),
        const Spacer(),
        Stack(children: [
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: context.colors.text2, size: 20),
            onPressed: _openNotifications,
          ),
          if (_unreadNotifications > 0)
            Positioned(
                top: 8,
                right: 8,
                child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: context.colors.red, shape: BoxShape.circle))),
        ]),
        const SizedBox(width: 6),
        if (_canCreateProject)
          ElevatedButton.icon(
            onPressed: () => _showCreateProjectDialog(),
            icon: const Icon(Icons.add, size: 14),
            label: Text(l10n.newProjectButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7)),
            ),
          )
        else
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: context.colors.bg3,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: context.colors.border)),
              child: Text(l10n.memberViewBadge,
                  style: TextStyle(fontSize: 11, color: context.colors.text2))),
      ]),
    );
  }

  Widget _buildKpiCards() {
    final l10n = AppLocalizations.of(context)!;
    final kpi = widget.kpi;
    final items = [
      _KpiData(l10n.kpiActiveProjects, kpi != null ? '${kpi.totalProjects}' : '0',
          '+3 ce mois', true, context.colors.blue, Icons.folder_outlined),
      _KpiData(
          l10n.kpiCompletionRate,
          kpi != null ? '${kpi.completionRate.toStringAsFixed(0)}%' : '0%',
          '+4% vs T1',
          true,
          context.colors.green,
          Icons.check_circle_outline),
      _KpiData(
          l10n.kpiCompletedTasks,
          kpi != null ? '${kpi.completedTasks}' : '0',
          'sur ${kpi?.totalTasks ?? 0} total',
          true,
          context.colors.amber,
          Icons.task_alt_outlined),
      _KpiData(
          l10n.kpiLoggedHours,
          kpi != null ? '${kpi.totalLoggedHours}h' : '0h',
          'cette semaine',
          true,
          context.colors.purple,
          Icons.access_time_outlined),
    ];

    return Row(
        children: items
            .asMap()
            .entries
            .map((e) => Expanded(
                    child: Padding(
                  padding:
                      EdgeInsets.only(right: e.key < items.length - 1 ? 8 : 0),
                  child: _kpiCard(e.value),
                )))
            .toList());
  }

  Widget _kpiCard(_KpiData item) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(item.icon, color: item.color, size: 17)),
          const SizedBox(height: 8),
          Text(item.value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: item.color)),
          const SizedBox(height: 1),
          Text(item.label,
              style: TextStyle(fontSize: 10, color: context.colors.text2)),
          const SizedBox(height: 5),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: context.colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16)),
              child: Text(item.delta,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: context.colors.green))),
        ],
      ),
    );
  }

  Widget _buildProjects() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(l10n.projectsPortfolioTitle,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: context.colors.text2,
                    letterSpacing: 0.07)),
          ]),
          const SizedBox(height: 10),
          if (widget.projects.isEmpty)
            Center(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.noProjects,
                        style: TextStyle(color: context.colors.text2))))
          else
            ...widget.projects.take(5).map(_buildProjectRow),
          const SizedBox(height: 10),
          Row(children: [
            _dot(context.colors.green,
                l10n.activeCount(widget.projects.where((p) => p.status == 'ACTIVE').length)),
            const SizedBox(width: 10),
            _dot(context.colors.amber,
                l10n.planningCount(widget.projects.where((p) => p.status == 'PLANNING').length)),
          ]),
        ],
      ),
    );
  }

  Widget _buildProjectRow(ProjectModel project) {
    final l10n = AppLocalizations.of(context)!;
    final colors = {
      'ACTIVE': context.colors.green,
      'PLANNING': context.colors.blue,
      'ON_HOLD': context.colors.amber,
      'COMPLETED': context.colors.cyan,
    };
    final color = colors[project.status] ?? context.colors.red;
    final total = project.taskCount > 0 ? project.taskCount : 1;
    final done = (total * 0.6).round();
    final progress = done / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.name,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.text1),
                overflow: TextOverflow.ellipsis),
            Text(
                '${project.memberCount} membres · '
                '${project.taskCount} tâches',
                style: TextStyle(fontSize: 10, color: context.colors.text2)),
          ],
        )),
        const SizedBox(width: 8),
        SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${(progress * 100).toInt()}%',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 3),
                ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: context.colors.bg4,
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 3)),
              ],
            )),
        const SizedBox(width: 8),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Text(
                project.status == 'ACTIVE'
                    ? l10n.statusActive
                    : project.status == 'PLANNING'
                        ? l10n.statusPlanning
                        : project.status == 'ON_HOLD'
                            ? l10n.statusPaused
                            : l10n.statusCompleted,
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: color))),
      ]),
    );
  }

  // ── Charge équipe: بيانات حقيقية من /kpi/members/{projectId} ──
  Widget _buildTeamLoad() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(l10n.teamLoadTitle,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: context.colors.text2,
                    letterSpacing: 0.07)),
          ]),
          const SizedBox(height: 10),
          if (_teamLoadLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: context.colors.accent))),
            )
          else if (_teamLoad.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(l10n.noTeamLoadData,
                  style: TextStyle(fontSize: 10, color: context.colors.text3)),
            )
          else
            ..._teamLoad.map(_buildMemberLoadRow),
        ],
      ),
    );
  }

  Widget _buildMemberLoadRow(MemberKpiModel m) {
    final color = m.overloaded
        ? context.colors.red
        : (m.workload > 70 ? context.colors.amber : context.colors.green);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text(m.memberName,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.colors.text1),
                    overflow: TextOverflow.ellipsis)),
            if (m.overloaded)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.warning_amber_rounded,
                    size: 11, color: context.colors.red),
              ),
            Text('${m.workload.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (m.workload / 100).clamp(0, 1),
              backgroundColor: context.colors.bg4,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlerts() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Column(children: [
        Row(children: [
          Text(l10n.alertsTitle,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.colors.text2,
                  letterSpacing: 0.07)),
        ]),
        const SizedBox(height: 10),
        ...widget.tasks.where((t) => t.overdue).take(3).map((t) => _alertBox(
            context.colors.red,
            l10n.taskOverdue(t.title),
            t.projectName)),
        if (widget.tasks.where((t) => t.overdue).isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(l10n.noAlerts,
                style: TextStyle(fontSize: 10, color: context.colors.text3)),
          ),
      ]),
    );
  }

  Widget _alertBox(Color color, String title, String sub) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded, size: 12, color: color),
            const SizedBox(width: 5),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color))),
          ]),
          const SizedBox(height: 2),
          Text(sub,
              style: TextStyle(fontSize: 10, color: context.colors.text2)),
        ],
      ),
    );
  }

  Widget _dot(Color color, String label) {
    return Row(children: [
      Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: context.colors.text2)),
    ]);
  }

  void _showCreateProjectDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final keyCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final budgetCtrl = TextEditingController(text: '50000');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.bg2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: context.colors.border)),
        title: Text(l10n.newProjectDialogTitle,
            style:
                TextStyle(color: context.colors.text1, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(l10n.fieldProjectName, nameCtrl),
              const SizedBox(height: 10),
              _dialogField(l10n.fieldProjectKey, keyCtrl),
              const SizedBox(height: 10),
              _dialogField(l10n.fieldDescription, descCtrl),
              const SizedBox(height: 10),
              _dialogField(l10n.fieldBudget, budgetCtrl,
                  type: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel,
                  style: TextStyle(color: context.colors.text2))),
          ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || keyCtrl.text.isEmpty) return;
                try {
                  await ApiService.createProject(
                      nameCtrl.text,
                      keyCtrl.text.toUpperCase(),
                      descCtrl.text,
                      double.tryParse(budgetCtrl.text) ?? 50000);
                  Navigator.pop(context);
                  await widget.onRefresh();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.projectCreatedSuccess),
                      backgroundColor: context.colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.errorGeneric(apiErrorMessage(e, fallback: '$e'))),
                      backgroundColor: context.colors.red,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: context.colors.accent),
              child: Text(l10n.createProjectButton)),
        ],
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: context.colors.text2)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: type,
          style: TextStyle(fontSize: 12, color: context.colors.text1),
          decoration: InputDecoration(
              filled: true,
              fillColor: context.colors.bg3,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.colors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.colors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: context.colors.accent, width: 1.5)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9)),
        ),
      ],
    );
  }
}

class _KpiData {
  final String label, value, delta;
  final bool isUp;
  final Color color;
  final IconData icon;
  _KpiData(
      this.label, this.value, this.delta, this.isUp, this.color, this.icon);
}