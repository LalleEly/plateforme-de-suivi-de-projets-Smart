import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/models/comment_model.dart';
import '../../../../shared/models/member_model.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../shared/models/task_model.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<TaskModel> _tasks = [];
  List<ProjectModel> _projects = [];
  bool _loading = true;
  String? _error;
  String _userRole = '';
  String _filter = 'Tous';

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isManagerOrChef => _userRole == 'MANAGER' || _userRole == 'CHEF_PROJET';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await StorageService.getToken();
      final role = await StorageService.getUserRole();
      if (token != null) ApiService.setToken(token);
      _userRole = role ?? '';
      final projects = await ApiService.getProjects();

      List<TaskModel> tasks;
      if (_isManagerOrChef) {
        // MANAGER/CHEF_PROJET : toutes les tâches de leurs projets visibles
        // (pas seulement celles qui leur sont assignées, sinon une tâche
        // créée pour quelqu'un d'autre n'apparaîtrait jamais ici).
        final merged = <int, TaskModel>{};
        for (final project in projects) {
          try {
            final projectTasks = await ApiService.getTasksByProject(project.id);
            for (final t in projectTasks) {
              merged[t.id] = t;
            }
          } catch (_) {
            continue;
          }
        }
        if (_userRole == 'CHEF_PROJET') {
          // En plus des projets qu'il dirige/dont il est membre, un CHEF_PROJET
          // peut recevoir une tâche assignée par le MANAGER dans un projet où
          // il n'est ni owner ni membre formel — sans ça elle n'apparaît jamais.
          try {
            final myTasks = await ApiService.getMyTasks();
            for (final t in myTasks) {
              merged[t.id] = t;
            }
          } catch (_) {}
        }
        tasks = merged.values.toList();
      } else {
        tasks = await ApiService.getMyTasks();
      }

      setState(() {
        _tasks = tasks;
        _projects = projects;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = apiErrorMessage(e, fallback: 'Impossible de charger les tâches');
      });
    }
  }

  List<TaskModel> get _filtered {
    if (_filter == 'Tous') return _tasks;
    if (_filter == 'En cours') {
      return _tasks.where((t) => t.status == 'IN_PROGRESS').toList();
    }
    if (_filter == 'À faire') {
      return _tasks
          .where((t) => t.status == 'TODO' || t.status == 'BACKLOG')
          .toList();
    }
    if (_filter == 'Terminées') {
      return _tasks.where((t) => t.status == 'DONE').toList();
    }
    return _tasks;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DONE':
        return context.colors.green;
      case 'IN_PROGRESS':
        return context.colors.blue;
      case 'IN_REVIEW':
        return context.colors.purple;
      case 'TODO':
        return context.colors.amber;
      case 'BACKLOG':
        return context.colors.text2;
      default:
        return context.colors.red;
    }
  }

  String _statusLabel(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'DONE':
        return l10n.statusDone;
      case 'IN_PROGRESS':
        return l10n.statusInProgressLabel;
      case 'IN_REVIEW':
        return l10n.statusInReview;
      case 'TODO':
        return l10n.statusTodo;
      case 'BACKLOG':
        return l10n.statusBacklog;
      default:
        return l10n.statusCancelled;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'CRITICAL':
        return context.colors.red;
      case 'HIGH':
        return context.colors.amber;
      case 'MEDIUM':
        return context.colors.blue;
      default:
        return context.colors.text2;
    }
  }

  Future<void> _updateStatus(TaskModel task, String newStatus) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiService.updateTaskStatus(task.id, newStatus);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.statusUpdatedSnack(_statusLabel(newStatus))),
          backgroundColor: context.colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(apiErrorMessage(e, fallback: 'Impossible de changer le statut')),
          backgroundColor: context.colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _filterLabel(String f) {
    final l10n = AppLocalizations.of(context)!;
    switch (f) {
      case 'En cours':
        return l10n.filterInProgress;
      case 'À faire':
        return l10n.filterTodo;
      case 'Terminées':
        return l10n.filterDone;
      default:
        return l10n.filterAll;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(children: [
      _buildTopBar(),
      Expanded(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(color: context.colors.accent))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: context.colors.text3),
                        const SizedBox(height: 12),
                        Text(_error!, style: TextStyle(color: context.colors.text2)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: context.colors.accent, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                onRefresh: _load,
                color: context.colors.accent,
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_box_outlined,
                                size: 56, color: context.colors.text2),
                            const SizedBox(height: 12),
                            Text(l10n.noTasksFound,
                                style: TextStyle(
                                    color: context.colors.text2, fontSize: 14)),
                            const SizedBox(height: 8),
                            if (_userRole == 'MANAGER' || _userRole == 'CHEF_PROJET')
                              ElevatedButton.icon(
                                onPressed: _showCreateDialog,
                                icon: const Icon(Icons.add, size: 14),
                                label: Text(l10n.createTaskButton),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: context.colors.accent),
                              ),
                          ],
                        ),
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(responsiveValue(context, mobile: 12, desktop: 16)),
                        children: [
                          _buildSection(
                              l10n.filterInProgress,
                              _filtered
                                  .where((t) => t.status == 'IN_PROGRESS')
                                  .toList(),
                              context.colors.blue),
                          _buildSection(
                              l10n.sectionInReview,
                              _filtered
                                  .where((t) => t.status == 'IN_REVIEW')
                                  .toList(),
                              context.colors.purple),
                          _buildSection(
                              l10n.filterTodo,
                              _filtered
                                  .where((t) => t.status == 'TODO')
                                  .toList(),
                              context.colors.amber),
                          _buildSection(
                              l10n.sectionBacklog,
                              _filtered
                                  .where((t) => t.status == 'BACKLOG')
                                  .toList(),
                              context.colors.text2),
                          _buildSection(
                              l10n.filterDone,
                              _filtered
                                  .where((t) => t.status == 'DONE')
                                  .toList(),
                              context.colors.green),
                        ],
                      ),
              ),
      ),
    ]);
  }

  Widget _buildTopBar() {
    final l10n = AppLocalizations.of(context)!;
    final mobile = isMobileWidth(context);
    final canManage = _userRole == 'MANAGER' || _userRole == 'CHEF_PROJET';

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.myTasksTitle,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.colors.text1)),
        Text(l10n.tasksAssignedCount(_tasks.length),
            style: TextStyle(fontSize: 10, color: context.colors.text2)),
      ],
    );

    final filterChips = Row(
      mainAxisSize: MainAxisSize.min,
      children: ['Tous', 'En cours', 'À faire', 'Terminées'].map((f) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: _filter == f ? context.colors.accent : context.colors.bg3,
                    border: Border.all(
                        color: _filter == f
                            ? context.colors.accent
                            : context.colors.border),
                    borderRadius: BorderRadius.circular(7)),
                child: Text(_filterLabel(f),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color:
                            _filter == f ? Colors.white : context.colors.text2)),
              ),
            ),
          )).toList(),
    );

    final importButton = OutlinedButton.icon(
      onPressed: _showImportDialog,
      icon: const Icon(Icons.file_upload_outlined, size: 14),
      label: const Text('Importer (CSV)'),
      style: OutlinedButton.styleFrom(
        foregroundColor: context.colors.text1,
        side: BorderSide(color: context.colors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7)),
      ),
    );

    final addButton = ElevatedButton.icon(
      onPressed: _showCreateDialog,
      icon: const Icon(Icons.add, size: 14),
      label: Text(mobile ? l10n.create : l10n.newTaskButton),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.colors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7)),
      ),
    );

    if (mobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: context.colors.bg2,
            border: Border(
                bottom: BorderSide(color: context.colors.border, width: 0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: title),
            if (canManage) addButton,
          ]),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              filterChips,
              if (canManage) ...[const SizedBox(width: 6), importButton],
            ]),
          ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          border:
              Border(bottom: BorderSide(color: context.colors.border, width: 0.5))),
      child: Row(children: [
        title,
        const Spacer(),
        filterChips,
        if (canManage) ...[
          importButton,
          const SizedBox(width: 8),
          addButton,
        ],
      ]),
    );
  }

  Widget _buildSection(String title, List<TaskModel> tasks, Color color) {
    if (tasks.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(children: [
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(title,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color))),
            const SizedBox(width: 8),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: context.colors.bg4,
                    borderRadius: BorderRadius.circular(8)),
                child: Text('${tasks.length}',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.colors.text2))),
          ]),
        ),
        ...tasks.map(_buildTaskCard),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor(task.status);
    final priorityColor = _priorityColor(task.priority);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(responsiveValue(context, mobile: 10, desktop: 12)),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colors.text1)),
                Row(children: [
                  Text(task.projectName,
                      style: TextStyle(
                          fontSize: 11, color: context.colors.text2)),
                  if (task.assigneeName != null) ...[
                    Text(' · ', style: TextStyle(color: context.colors.text2)),
                    Text(task.assigneeName!,
                        style: TextStyle(
                            fontSize: 11, color: context.colors.text2)),
                  ],
                ]),
              ],
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showStatusMenu(task),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Text(_statusLabel(task.status),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 14, color: statusColor),
                ]),
              ),
            ),
            if (_userRole == 'MANAGER' || (_userRole == 'CHEF_PROJET' && _projects.any((p) => p.id == task.projectId))) ...[
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                color: context.colors.bg3,
                icon: Icon(Icons.more_vert,
                    size: 16, color: context.colors.text2),
                onSelected: (v) {
                  if (v == 'edit') {
                    _showEditTaskDialog(task);
                  } else if (v == 'archive') {
                    _archiveTask(task);
                  } else if (v == 'delete') {
                    _confirmDeleteTask(task);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined,
                            size: 14, color: context.colors.text1),
                        const SizedBox(width: 8),
                        Text(l10n.editMenuItem,
                            style: TextStyle(
                                fontSize: 12, color: context.colors.text1)),
                      ])),
                  PopupMenuItem(
                      value: 'archive',
                      child: Row(children: [
                        Icon(Icons.archive_outlined,
                            size: 14, color: context.colors.text1),
                        const SizedBox(width: 8),
                        Text('Archiver',
                            style: TextStyle(
                                fontSize: 12, color: context.colors.text1)),
                      ])),
                  PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 14, color: context.colors.red),
                        const SizedBox(width: 8),
                        Text('Supprimer',
                            style: TextStyle(
                                fontSize: 12, color: context.colors.red)),
                      ])),
                ],
              ),
            ],
          ]),
          const SizedBox(height: 8),
          Row(children: [
            if (task.storyPoints != null) ...[
              _chip(Icons.star_outline, '${task.storyPoints} pts',
                  context.colors.text2),
              const SizedBox(width: 10),
            ],
            _chip(
                Icons.access_time,
                '${task.loggedHours}h / '
                '${task.estimatedHours ?? 0}h',
                context.colors.text2),
            const SizedBox(width: 10),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(task.priority,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: priorityColor))),
            if (task.overdue) ...[
              const SizedBox(width: 10),
              _chip(Icons.warning_amber_rounded, l10n.overdueChip, context.colors.red),
            ],
            const Spacer(),
            GestureDetector(
              onTap: () => _showComments(task),
              child: _chip(Icons.chat_bubble_outline, 'Commentaires', context.colors.accent),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 10, color: color)),
    ]);
  }

  void _showComments(TaskModel task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _CommentsSheet(task: task),
    );
  }

  void _showStatusMenu(TaskModel task) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(l10n.changeStatusTitle,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: context.colors.text1)),
            const SizedBox(height: 16),
            ...['BACKLOG', 'TODO', 'IN_PROGRESS', 'IN_REVIEW', 'DONE']
                .map((s) => ListTile(
                      leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: _statusColor(s).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(
                              s == 'DONE'
                                  ? Icons.check_circle_outline
                                  : s == 'IN_PROGRESS'
                                      ? Icons.play_circle_outline
                                      : Icons.circle_outlined,
                              size: 16,
                              color: _statusColor(s))),
                      title: Text(_statusLabel(s),
                          style: TextStyle(
                              color: context.colors.text1, fontSize: 13)),
                      trailing: task.status == s
                          ? Icon(Icons.check, color: context.colors.accent, size: 16)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _updateStatus(task, s);
                      },
                    )),
            ],
          ),
        ),
      ),
    );
  }

  // Import CSV : colonnes "title,description,priority" (description et priority
  // optionnelles ; priority parmi LOW/MEDIUM/HIGH/CRITICAL, MEDIUM par defaut).
  // La premiere ligne est traitee comme un en-tete si sa 1ere cellule vaut "title".
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

  void _showCreateDialog() {
    final l10n = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedProjectId;
    String priority = 'MEDIUM';
    List<MemberModel> assigneeOptions = [];
    int? selectedAssigneeId;

    Future<void> loadAssigneeOptions(
        String projectId, void Function(void Function()) setS) async {
      List<MemberModel> members = [];
      try {
        members = await ApiService.getProjectMembers(int.parse(projectId));
      } catch (_) {}
      setS(() {
        assigneeOptions = members;
        selectedAssigneeId = null;
      });
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: context.colors.bg2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: context.colors.border)),
          title: Text(l10n.newTaskDialogTitle,
              style: TextStyle(
                  color: context.colors.text1, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(l10n.fieldTitle, titleCtrl),
                const SizedBox(height: 10),
                _dialogField(l10n.fieldDescription, descCtrl),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.fieldProject,
                        style: TextStyle(fontSize: 11, color: context.colors.text2)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                          color: context.colors.bg3,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.colors.border)),
                      child: DropdownButton<String>(
                        value: selectedProjectId,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: context.colors.bg3,
                        hint: Text(l10n.selectProjectHint,
                            style: TextStyle(
                                fontSize: 12, color: context.colors.text2)),
                        style: TextStyle(
                            fontSize: 12, color: context.colors.text1),
                        items: _projects
                            .map((p) => DropdownMenuItem(
                                  value: '${p.id}',
                                  child: Text(p.name,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setS(() => selectedProjectId = v);
                          if (v != null) loadAssigneeOptions(v, setS);
                        },
                      ),
                    ),
                  ],
                ),
                if (selectedProjectId != null) ...[
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigné à',
                          style: TextStyle(fontSize: 11, color: context.colors.text2)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                            color: context.colors.bg3,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.colors.border)),
                        child: DropdownButton<int>(
                          value: selectedAssigneeId,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: context.colors.bg3,
                          hint: Text(
                              assigneeOptions.isEmpty
                                  ? 'Aucun membre sur ce projet'
                                  : 'Non assigné',
                              style: TextStyle(
                                  fontSize: 12, color: context.colors.text2)),
                          style: TextStyle(
                              fontSize: 12, color: context.colors.text1),
                          items: assigneeOptions
                              .map((m) => DropdownMenuItem(
                                    value: m.id,
                                    child: Text(m.fullName,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) => setS(() => selectedAssigneeId = v),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.fieldPriority,
                        style: TextStyle(fontSize: 11, color: context.colors.text2)),
                    const SizedBox(height: 4),
                    Row(
                        children: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
                            .map((p) => Expanded(
                                    child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: GestureDetector(
                                    onTap: () => setS(() => priority = p),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      decoration: BoxDecoration(
                                          color: priority == p
                                              ? _priorityColor(p)
                                                  .withOpacity(0.2)
                                              : context.colors.bg3,
                                          border: Border.all(
                                              color: priority == p
                                                  ? _priorityColor(p)
                                                  : context.colors.border),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Text(p,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: priority == p
                                                  ? _priorityColor(p)
                                                  : context.colors.text2)),
                                    ),
                                  ),
                                )))
                            .toList()),
                  ],
                ),
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
                  if (titleCtrl.text.isEmpty || selectedProjectId == null) {
                    return;
                  }
                  try {
                    await ApiService.createTask(titleCtrl.text, descCtrl.text,
                        int.parse(selectedProjectId!), priority,
                        assigneeId: selectedAssigneeId);
                    if (mounted) Navigator.pop(context);
                    _load();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(l10n.taskCreatedSnack),
                        backgroundColor: context.colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(apiErrorMessage(e, fallback: 'Impossible de créer la tâche')),
                        backgroundColor: context.colors.red,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  }
                },
                style:
                    ElevatedButton.styleFrom(backgroundColor: context.colors.accent),
                child: Text(l10n.create)),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(TaskModel task) {
    final l10n = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController(text: task.title);
    final descCtrl = TextEditingController(text: task.description ?? '');
    int? selectedAssigneeId = task.assigneeId;
    final assigneeOptionsFuture = ApiService.getProjectMembers(task.projectId);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
        backgroundColor: context.colors.bg2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: context.colors.border)),
        title: Text(l10n.editTaskDialogTitle,
            style:
                TextStyle(color: context.colors.text1, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(l10n.fieldTitle, titleCtrl),
              const SizedBox(height: 10),
              _dialogField(l10n.fieldDescription, descCtrl),
              const SizedBox(height: 10),
              FutureBuilder<List<MemberModel>>(
                future: assigneeOptionsFuture,
                builder: (context, snapshot) {
                  final assigneeOptions = snapshot.data ?? [];
                  // Tant que la liste charge (ou si l'assigné actuel n'y figure
                  // plus), la valeur affichée doit rester parmi les items
                  // presents, sinon DropdownButton lève une assertion.
                  final dropdownValue = assigneeOptions.any((m) => m.id == selectedAssigneeId)
                      ? selectedAssigneeId
                      : null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigné à',
                          style: TextStyle(fontSize: 11, color: context.colors.text2)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                            color: context.colors.bg3,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.colors.border)),
                        child: DropdownButton<int?>(
                          value: dropdownValue,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: context.colors.bg3,
                          hint: Text('Non assigné',
                              style: TextStyle(fontSize: 12, color: context.colors.text2)),
                          style: TextStyle(fontSize: 12, color: context.colors.text1),
                          items: [
                            const DropdownMenuItem<int?>(
                                value: null, child: Text('Non assigné')),
                            ...assigneeOptions.map((m) => DropdownMenuItem<int?>(
                                  value: m.id,
                                  child: Text(m.fullName, overflow: TextOverflow.ellipsis),
                                )),
                          ],
                          onChanged: (v) => setS(() => selectedAssigneeId = v),
                        ),
                      ),
                    ],
                  );
                },
              ),
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
                if (titleCtrl.text.isEmpty) return;
                try {
                  await ApiService.updateTask(task.id,
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      priority: task.priority,
                      assigneeId: selectedAssigneeId,
                      storyPoints: task.storyPoints,
                      estimatedHours: task.estimatedHours);
                  if (mounted) Navigator.pop(context);
                  _load();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.taskEditedSnack),
                      backgroundColor: context.colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(apiErrorMessage(e, fallback: 'Impossible de modifier la tâche')),
                      backgroundColor: context.colors.red,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: context.colors.accent),
              child: Text(l10n.editMenuItem)),
        ],
        ),
      ),
    );
  }

  Future<void> _archiveTask(TaskModel task) async {
    try {
      await ApiService.archiveTask(task.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Tâche archivée'),
          backgroundColor: context.colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(apiErrorMessage(e, fallback: 'Impossible d\'archiver la tâche')),
          backgroundColor: context.colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _confirmDeleteTask(TaskModel task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.bg2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: context.colors.border)),
        title: Text('Supprimer la tâche', style: TextStyle(color: context.colors.text1)),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer "${task.title}" ? Cette action est irréversible.',
            style: TextStyle(color: context.colors.text2, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: context.colors.text2))),
          ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.deleteTask(task.id);
                  if (mounted) Navigator.pop(context);
                  _load();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Tâche supprimée'),
                      backgroundColor: context.colors.red,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                } catch (e) {
                  if (mounted) Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(apiErrorMessage(e, fallback: 'Impossible de supprimer la tâche')),
                      backgroundColor: context.colors.red,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.red),
              child: const Text('Supprimer')),
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

