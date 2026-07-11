import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
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

class ProfitScreen extends StatefulWidget {
  const ProfitScreen({super.key});
  @override
  State<ProfitScreen> createState() => _ProfitScreenState();
}

class _ProfitScreenState extends State<ProfitScreen> {
  KpiDashboardModel? _kpi;
  List<ProjectModel> _projects = [];
  ProjectModel? _selectedProject;
  bool _loading = true;
  bool _exporting = false;
  String? _error;

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
      final projects = await ApiService.getProjects();
      setState(() { _kpi = kpi; _projects = projects; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = apiErrorMessage(e, fallback: 'Impossible de charger les données financières'); });
    }
  }

  List<ProjectKpiModel> get _visibleProjectKpis {
    if (_kpi == null) return [];
    if (_selectedProject == null) return _kpi!.projectKpis;
    return _kpi!.projectKpis
        .where((p) => p.projectId == _selectedProject!.id)
        .toList();
  }

  double get _totalProfitability {
    if (_kpi == null || _kpi!.projectKpis.isEmpty) return 0;
    return _kpi!.projectKpis
        .map((p) => p.profitability)
        .fold(0.0, (a, b) => a + b) / _kpi!.projectKpis.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTopBar(),
      Expanded(
        child: _loading
          ? Center(child: CircularProgressIndicator(color: context.colors.accent))
          : _error != null
            ? _buildError()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _buildSelectorAndExport(),
                  const SizedBox(height: 14),
                  _buildStats(),
                  const SizedBox(height: 14),
                  _buildProjectTable(),
                ]),
              ),
      ),
    ]);
  }

  Widget _buildSelectorAndExport() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
                color: context.colors.bg3,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.border)),
            child: DropdownButton<ProjectModel?>(
              value: _selectedProject,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: context.colors.bg3,
              hint: Text('Tous les projets',
                  style: TextStyle(fontSize: 12, color: context.colors.text2)),
              style: TextStyle(fontSize: 12, color: context.colors.text1),
              onChanged: (p) => setState(() => _selectedProject = p),
              items: [
                DropdownMenuItem<ProjectModel?>(
                  value: null,
                  child: Text('Tous les projets',
                      style: TextStyle(color: context.colors.text2)),
                ),
                ..._projects.map((p) => DropdownMenuItem<ProjectModel?>(
                      value: p,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _exporting ? null : _exportCsv,
          icon: _exporting
              ? const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.table_chart_outlined, size: 16),
          label: const Text('CSV / Excel'),
          style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.accent, foregroundColor: Colors.white),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _exporting ? null : _exportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
          label: const Text('PDF'),
          style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.bg3,
              foregroundColor: context.colors.text1,
              side: BorderSide(color: context.colors.border)),
        ),
      ]),
    );
  }

  List<List<dynamic>> _buildRows() {
    final rows = <List<dynamic>>[
      [_selectedProject != null
          ? 'Rapport de rentabilité - ${_selectedProject!.name}'
          : 'Rapport de rentabilité - Tous les projets'],
      ['Généré le', DateTime.now().toString()],
      [],
      ['Projet', 'Complétion (%)', 'Heures', 'Coût main d\'œuvre', 'Budget', 'Rentabilité (%)', 'Dans les délais'],
    ];
    for (final p in _visibleProjectKpis) {
      rows.add([
        p.projectName,
        p.completionRate.toStringAsFixed(1),
        p.loggedHours,
        p.laborCost?.toStringAsFixed(2) ?? 'N/A',
        p.budget?.toStringAsFixed(2) ?? 'N/A',
        p.profitability.toStringAsFixed(1),
        p.onSchedule ? 'Oui' : 'Non',
      ]);
    }
    return rows;
  }

  String get _baseFileName =>
      'rentabilite_${(_selectedProject?.name ?? 'tous').replaceAll(' ', '_').toLowerCase()}_'
      '${DateTime.now().millisecondsSinceEpoch}';

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final csvData = const ListToCsvConverter().convert(_buildRows());
      await saveAndShareBytes(
          Uint8List.fromList(utf8.encode(csvData)), '$_baseFileName.csv',
          mimeType: 'text/csv');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Rapport CSV généré et téléchargé'),
          backgroundColor: context.colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(apiErrorMessage(e, fallback: 'Erreur lors de l\'export CSV')),
          backgroundColor: context.colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final rows = _buildRows();
      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, text: '${rows.first.first}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: rows[3].map((e) => '$e').toList(),
            data: rows.skip(4).map((r) => r.map((e) => '$e').toList()).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ));
      await saveAndShareBytes(await doc.save(), '$_baseFileName.pdf', mimeType: 'application/pdf');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Rapport PDF généré et téléchargé'),
          backgroundColor: context.colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(apiErrorMessage(e, fallback: 'Erreur lors de l\'export PDF')),
          backgroundColor: context.colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          border: Border(bottom: BorderSide(color: context.colors.border, width: 0.5))),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Rentabilité',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.text1)),
          Text('Analyse financière des projets',
              style: TextStyle(fontSize: 10, color: context.colors.text2)),
        ]),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.refresh_rounded, size: 18, color: context.colors.text2),
          onPressed: _load,
        ),
      ]),
    );
  }

  Widget _buildStats() {
    final kpi = _kpi!;
    final profitSign = _totalProfitability >= 0 ? '+' : '';

    return Row(children: [
      Expanded(child: _statCard(
          Icons.folder_outlined, '${kpi.totalProjects}',
          'Projets suivis', context.colors.blue)),
      const SizedBox(width: 10),
      Expanded(child: _statCard(
          Icons.check_circle_outline, '${kpi.completedTasks}/${kpi.totalTasks}',
          'Tâches complétées', context.colors.green)),
      const SizedBox(width: 10),
      Expanded(child: _statCard(
          Icons.access_time_rounded, '${kpi.totalLoggedHours}h',
          'Heures enregistrées', context.colors.purple)),
      const SizedBox(width: 10),
      Expanded(child: _statCard(
          Icons.trending_up_rounded,
          '$profitSign${_totalProfitability.toStringAsFixed(1)}%',
          'Rentabilité moy.', _totalProfitability >= 0 ? context.colors.green : context.colors.red)),
    ]);
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: context.colors.text2)),
        ])),
      ]),
    );
  }

  Widget _buildProjectTable() {
    final projects = _visibleProjectKpis;

    return Container(
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.colors.border, width: 0.5))),
          child: Text('ANALYSE PAR PROJET',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: context.colors.text2, letterSpacing: 0.07)),
        ),
        // En-têtes
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.colors.border, width: 0.5))),
          child: Row(children: [
            Expanded(flex: 3, child: Text('PROJET',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.colors.text2))),
            Expanded(flex: 2, child: Text('COMPLÉTION',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.colors.text2))),
            Expanded(child: Text('HEURES',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.colors.text2))),
            Expanded(child: Text('RENTABILITÉ',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.colors.text2))),
            Expanded(child: Text('STATUT',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.colors.text2))),
          ]),
        ),

        if (projects.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Aucun projet disponible',
                style: TextStyle(fontSize: 13, color: context.colors.text2)),
          ),

        ...projects.map((p) {
          final profitColor = p.profitability >= 0 ? context.colors.green : context.colors.red;
          final profitSign = p.profitability >= 0 ? '+' : '';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.colors.border, width: 0.5))),
            child: Row(children: [
              // Nom projet
              Expanded(flex: 3, child: Text(p.projectName,
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600, color: context.colors.text1),
                  overflow: TextOverflow.ellipsis)),
              // Barre de complétion
              Expanded(flex: 2, child: Row(children: [
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: p.completionRate / 100,
                    backgroundColor: context.colors.bg4,
                    valueColor: AlwaysStoppedAnimation(context.colors.accent),
                    minHeight: 5,
                  ),
                )),
                const SizedBox(width: 6),
                Text('${p.completionRate.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w700, color: context.colors.accent)),
              ])),
              // Heures
              Expanded(child: Text('${p.loggedHours}h',
                  style: TextStyle(fontSize: 11, color: context.colors.text2))),
              // Rentabilité
              Expanded(child: Text(
                '$profitSign${p.profitability.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700, color: profitColor),
              )),
              // Statut planning
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                    color: p.onSchedule
                        ? context.colors.green.withOpacity(0.1)
                        : context.colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(p.onSchedule ? 'Dans les délais' : 'En retard',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                        color: p.onSchedule ? context.colors.green : context.colors.amber)),
              )),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildError() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bar_chart_outlined, size: 48, color: context.colors.text3),
        const SizedBox(height: 16),
        Text(_error!, style: TextStyle(fontSize: 13, color: context.colors.text2)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Réessayer'),
          style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.accent, foregroundColor: Colors.white),
        ),
      ],
    ));
  }
}