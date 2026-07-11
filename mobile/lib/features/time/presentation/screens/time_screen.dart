import 'package:flutter/material.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../shared/models/task_model.dart';
import '../../../../shared/models/time_log_model.dart';
import '../../../../core/utils/responsive.dart';

class TimeScreen extends StatefulWidget {
  const TimeScreen({super.key});
  @override
  State<TimeScreen> createState() => _TimeScreenState();
}

class _TimeScreenState extends State<TimeScreen> {
  // Données API
  List<ProjectModel> _projects = [];
  List<TaskModel> _tasks = [];
  List<TimeLogModel> _logs = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _success;

  // Formulaire
  ProjectModel? _selectedProject;
  TaskModel? _selectedTask;
  final _hoursCtrl = TextEditingController(text: '1');
  final _noteCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await StorageService.getToken();
      if (token != null) ApiService.setToken(token);
      final projects = await ApiService.getProjects();
      final logs = await ApiService.getMyTimeLogs();
      setState(() {
        _projects = projects;
        _logs = logs;
        _loading = false;
        // Resynchronise la selection avec la liste fraichement recuperee :
        // si le projet selectionne n'y figure plus (ex: archive entre-temps),
        // on retombe sur null plutot que de garder une valeur orpheline qui
        // ferait planter le DropdownButton.
        if (_selectedProject != null && !_projects.contains(_selectedProject)) {
          _selectedProject = null;
          _selectedTask = null;
          _tasks = [];
        }
      });
    } catch (e) {
      setState(() { _loading = false; _error = apiErrorMessage(e, fallback: 'Impossible de charger les données'); });
    }
  }

  Future<void> _loadTasksForProject(ProjectModel project) async {
    try {
      final tasks = await ApiService.getTasksByProject(project.id);
      setState(() { _tasks = tasks; _selectedTask = null; });
    } catch (e) {
      setState(() => _tasks = []);
    }
  }

  Future<void> _save() async {
    if (_selectedTask == null) {
      setState(() => _error = 'Veuillez sélectionner une tâche');
      return;
    }
    final hours = double.tryParse(_hoursCtrl.text);
    if (hours == null || hours <= 0) {
      setState(() => _error = 'Durée invalide');
      return;
    }

    setState(() { _saving = true; _error = null; _success = null; });
    try {
      await ApiService.logTime(
        taskId: _selectedTask!.id,
        hours: hours,
        date: _selectedDate.toIso8601String().substring(0, 10),
        description: _noteCtrl.text.trim(),
      );
      _noteCtrl.clear();
      _hoursCtrl.text = '1';
      await _load();
      setState(() => _success = 'Temps enregistré avec succès !');
      Future.delayed(const Duration(seconds: 3),
          () { if (mounted) setState(() => _success = null); });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e, fallback: 'Erreur lors de l\'enregistrement'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteLog(int id) async {
    try {
      await ApiService.deleteTimeLog(id);
      await _load();
    } catch (e) {
      setState(() => _error = apiErrorMessage(e, fallback: 'Impossible de supprimer cette entrée'));
    }
  }

  // Heures totales cette semaine
  int get _weekMinutes {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return _logs
        .where((l) => DateTime.parse(l.date).isAfter(monday.subtract(const Duration(days: 1))))
        .fold(0, (sum, l) => sum + l.minutes);
  }

  // Calcul des jours de la semaine pour le graphique
  List<_DayBar> get _weekBars {
    final now = DateTime.now();
    final labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: now.weekday - 1 - i));
      final dayStr = day.toIso8601String().substring(0, 10);
      final mins = _logs
          .where((l) => l.date == dayStr)
          .fold(0, (s, l) => s + l.minutes);
      return _DayBar(labels[i], mins);
    });
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
                ResponsivePanels(children: [_buildForm(), _buildWeekChart()]),
                const SizedBox(height: 14),
                _buildHistory(),
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
          Text('Suivi des temps',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.text1)),
          Text('Saisie et historique',
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

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SAISIR DU TEMPS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: context.colors.text2, letterSpacing: 0.07)),
        const SizedBox(height: 14),

        // Projet
        _label('Projet'),
        const SizedBox(height: 5),
        _dropdown<ProjectModel>(
          value: _selectedProject,
          hint: 'Sélectionner un projet',
          items: _projects,
          display: (p) => p.name,
          onChanged: (p) {
            setState(() => _selectedProject = p);
            if (p != null) _loadTasksForProject(p);
          },
        ),
        const SizedBox(height: 10),

        // Tâche
        _label('Tâche'),
        const SizedBox(height: 5),
        _dropdown<TaskModel>(
          value: _selectedTask,
          hint: _selectedProject == null ? 'Choisir un projet d\'abord' : 'Sélectionner une tâche',
          items: _tasks,
          display: (t) => t.title,
          onChanged: _selectedProject == null ? null : (t) => setState(() => _selectedTask = t),
        ),
        const SizedBox(height: 10),

        // Date + Durée
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Date'),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: ColorScheme.dark(
                          primary: context.colors.accent,
                          surface: context.colors.bg2)),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _selectedDate = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                decoration: BoxDecoration(
                    color: context.colors.bg3,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.colors.border)),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: context.colors.text2),
                  const SizedBox(width: 6),
                  Text(
                    '${_selectedDate.day.toString().padLeft(2,'0')}/'
                    '${_selectedDate.month.toString().padLeft(2,'0')}/'
                    '${_selectedDate.year}',
                    style: TextStyle(fontSize: 12, color: context.colors.text1)),
                ]),
              ),
            ),
          ])),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Durée (h)'),
              const SizedBox(height: 5),
              TextField(
                controller: _hoursCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 13, color: context.colors.text1),
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
                        borderSide: BorderSide(color: context.colors.accent, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11)),
              ),
            ],
          )),
        ]),
        const SizedBox(height: 10),

        // Note
        _label('Description (optionnel)'),
        const SizedBox(height: 5),
        TextField(
          controller: _noteCtrl,
          maxLines: 3,
          style: TextStyle(fontSize: 12, color: context.colors.text1),
          decoration: InputDecoration(
              filled: true,
              fillColor: context.colors.bg3,
              hintText: 'Ce que vous avez fait...',
              hintStyle: TextStyle(fontSize: 12, color: context.colors.text2),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.colors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.colors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.colors.accent, width: 1.5)),
              contentPadding: const EdgeInsets.all(10)),
        ),
        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_rounded, size: 16),
            label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildWeekChart() {
    final bars = _weekBars;
    final maxMins = bars.map((b) => b.minutes).fold(0, (a, b) => a > b ? a : b);
    final weekH = _weekMinutes ~/ 60;
    final weekM = _weekMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CETTE SEMAINE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: context.colors.text2, letterSpacing: 0.07)),
        const SizedBox(height: 10),
        Text(weekM == 0 ? '${weekH}h' : '${weekH}h${weekM.toString().padLeft(2,'0')}',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                color: context.colors.blue)),
        Text('cette semaine · cible 40h',
            style: TextStyle(fontSize: 11, color: context.colors.text2)),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.map((d) {
              final ratio = maxMins == 0 ? 0.0 : d.minutes / maxMins;
              final h = d.minutes ~/ 60;
              final m = d.minutes % 60;
              final label = d.minutes == 0 ? '' : (m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2,'0')}');
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (label.isNotEmpty)
                    Text(label, style: TextStyle(fontSize: 8, color: context.colors.text2)),
                  const SizedBox(height: 3),
                  Expanded(child: FractionallySizedBox(
                    heightFactor: ratio == 0 ? 0.05 : ratio,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                          color: ratio > 0 ? context.colors.accent : context.colors.bg4,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                  )),
                  const SizedBox(height: 4),
                  Text(d.label, style: TextStyle(fontSize: 10, color: context.colors.text2)),
                ]),
              ));
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildHistory() {
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
          child: Text('HISTORIQUE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: context.colors.text2, letterSpacing: 0.07)),
        ),
        if (_logs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Aucune entrée de temps',
                style: TextStyle(fontSize: 13, color: context.colors.text2)),
          ),
        ..._logs.map((log) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.colors.border, width: 0.5))),
          child: Row(children: [
            Expanded(child: Text(log.date,
                style: TextStyle(fontSize: 11, color: context.colors.text2))),
            Expanded(flex: 2, child: Text(log.projectName,
                style: TextStyle(fontSize: 11, color: context.colors.text1),
                overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Text(log.taskTitle,
                style: TextStyle(fontSize: 11, color: context.colors.text2),
                overflow: TextOverflow.ellipsis)),
            Expanded(child: Text(log.formattedHours,
                style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700, color: context.colors.blue))),
            if (log.description != null && log.description!.isNotEmpty)
              Expanded(flex: 2, child: Text(log.description!,
                  style: TextStyle(fontSize: 11, color: context.colors.text2),
                  overflow: TextOverflow.ellipsis))
            else
              const Expanded(flex: 2, child: SizedBox()),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 16, color: context.colors.text3),
              padding: EdgeInsets.zero,
              tooltip: 'Supprimer',
              onPressed: () => _deleteLog(log.id),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: TextStyle(fontSize: 11, color: context.colors.text2));
  }

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) display,
    required Function(T?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
          color: context.colors.bg3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.colors.border)),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: context.colors.bg3,
        hint: Text(hint,
            style: TextStyle(fontSize: 12, color: context.colors.text2)),
        style: TextStyle(fontSize: 12, color: context.colors.text1),
        onChanged: onChanged,
        items: items.map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(display(item), overflow: TextOverflow.ellipsis),
        )).toList(),
      ),
    );
  }
}

class _DayBar {
  final String label;
  final int minutes;
  _DayBar(this.label, this.minutes);
}