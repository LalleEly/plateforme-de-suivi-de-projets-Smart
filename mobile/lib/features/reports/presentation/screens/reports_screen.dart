import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/save_bytes.dart';
import '../../../../shared/models/kpi_model.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../core/utils/responsive.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  KpiDashboardModel? _kpi;
  List<ProjectModel> _projects = [];
  bool _loading = true;
  bool _generating = false;
  String? _error;
  String? _success;
  String _userRole = '';

  String _reportType = 'KPI Global';
  ProjectModel? _selectedProject;

  bool get _canImport => _userRole == 'MANAGER' || _userRole == 'CHEF_PROJET';

  final _reportTypes = [
    'KPI Global',
    'Suivi des temps',
    'Analyse par projet',
    'Performance équipe',
  ];

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
      final role = await StorageService.getUserRole();
      final kpi = await ApiService.getDashboard();
      final projects = await ApiService.getProjects();
      setState(() {
        _kpi = kpi;
        _projects = projects;
        _userRole = role ?? '';
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = apiErrorMessage(e, fallback: 'Impossible de charger les données'); });
    }
  }

  Future<List<List<dynamic>>?> _buildRows() async {
    if (_reportType == 'Performance équipe' && _selectedProject == null) {
      setState(() {
        _error = 'Sélectionnez un projet pour ce type de rapport';
        _success = null;
      });
      return null;
    }
    switch (_reportType) {
      case 'KPI Global':
        return _buildKpiGlobalRows();
      case 'Suivi des temps':
        return _buildTimeRows();
      case 'Analyse par projet':
        return _buildProjectRows();
      case 'Performance équipe':
        return await _buildTeamRows();
      default:
        return [];
    }
  }

  String get _baseFileName =>
      'rapport_${_reportType.replaceAll(' ', '_').toLowerCase()}_'
      '${DateTime.now().millisecondsSinceEpoch}';

  // ── Export CSV (ouvre nativement dans Excel / Google Sheets) ──────────
  Future<void> _exportCsv() async {
    if (_kpi == null) return;
    setState(() { _generating = true; _success = null; _error = null; });
    try {
      final rows = await _buildRows();
      if (rows == null) {
        setState(() => _generating = false);
        return;
      }
      final csvData = const ListToCsvConverter().convert(rows);
      await saveAndShareBytes(
          Uint8List.fromList(utf8.encode(csvData)), '$_baseFileName.csv',
          mimeType: 'text/csv');
      setState(() { _generating = false; _success = 'Rapport CSV généré et téléchargé'; });
    } catch (e) {
      setState(() {
        _generating = false;
        _error = apiErrorMessage(e, fallback: 'Erreur lors de l\'export CSV : $e');
      });
    }
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() { _success = null; _error = null; });
    });
  }

  // ── Export PDF réel (pdf + printing, fonctionne sur web/desktop/mobile) ──
  Future<void> _exportPdf() async {
    if (_kpi == null) return;
    setState(() { _generating = true; _success = null; _error = null; });
    try {
      final rows = await _buildRows();
      if (rows == null) {
        setState(() => _generating = false);
        return;
      }
      final bytes = await _buildPdfBytes(rows);
      await saveAndShareBytes(bytes, '$_baseFileName.pdf', mimeType: 'application/pdf');
      setState(() { _generating = false; _success = 'Rapport PDF généré et téléchargé'; });
    } catch (e) {
      setState(() {
        _generating = false;
        _error = apiErrorMessage(e, fallback: 'Erreur lors de l\'export PDF : $e');
      });
    }
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() { _success = null; _error = null; });
    });
  }

  // Rend generiquement la meme structure de lignes (titre, sous-titres, tableaux)
  // pour n'importe lequel des 4 types de rapport, sans logique specifique par type.
  Future<Uint8List> _buildPdfBytes(List<List<dynamic>> rows) async {
    final doc = pw.Document();
    final widgets = <pw.Widget>[];
    List<List<String>> buffer = [];
    String? title;

    void flush() {
      if (buffer.length >= 2) {
        widgets.add(pw.TableHelper.fromTextArray(
          headers: buffer.first,
          data: buffer.skip(1).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerLeft,
        ));
        widgets.add(pw.SizedBox(height: 12));
      } else if (buffer.length == 1) {
        widgets.add(pw.Text(buffer.first.join(' : '), style: const pw.TextStyle(fontSize: 10)));
        widgets.add(pw.SizedBox(height: 6));
      }
      buffer = [];
    }

    for (final row in rows) {
      if (row.isEmpty) {
        flush();
        continue;
      }
      final cells = row.map((e) => '$e').toList();
      if (title == null) {
        title = cells.join(' ');
        continue;
      }
      if (cells.length == 1) {
        flush();
        widgets.add(pw.Header(level: 1, text: cells.first));
        continue;
      }
      buffer.add(cells);
    }
    flush();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, text: title ?? 'Rapport'),
          pw.SizedBox(height: 12),
          ...widgets,
        ],
      ),
    );
    return doc.save();
  }

  List<List<dynamic>> _buildKpiGlobalRows() {
    final kpi = _kpi!;
    final rows = <List<dynamic>>[
      ['Rapport KPI Global - ProjectFlow'],
      ['Généré le', DateTime.now().toString()],
      [],
      ['Métrique', 'Valeur'],
      ['Projets totaux', kpi.totalProjects],
      ['Tâches totales', kpi.totalTasks],
      ['Tâches complétées', kpi.completedTasks],
      ['Taux de complétion (%)', kpi.completionRate.toStringAsFixed(1)],
      ['Heures enregistrées', kpi.totalLoggedHours],
      [],
      ['Détail par projet'],
      ['Projet', 'Complétion (%)', 'Heures', 'Rentabilité (%)', 'À temps'],
    ];
    for (final p in kpi.projectKpis) {
      rows.add([
        p.projectName,
        p.completionRate.toStringAsFixed(1),
        p.loggedHours,
        p.profitability.toStringAsFixed(1),
        p.onSchedule ? 'Oui' : 'Non',
      ]);
    }
    return rows;
  }

  List<List<dynamic>> _buildTimeRows() {
    final kpi = _kpi!;
    final rows = <List<dynamic>>[
      ['Rapport Suivi des temps - ProjectFlow'],
      ['Généré le', DateTime.now().toString()],
      [],
      ['Projet', 'Heures enregistrées', 'Complétion (%)'],
    ];
    final source = _selectedProject != null
        ? kpi.projectKpis.where((p) => p.projectId == _selectedProject!.id)
        : kpi.projectKpis;
    for (final p in source) {
      rows.add([p.projectName, p.loggedHours, p.completionRate.toStringAsFixed(1)]);
    }
    rows.add([]);
    rows.add(['Total heures', source.fold<int>(0, (sum, p) => sum + p.loggedHours)]);
    return rows;
  }

  List<List<dynamic>> _buildProjectRows() {
    final kpi = _kpi!;
    final rows = <List<dynamic>>[
      ['Rapport Analyse par projet - ProjectFlow'],
      ['Généré le', DateTime.now().toString()],
      [],
      ['Projet', 'Statut', 'Membres', 'Tâches', 'Complétion (%)',
        'Heures', 'Rentabilité (%)', 'À temps'],
    ];
    final projectsToShow = _selectedProject != null
        ? _projects.where((p) => p.id == _selectedProject!.id)
        : _projects;
    for (final proj in projectsToShow) {
      final k = kpi.projectKpis.firstWhere(
        (p) => p.projectId == proj.id,
        orElse: () => ProjectKpiModel(
            projectId: proj.id,
            projectName: proj.name,
            totalTasks: 0,
            completedTasks: 0,
            completionRate: 0,
            loggedHours: 0,
            profitability: 0,
            onSchedule: true),
      );
      rows.add([
        proj.name,
        proj.status,
        proj.memberCount,
        proj.taskCount,
        k.completionRate.toStringAsFixed(1),
        k.loggedHours,
        k.profitability.toStringAsFixed(1),
        k.onSchedule ? 'Oui' : 'Non',
      ]);
    }
    return rows;
  }

  Future<List<List<dynamic>>> _buildTeamRows() async {
    final members = await ApiService.getMemberKpis(_selectedProject!.id);
    final rows = <List<dynamic>>[
      ['Rapport Performance équipe - ${_selectedProject!.name}'],
      ['Généré le', DateTime.now().toString()],
      [],
      ['Membre', 'Tâches assignées', 'Tâches terminées',
        'Heures loggées', 'Charge (%)', 'Efficacité (%)', 'Surchargé'],
    ];
    for (final m in members) {
      rows.add([
        m.memberName,
        m.tasksAssigned,
        m.tasksCompleted,
        m.loggedHours,
        m.workload.toStringAsFixed(1),
        m.efficiency.toStringAsFixed(1),
        m.overloaded ? 'Oui' : 'Non',
      ]);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTopBar(),
      Expanded(
        child: _loading
          ? Center(child: CircularProgressIndicator(color: context.colors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                if (_error != null) _buildBanner(_error!, context.colors.red, Icons.error_outline),
                if (_success != null) _buildBanner(_success!, context.colors.green, Icons.check_circle_outline),
                ResponsivePanels(
                    children: [_buildGenerateForm(), _buildSummary()]),
              ]),
            ),
      ),
    ]);
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          border: Border(bottom: BorderSide(color: context.colors.border, width: 0.5))),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Rapports',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.text1)),
          Text('Génération et export CSV / PDF',
              style: TextStyle(fontSize: 10, color: context.colors.text2)),
        ]),
        const Spacer(),
        if (_canImport) ...[
          OutlinedButton.icon(
            onPressed: _showImportDialog,
            icon: const Icon(Icons.file_upload_outlined, size: 14),
            label: const Text('Importer (CSV)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.text1,
              side: BorderSide(color: context.colors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          icon: Icon(Icons.refresh_rounded, size: 18, color: context.colors.text2),
          onPressed: _load,
        ),
      ]),
    );
  }

  Widget _buildBanner(String msg, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: TextStyle(fontSize: 12, color: color))),
      ]),
    );
  }

  Widget _buildGenerateForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GÉNÉRER UN RAPPORT',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: context.colors.text2, letterSpacing: 0.07)),
        const SizedBox(height: 16),

        Text('Type de rapport',
            style: TextStyle(fontSize: 11, color: context.colors.text2)),
        const SizedBox(height: 6),
        ...(_reportTypes.map((type) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() => _reportType = type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: _reportType == type
                      ? context.colors.accent.withOpacity(0.12)
                      : context.colors.bg3,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _reportType == type
                          ? context.colors.accent
                          : context.colors.border)),
              child: Row(children: [
                Icon(_typeIcon(type),
                    size: 16,
                    color: _reportType == type ? context.colors.accent : context.colors.text2),
                const SizedBox(width: 10),
                Text(type,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _reportType == type
                            ? context.colors.accentLight
                            : context.colors.text1)),
                const Spacer(),
                if (_reportType == type)
                  Icon(Icons.check_circle_rounded,
                      size: 16, color: context.colors.accent),
              ]),
            ),
          ),
        ))),

        const SizedBox(height: 4),

        Text(
          _reportType == 'Performance équipe'
              ? 'Projet (obligatoire pour ce rapport)'
              : 'Projet (optionnel)',
          style: TextStyle(fontSize: 11, color: context.colors.text2),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
              color: context.colors.bg3,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colors.border)),
          child: DropdownButton<ProjectModel>(
            value: _selectedProject,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: context.colors.bg3,
            hint: Text('Tous les projets',
                style: TextStyle(fontSize: 12, color: context.colors.text2)),
            style: TextStyle(fontSize: 12, color: context.colors.text1),
            onChanged: (p) => setState(() => _selectedProject = p),
            items: [
              const DropdownMenuItem<ProjectModel>(
                value: null,
                child: Text('Tous les projets'),
              ),
              ..._projects.map((p) => DropdownMenuItem<ProjectModel>(
                value: p,
                child: Text(p.name, overflow: TextOverflow.ellipsis),
              )),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _generating ? null : _exportCsv,
              icon: _generating
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.table_chart_outlined, size: 16),
              label: const Text('CSV / Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _generating ? null : _exportPdf,
              icon: _generating
                  ? SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(color: context.colors.text1, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_outlined, size: 16),
              label: const Text('PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.bg3,
                foregroundColor: context.colors.text1,
                side: BorderSide(color: context.colors.border),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildSummary() {
    if (_kpi == null) return const SizedBox();
    final kpi = _kpi!;

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: context.colors.bg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.colors.border, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('RÉSUMÉ DES DONNÉES',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: context.colors.text2, letterSpacing: 0.07)),
          const SizedBox(height: 14),
          _kpiRow(Icons.folder_outlined, 'Projets totaux',
              '${kpi.totalProjects}', context.colors.blue),
          _kpiRow(Icons.check_box_outlined, 'Tâches complétées',
              '${kpi.completedTasks} / ${kpi.totalTasks}', context.colors.green),
          _kpiRow(Icons.percent_rounded, 'Taux de complétion',
              '${kpi.completionRate.toStringAsFixed(1)}%', context.colors.accent),
          _kpiRow(Icons.access_time_rounded, 'Heures enregistrées',
              '${kpi.totalLoggedHours}h', context.colors.purple),
        ]),
      ),
      const SizedBox(height: 12),
      if (kpi.projectKpis.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: context.colors.bg2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.colors.border, width: 0.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PAR PROJET',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: context.colors.text2, letterSpacing: 0.07)),
            const SizedBox(height: 14),
            ...kpi.projectKpis.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.projectName,
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600, color: context.colors.text1),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: p.completionRate / 100,
                      backgroundColor: context.colors.bg4,
                      valueColor: AlwaysStoppedAnimation(context.colors.accent),
                      minHeight: 4,
                    ),
                  ),
                ])),
                const SizedBox(width: 10),
                Text('${p.completionRate.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w700, color: context.colors.accent)),
              ]),
            )),
          ]),
        ),
    ]);
  }

  Widget _kpiRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 12, color: context.colors.text2))),
        Text(value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  // Import CSV : colonnes "title,description,priority" (description et priority
  // optionnelles ; priority parmi LOW/MEDIUM/HIGH/CRITICAL, MEDIUM par defaut).
  // La premiere ligne est traitee comme un en-tete si sa 1ere cellule vaut "title".
  // Reserve a MANAGER/CHEF_PROJET (le backend restreint deja CHEF_PROJET a ses
  // propres projets via checkManageRights, donc _projects est deja bien filtree).
  void _showImportDialog() {
    String? selectedProjectId = _projects.isNotEmpty ? '${_projects.first.id}' : null;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: context.colors.bg2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: context.colors.border)),
          title: Text('Importer des tâches (CSV)',
              style: TextStyle(color: context.colors.text1, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Format attendu : colonnes "title,description,priority" '
                  '(description et priority optionnelles ; priority parmi '
                  'LOW, MEDIUM, HIGH, CRITICAL).',
                  style: TextStyle(fontSize: 11, color: context.colors.text2),
                ),
                const SizedBox(height: 14),
                Text('Projet cible',
                    style: TextStyle(fontSize: 11, color: context.colors.text2)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                      color: context.colors.bg3,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.colors.border)),
                  child: DropdownButton<String>(
                    value: selectedProjectId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: context.colors.bg3,
                    hint: Text('Sélectionner un projet',
                        style: TextStyle(fontSize: 12, color: context.colors.text2)),
                    style: TextStyle(fontSize: 12, color: context.colors.text1),
                    items: _projects
                        .map((p) => DropdownMenuItem(
                              value: '${p.id}',
                              child: Text(p.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setS(() => selectedProjectId = v),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: selectedProjectId == null
                        ? null
                        : () => _pickAndImportCsv(int.parse(selectedProjectId!)),
                    icon: const Icon(Icons.folder_open_outlined, size: 16),
                    label: const Text('Choisir un fichier CSV...'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.text1,
                        side: BorderSide(color: context.colors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer', style: TextStyle(color: context.colors.text2))),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndImportCsv(int projectId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final content = utf8.decode(bytes, allowMalformed: true);
    final rows = const CsvToListConverter(eol: '\n').convert(content, shouldParseNumbers: false);
    if (rows.isEmpty) return;

    var dataRows = rows;
    if (rows.first.isNotEmpty &&
        '${rows.first[0]}'.trim().toLowerCase() == 'title') {
      dataRows = rows.skip(1).toList();
    }

    const validPriorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
    int success = 0;
    int failed = 0;
    for (final row in dataRows) {
      if (row.isEmpty) continue;
      final title = '${row[0]}'.trim();
      if (title.isEmpty) continue;
      final description = row.length > 1 ? '${row[1]}'.trim() : '';
      var priority = row.length > 2 ? '${row[2]}'.trim().toUpperCase() : 'MEDIUM';
      if (!validPriorities.contains(priority)) priority = 'MEDIUM';
      try {
        await ApiService.createTask(title, description, projectId, priority);
        success++;
      } catch (_) {
        failed++;
      }
    }

    if (mounted) Navigator.pop(context);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(failed == 0
            ? '$success tâche(s) importée(s) avec succès'
            : '$success tâche(s) importée(s), $failed échec(s)'),
        backgroundColor: failed == 0 ? context.colors.green : context.colors.amber,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'KPI Global': return Icons.bar_chart_rounded;
      case 'Suivi des temps': return Icons.access_time_rounded;
      case 'Analyse par projet': return Icons.folder_outlined;
      case 'Performance équipe': return Icons.people_outline;
      default: return Icons.description_outlined;
    }
  }
}