class _CommentsSheet extends StatefulWidget {
  final TaskModel task;
  const _CommentsSheet({required this.task});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  List<CommentModel> _comments = [];
  bool _loading = true;
  bool _sending = false;
  final _contentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final comments = await ApiService.getComments(widget.task.id);
      if (mounted) setState(() { _comments = comments; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiService.addComment(widget.task.id, content);
      _contentCtrl.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Impossible d\'ajouter le commentaire'),
          backgroundColor: context.colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.task.title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: context.colors.text1)),
            Text('Commentaires',
                style: TextStyle(fontSize: 11, color: context.colors.text2)),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: context.colors.accent))
                  : _comments.isEmpty
                      ? Center(
                          child: Text('Aucun commentaire pour le moment',
                              style: TextStyle(color: context.colors.text2)))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _comments.length,
                          itemBuilder: (_, i) {
                            final c = _comments[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: context.colors.bg3,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: context.colors.border)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.authorName,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: context.colors.text1)),
                                  const SizedBox(height: 3),
                                  Text(c.content,
                                      style: TextStyle(
                                          fontSize: 12, color: context.colors.text2)),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _contentCtrl,
                  style: TextStyle(fontSize: 12, color: context.colors.text1),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.colors.bg3,
                    hintText: 'Ajouter un commentaire...',
                    hintStyle: TextStyle(fontSize: 12, color: context.colors.text2),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.colors.border)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: _sending
                    ? SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: context.colors.accent))
                    : Icon(Icons.send_rounded, color: context.colors.accent),
                onPressed: _sending ? null : _send,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
