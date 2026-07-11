import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/kpi_model.dart';
import '../../../../shared/models/member_model.dart';

class KpiScreen extends StatefulWidget {
  const KpiScreen({super.key});

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen> {
  KpiDashboardModel? _kpi;
  bool _loading = true;
  String? _error;

  int? _selectedProjectId;
  List<MemberKpiModel> _members = [];
  bool _membersLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await StorageService.getToken();
      if (token != null) ApiService.setToken(token);
      final kpi = await ApiService.getDashboard();
      setState(() {
        _kpi = kpi;
        _loading = false;
        if (kpi.projectKpis.isNotEmpty) {
          _selectedProjectId = kpi.projectKpis.first.projectId;
          _loadMembers();
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = apiErrorMessage(e, fallback: 'Impossible de charger les KPI (accès réservé aux Managers)');
      });
    }
  }

  Future<void> _loadMembers() async {
    if (_selectedProjectId == null) return;
    setState(() => _membersLoading = true);
    try {
      final members = await ApiService.getMemberKpis(_selectedProjectId!);
      setState(() {
        _members = members..sort((a, b) => b.workload.compareTo(a.workload));
        _membersLoading = false;
      });
    } catch (_) {
      setState(() {
        _members = [];
        _membersLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTopBar(),
      Expanded(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(color: context.colors.accent))
            : _error != null
                ? _buildError()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _buildStatCards(),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildBarChart()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildScoreTable()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildMemberPerf(),
                    ]),
                  ),
      ),
    ]);
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.lock_outline, size: 48, color: context.colors.text3),
        const SizedBox(height: 16),
        Text(_error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.colors.text2)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Réessayer'),
          style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.accent, foregroundColor: Colors.white),
        ),
      ]),
    );
  }

  Widget _buildTopBar() {
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
            Text('Indicateurs KPI',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.colors.text1)),
            Text('Performance globale',
                style: TextStyle(fontSize: 10, color: context.colors.text2)),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.refresh_rounded,
              size: 18, color: context.colors.text2),
          tooltip: 'Actualiser',
          onPressed: _load,
        ),
      ]),
    );
  }

  Widget _buildStatCards() {
    final kpi = _kpi;
    final cards = [
      _KpiCard(
          'Taux de complétion',
          kpi != null ? '${kpi.completionRate.toStringAsFixed(0)}%' : '0%',
          '${kpi?.completedTasks ?? 0}/${kpi?.totalTasks ?? 0} tâches',
          true,
          context.colors.green,
          Icons.check_circle_outline),
      _KpiCard('Projets actifs', kpi != null ? '${kpi.totalProjects}' : '0',
          'au total', true, context.colors.blue, Icons.folder_outlined),
      _KpiCard('Heures loggées', kpi != null ? '${kpi.totalLoggedHours}h' : '0h',
          'cumulées', true, context.colors.purple, Icons.access_time_outlined),
      _KpiCard(
          'Projets en retard',
          kpi != null
              ? '${kpi.projectKpis.where((p) => !p.onSchedule).length}'
              : '0',
          'sur ${kpi?.projectKpis.length ?? 0}',
          (kpi?.projectKpis.where((p) => !p.onSchedule).length ?? 0) == 0,
          context.colors.red,
          Icons.warning_amber_rounded),
    ];

    return Row(
        children: cards
            .asMap()
            .entries
            .map((e) => Expanded(
                    child: Padding(
                  padding:
                      EdgeInsets.only(right: e.key < cards.length - 1 ? 8 : 0),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                        color: context.colors.bg2,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: context.colors.border, width: 0.5)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                                color: e.value.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Icon(e.value.icon,
                                color: e.value.color, size: 17)),
                        const SizedBox(height: 8),
                        Text(e.value.value,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: e.value.color)),
                        const SizedBox(height: 1),
                        Text(e.value.label,
                            style: TextStyle(
                                fontSize: 10, color: context.colors.text2)),
                        const SizedBox(height: 5),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: (e.value.isUp
                                        ? context.colors.green
                                        : context.colors.red)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16)),
                            child: Text(e.value.delta,
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: e.value.isUp
                                        ? context.colors.green
                                        : context.colors.red))),
                      ],
                    ),
                  ),
                )))
            .toList());
  }

  // ── Bar chart: تقدم كل مشروع حقيقي (ماشي بيانات شهرية وهمية) ──
  Widget _buildBarChart() {
    final projects = _kpi?.projectKpis ?? [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TAUX DE COMPLÉTION PAR PROJET',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.colors.text2,
                  letterSpacing: 0.07)),
          const SizedBox(height: 16),
          if (projects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                  child: Text('Aucun projet',
                      style: TextStyle(fontSize: 11, color: context.colors.text3))),
            )
          else
            SizedBox(
              height: 150,
              child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                minY: 0,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                          style: TextStyle(
                              fontSize: 9, color: context.colors.text2)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i >= projects.length) return const SizedBox();
                        final name = projects[i].projectName;
                        return Text(
                            name.length > 6 ? name.substring(0, 6) : name,
                            style: TextStyle(
                                fontSize: 8, color: context.colors.text2));
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                        color: context.colors.border.withOpacity(0.5),
                        strokeWidth: 0.5)),
                borderData: FlBorderData(show: false),
                barGroups: projects
                    .take(8)
                    .toList()
                    .asMap()
                    .entries
                    .map((e) => BarChartGroupData(x: e.key, barRods: [
                          BarChartRodData(
                            toY: e.value.completionRate,
                            color: e.value.onSchedule
                                ? context.colors.accent
                                : context.colors.red,
                            width: 22,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ]))
                    .toList(),
              )),
            ),
        ],
      ),
    );
  }

  // ── Table: profitabilité + heures + statut réels par projet ──
  Widget _buildScoreTable() {
    final projects = _kpi?.projectKpis ?? [];

    return Container(
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: context.colors.border, width: 0.5))),
          child: Text('RENTABILITÉ PAR PROJET',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.colors.text2,
                  letterSpacing: 0.07)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: context.colors.border, width: 0.5))),
          child: Row(children: [
            Expanded(
                flex: 2,
                child: Text('PROJET',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.colors.text2))),
            Expanded(
                child: Text('HEURES',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.colors.text2))),
            Expanded(
                child: Text('RENTAB.',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.colors.text2))),
            Expanded(
                child: Text('STATUT',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.colors.text2))),
          ]),
        ),
        if (projects.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Aucun projet',
                style: TextStyle(fontSize: 11, color: context.colors.text3)),
          ),
        ...projects.map((p) {
          final color = p.profitability >= 0 ? context.colors.green : context.colors.red;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: context.colors.border, width: 0.5))),
            child: Row(children: [
              Expanded(
                  flex: 2,
                  child: Text(p.projectName,
                      style: TextStyle(
                          fontSize: 12, color: context.colors.text1),
                      overflow: TextOverflow.ellipsis)),
              Expanded(
                  child: Text('${p.loggedHours}h',
                      style: TextStyle(
                          fontSize: 12, color: context.colors.text2))),
              Expanded(
                  child: Text('${p.profitability.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: color))),
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: (p.onSchedule ? context.colors.green : context.colors.red)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(p.onSchedule ? 'À temps' : 'Retard',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: p.onSchedule
                                  ? context.colors.green
                                  : context.colors.red),
                          textAlign: TextAlign.center))),
            ]),
          );
        }),
      ]),
    );
  }

  // ── Performance membres: vraies données via /kpi/members/{id} ──
  Widget _buildMemberPerf() {
    final projects = _kpi?.projectKpis ?? [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('PERFORMANCE MEMBRES',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: context.colors.text2,
                    letterSpacing: 0.07)),
            const Spacer(),
            if (projects.isNotEmpty)
              DropdownButton<int>(
                value: _selectedProjectId,
                underline: const SizedBox(),
                dropdownColor: context.colors.bg2,
                style: TextStyle(fontSize: 11, color: context.colors.text1),
                items: projects
                    .map((p) => DropdownMenuItem(
                        value: p.projectId,
                        child: Text(p.projectName,
                            style: const TextStyle(fontSize: 11))))
                    .toList(),
                onChanged: (id) {
                  setState(() => _selectedProjectId = id);
                  _loadMembers();
                },
              ),
          ]),
          const SizedBox(height: 14),
          if (_membersLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: context.colors.accent)),
            )
          else if (_members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                  child: Text('Aucune donnée pour ce projet',
                      style: TextStyle(fontSize: 11, color: context.colors.text3))),
            )
          else
            Row(
                children: _members.take(4).toList().asMap().entries.map((e) {
              final m = e.value;
              final color = m.overloaded
                  ? context.colors.red
                  : (m.workload > 70 ? context.colors.amber : context.colors.blue);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: e.key < _members.take(4).length - 1 ? 10 : 0),
                  child: Column(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.15), shape: BoxShape.circle),
                      child: Center(
                          child: Text(
                              m.memberName.isNotEmpty
                                  ? m.memberName
                                      .split(' ')
                                      .map((w) => w.isNotEmpty ? w[0] : '')
                                      .take(2)
                                      .join()
                                      .toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: color))),
                    ),
                    const SizedBox(height: 8),
                    Text(m.memberName,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.colors.text1),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text('${m.tasksCompleted}/${m.tasksAssigned} tâches',
                        style: TextStyle(
                            fontSize: 10, color: context.colors.text2)),
                    Text('${m.loggedHours}h loggées',
                        style: TextStyle(
                            fontSize: 10, color: context.colors.text2)),
                    const SizedBox(height: 8),
                    Text('${m.workload.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: color)),
                    Text('charge',
                        style: TextStyle(
                            fontSize: 10, color: context.colors.text2)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (m.workload / 100).clamp(0, 1),
                        backgroundColor: context.colors.bg4,
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 4,
                      ),
                    ),
                  ]),
                ),
              );
            }).toList()),
        ],
      ),
    );
  }
}

class _KpiCard {
  final String label, value, delta;
  final bool isUp;
  final Color color;
  final IconData icon;
  _KpiCard(
      this.label, this.value, this.delta, this.isUp, this.color, this.icon);
}