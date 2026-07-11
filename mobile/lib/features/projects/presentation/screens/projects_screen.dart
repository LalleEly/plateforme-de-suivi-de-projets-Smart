import 'package:flutter/material.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../shared/models/sprint_model.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<ProjectModel> _projects = [];
  List<ProjectModel> _filtered = [];
  bool _loading = true;
  String _filter = 'Tous';
  String _userRole = '';
  int? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await StorageService.getToken();
      final role = await StorageService.getUserRole();
      final uid = await StorageService.getUserId();
      if (token != null) ApiService.setToken(token);
      // includeArchived: true — necessaire pour que l'onglet "Archivés" ait des
      // données à afficher (les autres écrans/dropdowns utilisent la valeur par
      // défaut, qui exclut les projets archivés).
      final projects = await ApiService.getProjects(includeArchived: true);
      setState(() {
        _userRole = role ?? '';
        _userId = uid;
        _projects = projects;
        _loading = false;
      });
      _applyFilter(_filter);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _filter = filter;
      if (filter == 'Archivés') {
        // "Archivés" se base sur le champ booléen archived, pas sur le statut
        // métier (PLANNING/ACTIVE/ON_HOLD/COMPLETED/CANCELLED) : un projet
        // COMPLETED ou CANCELLED n'est pas forcément archivé, et vice-versa.
        _filtered = _projects.where((p) => p.archived).toList();
      } else if (filter == 'Tous') {
        _filtered = _projects.where((p) => !p.archived).toList();
      } else if (filter == 'Actifs') {
        _filtered = _projects.where(
          (p) => !p.archived && p.status == 'ACTIVE').toList();
      } else if (filter == 'Planification') {
        _filtered = _projects.where(
          (p) => !p.archived && p.status == 'PLANNING').toList();
      }
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE': return context.colors.green;
      case 'PLANNING': return context.colors.blue;
      case 'ON_HOLD': return context.colors.amber;
      case 'COMPLETED': return context.colors.cyan;
      default: return context.colors.red;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ACTIVE': return 'Actif';
      case 'PLANNING': return 'Planification';
      case 'ON_HOLD': return 'En pause';
      case 'COMPLETED': return 'Terminé';
      default: return 'Annulé';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTopBar(),
      Expanded(
        child: _loading
          ? Center(child: CircularProgressIndicator(
              color: context.colors.accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: context.colors.accent,
              child: SingleChildScrollView(
                physics:
                  const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(responsiveValue(context, mobile: 12, desktop: 16)),
                child: Column(children: [
                  _buildTable(),
                  SizedBox(height: responsiveValue(context, mobile: 10, desktop: 14)),
                  _buildGantt(),
                ]),
              ),
            ),
      ),
    ]);
  }

  Widget _buildTopBar() {
    final mobile = isMobileWidth(context);

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Projets', style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: context.colors.text1)),
        Text('${_projects.where((p) => !p.archived).length} projets · '
          '${_projects.where(
            (p) => !p.archived && p.status == 'ACTIVE').length} actifs',
          style: TextStyle(
            fontSize: 10, color: context.colors.text2)),
      ],
    );

    final filterChips = Row(
      mainAxisSize: MainAxisSize.min,
      children: ['Tous', 'Actifs', 'Planification', 'Archivés'].map((f) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () => _applyFilter(f),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _filter == f
                ? context.colors.accent
                : context.colors.bg3,
              border: Border.all(
                color: _filter == f
                  ? context.colors.accent : context.colors.border),
              borderRadius: BorderRadius.circular(7)),
            child: Text(f, style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _filter == f
                ? Colors.white : context.colors.text2)),
          ),
        ),
      )).toList(),
    );

    final canCreate = _userRole == 'MANAGER' || _userRole == 'CHEF_PROJET';
    final addButton = ElevatedButton.icon(
      onPressed: _showCreateDialog,
      icon: const Icon(Icons.add, size: 14),
      label: Text(mobile ? 'Nouveau' : 'Nouveau projet'),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.colors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7)),
      ),
    );

    if (mobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.colors.bg2,
          border: Border(bottom: BorderSide(
            color: context.colors.border, width: 0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: title),
            if (canCreate) addButton,
          ]),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: filterChips,
          ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.bg2,
        border: Border(bottom: BorderSide(
          color: context.colors.border, width: 0.5))),
      child: Row(children: [
        title,
        const Spacer(),
        filterChips,
        if (canCreate) addButton,
      ]),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.colors.border, width: 0.5)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
              color: context.colors.border, width: 0.5))),
          child: Row(children: [
            Text('LISTE DES PROJETS',
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: context.colors.text2,
                letterSpacing: 0.07)),
            const Spacer(),
            Text('${_filtered.length} résultats',
              style: TextStyle(
                fontSize: 10, color: context.colors.text2)),
          ]),
        ),
        // Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
              color: context.colors.border, width: 0.5))),
          child: Row(children: [
            Expanded(flex: 3, child: Text('PROJET',
              style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700,
                color: context.colors.text2))),
            Expanded(flex: 2, child: Text('RESPONSABLE',
              style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700,
                color: context.colors.text2))),
            Expanded(child: Text('MEMBRES',
              style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700,
                color: context.colors.text2))),
            Expanded(child: Text('TÂCHES',
              style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700,
                color: context.colors.text2))),
            Expanded(child: Text('BUDGET',
              style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700,
                color: context.colors.text2))),
            Expanded(flex: 2, child: Text('PROGRESSION',
              style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700,
                color: context.colors.text2))),
            Expanded(child: Text('STATUT',
              style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700,
                color: context.colors.text2))),
            const SizedBox(width: 34),
            const SizedBox(width: 40),
          ]),
        ),
        if (_filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Aucun projet trouvé',
              style: TextStyle(color: context.colors.text2)))
        else
          ..._filtered.map(_buildRow),
      ]),
    );
  }

  Widget _buildRow(ProjectModel project) {
    final color = _statusColor(project.status);
    final progress = project.taskCount > 0
      ? (project.taskCount * 0.6).clamp(0.0, 100.0) / 100
      : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: context.colors.border, width: 0.5))),
      child: Row(children: [
        Expanded(flex: 3, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.name, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: context.colors.text1),
              overflow: TextOverflow.ellipsis),
            if (project.description != null &&
                project.description!.isNotEmpty)
              Text(project.description!,
                style: TextStyle(
                  fontSize: 10, color: context.colors.text2),
                overflow: TextOverflow.ellipsis),
          ],
        )),
        Expanded(flex: 2, child: Text(
          project.ownerName,
          style: TextStyle(
            fontSize: 11, color: context.colors.text2),
          overflow: TextOverflow.ellipsis)),
        Expanded(child: Text(
          '${project.memberCount}',
          style: TextStyle(
            fontSize: 11, color: context.colors.text1,
            fontWeight: FontWeight.w600))),
        Expanded(child: Text(
          '${project.taskCount}',
          style: TextStyle(
            fontSize: 11, color: context.colors.text1,
            fontWeight: FontWeight.w600))),
        Expanded(child: Text(
          project.budget != null
            ? '${project.budget!.toStringAsFixed(0)}€'
            : 'N/A',
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: context.colors.amber))),
        Expanded(flex: 2, child: Row(children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.colors.bg4,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4))),
          const SizedBox(width: 6),
          Text('${(progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: color)),
        ])),
        Expanded(child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12)),
          child: Text(_statusLabel(project.status),
            style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700,
              color: color),
            textAlign: TextAlign.center))),
        SizedBox(
          width: 34,
          child: IconButton(
            icon: Icon(Icons.view_agenda_outlined,
              size: 16, color: context.colors.text2),
            tooltip: 'Sprints',
            onPressed: () => _showSprints(project),
          ),
        ),
        SizedBox(
          width: 40,
          // Le backend confirme le controle exact (owner/membre pour CHEF_PROJET) ;
          // ici, si le projet apparait dans la liste d'un CHEF_PROJET, c'est deja qu'il
          // est owner ou membre (getAllProjects le filtre deja ainsi cote backend).
          child: (_userRole == 'MANAGER' || _userRole == 'CHEF_PROJET')
            ? PopupMenuButton<String>(
                color: context.colors.bg3,
                icon: Icon(Icons.more_vert,
                  size: 16, color: context.colors.text2),
                onSelected: (v) {
                  if (v == 'edit') {
                    _showEditDialog(project);
                  } else if (v == 'archive') {
                    _archiveProject(project);
                  } else if (v == 'delete') {
                    _confirmDelete(project);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined,
                        size: 14, color: context.colors.text1),
                      const SizedBox(width: 8),
                      Text('Modifier',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.text1)),
                    ])),
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(children: [
                      Icon(
                        project.archived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                        size: 14, color: context.colors.text1),
                      const SizedBox(width: 8),
                      Text(project.archived ? 'Désarchiver' : 'Archiver',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.text1)),
                    ])),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                        size: 14, color: context.colors.red),
                      const SizedBox(width: 8),
                      Text('Supprimer',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.red)),
                    ])),
                ],
              )
            : const SizedBox()),
      ]),
    );
  }

  Widget _buildGantt() {
    if (_filtered.isEmpty) return const SizedBox();
    final months = ['Jan','Fév','Mar','Avr',
      'Mai','Jun','Jui','Aoû'];
    final colors = [context.colors.green, context.colors.amber,
      context.colors.red, context.colors.purple, context.colors.accent,
      context.colors.blue, context.colors.cyan];

    return Container(
      decoration: BoxDecoration(
        color: context.colors.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.colors.border, width: 0.5)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
              color: context.colors.border, width: 0.5))),
          child: Text(
            'GANTT — VUE TRIMESTRIELLE',
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: context.colors.text2, letterSpacing: 0.07)),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              const SizedBox(width: 100),
              ...months.map((m) => Expanded(child:
                Text(m, style: TextStyle(
                  fontSize: 9, color: context.colors.text2),
                textAlign: TextAlign.center))),
            ]),
            const SizedBox(height: 8),
            ..._filtered.take(5).toList()
              .asMap().entries.map((e) {
              final project = e.value;
              final color = colors[
                e.key % colors.length];
              final start = (e.key * 0.1).clamp(0.0, 0.5);
              final progress = project.taskCount > 0
                ? (project.taskCount * 0.06)
                  .clamp(0.1, 0.95) : 0.3;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4),
                child: Row(children: [
                  SizedBox(width: 100,
                    child: Text(project.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: context.colors.text1),
                      overflow: TextOverflow.ellipsis)),
                  Expanded(child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: context.colors.bg4,
                      borderRadius: BorderRadius.circular(3)),
                    child: LayoutBuilder(
                      builder: (ctx, constraints) {
                        final total = constraints.maxWidth;
                        return Stack(children: [
                          Positioned(
                            left: start * total,
                            width: progress * total,
                            top: 0, bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius:
                                  BorderRadius.circular(3)),
                              child: Center(child: Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white))))),
                        ]);
                      }),
                  )),
                ]),
              );
            }),
          ]),
        ),
      ]),
    );
  }

  void _showSprints(ProjectModel project) {
    final canManage = _userRole == 'MANAGER' ||
        (_userRole == 'CHEF_PROJET' && project.ownerId == _userId);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _SprintsSheet(project: project, canManage: canManage),
    );
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final keyCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final budgetCtrl = TextEditingController(
      text: '50000');

    showDialog(
      context: context,
      builder: (_) => _ProjectDialog(
        title: 'Nouveau projet',
        nameCtrl: nameCtrl,
        keyCtrl: keyCtrl,
        descCtrl: descCtrl,
        budgetCtrl: budgetCtrl,
        onSave: () async {
          if (nameCtrl.text.isEmpty ||
              keyCtrl.text.isEmpty) {
            return;
          }
          await ApiService.createProject(
            nameCtrl.text,
            keyCtrl.text.toUpperCase(),
            descCtrl.text,
            double.tryParse(budgetCtrl.text) ?? 50000);
          Navigator.pop(context);
          _load();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Projet créé avec succès !'),
                backgroundColor: context.colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              ));
          }
        },
      ),
    );
  }

  void _showEditDialog(ProjectModel project) {
    final nameCtrl = TextEditingController(
      text: project.name);
    final keyCtrl = TextEditingController(
      text: project.key);
    final descCtrl = TextEditingController(
      text: project.description ?? '');
    final budgetCtrl = TextEditingController(
      text: project.budget?.toStringAsFixed(0) ?? '');

    showDialog(
      context: context,
      builder: (_) => _ProjectDialog(
        title: 'Modifier le projet',
        nameCtrl: nameCtrl,
        keyCtrl: keyCtrl,
        descCtrl: descCtrl,
        budgetCtrl: budgetCtrl,
        isEdit: true,
        onSave: () async {
          if (nameCtrl.text.isEmpty || keyCtrl.text.isEmpty) return;
          try {
            await ApiService.updateProject(
              project.id,
              nameCtrl.text,
              keyCtrl.text.toUpperCase(),
              descCtrl.text,
              double.tryParse(budgetCtrl.text) ?? 0,
            );
            if (mounted) Navigator.pop(context);
            _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Projet modifié avec succès !'),
                  backgroundColor: context.colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                ));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(apiErrorMessage(e, fallback: 'Impossible de modifier le projet')),
                  backgroundColor: context.colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
            }
          }
        },
      ),
    );
  }

  Future<void> _archiveProject(ProjectModel project) async {
    final newArchived = !project.archived;
    try {
      await ApiService.archiveProject(project.id, archived: newArchived);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newArchived ? 'Projet archivé' : 'Projet désarchivé'),
          backgroundColor: context.colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(apiErrorMessage(e, fallback: 'Impossible d\'archiver le projet')),
          backgroundColor: context.colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _confirmDelete(ProjectModel project) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: context.colors.border)),
        title: Text('Supprimer le projet',
          style: TextStyle(color: context.colors.text1)),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer '
          '"${project.name}" ? Cette action est '
          'irréversible.',
          style: TextStyle(
            color: context.colors.text2, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
              style: TextStyle(color: context.colors.text2))),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.deleteProject(project.id);
                if (mounted) Navigator.pop(context);
                _load();
                if (mounted) {
                  ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(
                      content: const Text(
                        'Projet supprimé'),
                      backgroundColor: context.colors.red,
                      behavior: SnackBarBehavior.floating,
                    ));
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(apiErrorMessage(e, fallback: 'Impossible de supprimer le projet')),
                    backgroundColor: context.colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.red),
            child: const Text('Supprimer')),
        ],
      ),
    );
  }
}

class _ProjectDialog extends StatelessWidget {
  final String title;
  final TextEditingController nameCtrl;
  final TextEditingController keyCtrl;
  final TextEditingController descCtrl;
  final TextEditingController budgetCtrl;
  final VoidCallback onSave;
  final bool isEdit;

  const _ProjectDialog({
    required this.title,
    required this.nameCtrl,
    required this.keyCtrl,
    required this.descCtrl,
    required this.budgetCtrl,
    required this.onSave,
    this.isEdit = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colors.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.border)),
      title: Text(title, style: TextStyle(
        color: context.colors.text1,
        fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _f(context, 'Nom du projet', nameCtrl),
            const SizedBox(height: 10),
            _f(context, 'Clé (ex: PROJ1)', keyCtrl),
            const SizedBox(height: 10),
            _f(context, 'Description', descCtrl),
            const SizedBox(height: 10),
            _f(context, 'Budget (€)', budgetCtrl,
              type: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler',
            style: TextStyle(color: context.colors.text2))),
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.accent),
          child: Text(isEdit ? 'Modifier' : 'Créer')),
      ],
    );
  }

  Widget _f(BuildContext context, String label,
      TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontSize: 11, color: context.colors.text2)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: type,
          style: TextStyle(
            fontSize: 12, color: context.colors.text1),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.colors.bg3,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: context.colors.border)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: context.colors.border)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: context.colors.accent, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 9)),
        ),
      ],
    );
  }
}

class _SprintsSheet extends StatefulWidget {
  final ProjectModel project;
  final bool canManage;
  const _SprintsSheet({required this.project, required this.canManage});

  @override
  State<_SprintsSheet> createState() => _SprintsSheetState();
}

class _SprintsSheetState extends State<_SprintsSheet> {
  List<SprintModel> _sprints = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sprints = await ApiService.getSprints(widget.project.id);
      if (mounted) setState(() { _sprints = sprints; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE': return context.colors.green;
      case 'COMPLETED': return context.colors.cyan;
      default: return context.colors.blue;
    }
  }

  void _showCreateSprintDialog() {
    final nameCtrl = TextEditingController();
    final numberCtrl =
        TextEditingController(text: '${_sprints.length + 1}');
    final goalCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.bg2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: context.colors.border)),
        title: Text('Nouveau sprint',
            style:
                TextStyle(color: context.colors.text1, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sprintField('Nom du sprint', nameCtrl),
              const SizedBox(height: 10),
              _sprintField('Numéro', numberCtrl, type: TextInputType.number),
              const SizedBox(height: 10),
              _sprintField('Objectif', goalCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler',
                  style: TextStyle(color: context.colors.text2))),
          ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                try {
                  await ApiService.createSprint(
                    projectId: widget.project.id,
                    name: nameCtrl.text,
                    number: int.tryParse(numberCtrl.text) ?? (_sprints.length + 1),
                    goal: goalCtrl.text.isEmpty ? null : goalCtrl.text,
                  );
                  if (mounted) Navigator.pop(context);
                  _load();
                } catch (e) {
                  if (mounted) Navigator.pop(context);
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: context.colors.accent),
              child: const Text('Créer')),
        ],
      ),
    );
  }

  Widget _sprintField(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: context.colors.text2)),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSprint(SprintModel sprint) async {
    try {
      await ApiService.deleteSprint(sprint.id);
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text('Sprints — ${widget.project.name}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: context.colors.text1)),
              ),
              if (widget.canManage)
                IconButton(
                  icon: Icon(Icons.add, color: context.colors.accent),
                  onPressed: _showCreateSprintDialog,
                ),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: context.colors.accent))
                  : _sprints.isEmpty
                      ? Center(
                          child: Text('Aucun sprint pour ce projet',
                              style: TextStyle(color: context.colors.text2)))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _sprints.length,
                          itemBuilder: (_, i) {
                            final s = _sprints[i];
                            final color = _statusColor(s.status);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: context.colors.bg3,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: context.colors.border)),
                              child: Row(children: [
                                Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                        color: color, shape: BoxShape.circle)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Sprint ${s.number} — ${s.name}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: context.colors.text1)),
                                      Text(
                                          '${s.taskCount} tâches · vélocité ${s.velocity} pts',
                                          style: TextStyle(
                                              fontSize: 10, color: context.colors.text2)),
                                    ],
                                  ),
                                ),
                                if (widget.canManage)
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        size: 16, color: context.colors.red),
                                    onPressed: () => _deleteSprint(s),
                                  ),
                              ]),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}