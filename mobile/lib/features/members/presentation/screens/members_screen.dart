import 'package:flutter/material.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/member_model.dart';
import '../../../../shared/models/task_model.dart';
import '../../../../core/utils/responsive.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});
  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<MemberModel> _members = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _userRole = '';

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
      _userRole = role ?? '';

      List<MemberModel> members;
      if (_userRole == 'MANAGER') {
        members = await ApiService.getAllUsers();
      } else {
        // CHEF_PROJET/MEMBRE : uniquement les membres de leurs propres projets
        // (owner/membre) — GET /users est reserve a MANAGER, un MEMBRE qui
        // l'appelait recevait un 403 et un ecran d'erreur.
        final projects = await ApiService.getProjects();
        final merged = <int, MemberModel>{};
        for (final project in projects) {
          try {
            final projectMembers = await ApiService.getProjectMembers(project.id);
            for (final m in projectMembers) {
              merged[m.id] = m;
            }
          } catch (_) {
            continue;
          }
        }
        members = merged.values.toList();
        if (_userRole == 'CHEF_PROJET') {
          // Un CHEF_PROJET ne voit que les MEMBRE de ses projets ici (ni
          // lui-même, ni d'autres CHEF_PROJET qui seraient membres du même
          // projet) — cette page liste son équipe, pas les autres leads.
          members = members.where((m) => m.globalRole == 'MEMBRE').toList();
        }
      }

      setState(() { _members = members; _loading = false; });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = apiErrorMessage(e, fallback: 'Impossible de charger les membres');
      });
    }
  }

  Future<void> _changeRole(MemberModel m, String newRole) async {
    try {
      await ApiService.updateUserRole(m.id, newRole);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${m.fullName} est maintenant ${newRole == 'CHEF_PROJET' ? 'Chef de projet' : 'Membre'}'),
          backgroundColor: context.colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(apiErrorMessage(e, fallback: 'Impossible de modifier le rôle')),
          backgroundColor: context.colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // MANAGER seulement, et jamais sur un autre MANAGER (memes garde-fous que le
  // backend UserController.updateRole) — bascule MEMBRE <-> CHEF_PROJET.
  Widget _roleMenu(MemberModel m) {
    if (_userRole != 'MANAGER' || m.globalRole == 'MANAGER') {
      return const SizedBox();
    }
    return PopupMenuButton<String>(
      color: context.colors.bg3,
      icon: Icon(Icons.swap_horiz, size: 16, color: context.colors.text2),
      tooltip: 'Changer le rôle',
      onSelected: (role) => _changeRole(m, role),
      itemBuilder: (_) => [
        if (m.globalRole != 'CHEF_PROJET')
          PopupMenuItem(
            value: 'CHEF_PROJET',
            child: Text('Promouvoir Chef de projet',
                style: TextStyle(fontSize: 12, color: context.colors.text1))),
        if (m.globalRole != 'MEMBRE')
          PopupMenuItem(
            value: 'MEMBRE',
            child: Text('Rétrograder Membre',
                style: TextStyle(fontSize: 12, color: context.colors.text1))),
      ],
    );
  }

  Future<void> _showMemberTasks(MemberModel member) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _MemberTasksSheet(member: member),
    );
  }

  List<MemberModel> get _filtered {
    if (_search.isEmpty) return _members;
    return _members.where((m) =>
      m.fullName.toLowerCase().contains(_search.toLowerCase()) ||
      m.email.toLowerCase().contains(_search.toLowerCase()) ||
      m.globalRole.toLowerCase().contains(_search.toLowerCase())
    ).toList();
  }

  int get _totalActive => _members.where((m) => m.active).length;

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
                padding: EdgeInsets.all(responsiveValue(context, mobile: 12, desktop: 16)),
                child: Column(children: [
                  _buildStats(),
                  SizedBox(height: responsiveValue(context, mobile: 10, desktop: 14)),
                  _buildSearchBar(),
                  SizedBox(height: responsiveValue(context, mobile: 10, desktop: 12)),
                  _buildTable(),
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
          Text('Ressources',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.text1)),
          Text('Gestion de l\'équipe',
              style: TextStyle(fontSize: 10, color: context.colors.text2)),
        ]),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.refresh_rounded, size: 18, color: context.colors.text2),
          tooltip: 'Actualiser',
          onPressed: _load,
        ),
      ]),
    );
  }

  Widget _buildStats() {
    final managers = _members.where((m) => m.globalRole == 'MANAGER').length;
    final chefs = _members.where((m) => m.globalRole == 'CHEF_PROJET').length;

    return ResponsiveKpiGrid(spacing: 10, children: [
      _statCard(Icons.people_outline,
          '${_members.length}', 'Total membres', context.colors.purple),
      _statCard(Icons.person_outline,
          '$_totalActive', 'Actifs', context.colors.green),
      _statCard(Icons.admin_panel_settings_outlined,
          '$managers', 'Managers', context.colors.red),
      _statCard(Icons.manage_accounts_outlined,
          '$chefs', 'Chefs projet', context.colors.accent),
    ]);
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    final mobile = isMobileWidth(context);
    return Container(
      padding: EdgeInsets.all(cardPadding(context)),
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Row(children: [
        Container(
          width: mobile ? 30 : 36, height: mobile ? 30 : 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: mobile ? 15 : 18),
        ),
        SizedBox(width: mobile ? 8 : 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(value,
                  style: TextStyle(
                      fontSize: mobile ? 17 : 20,
                      fontWeight: FontWeight.w700,
                      color: color)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: mobile ? 9 : 10, color: context.colors.text2)),
            ])),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (v) => setState(() => _search = v),
      style: TextStyle(fontSize: 13, color: context.colors.text1),
      decoration: InputDecoration(
        filled: true,
        fillColor: context.colors.bg2,
        hintText: 'Rechercher un membre...',
        hintStyle: TextStyle(fontSize: 12, color: context.colors.text2),
        prefixIcon: Icon(Icons.search, color: context.colors.text2, size: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.colors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.colors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.colors.accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      ),
    );
  }

  Widget _buildTable() {
    final list = _filtered;
    final mobile = isMobileWidth(context);

    return Container(
      decoration: BoxDecoration(
          color: context.colors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.border, width: 0.5)),
      child: Column(children: [
        // Header (masqué sur mobile : remplacé par les cartes empilées ci-dessous)
        if (!mobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.colors.border, width: 0.5))),
            child: Row(children: [
              Expanded(flex: 3, child: Text('MEMBRE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.colors.text2))),
              Expanded(flex: 2, child: Text('EMAIL',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.colors.text2))),
              Expanded(flex: 2, child: Text('RÔLE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.colors.text2))),
              Expanded(child: Text('STATUT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.colors.text2))),
              if (_userRole == 'MANAGER') const SizedBox(width: 34),
            ]),
          ),

        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Aucun membre trouvé',
                style: TextStyle(fontSize: 13, color: context.colors.text2)),
          )
        else if (mobile)
          ...list.map(_buildMemberCard)
        else
          ...list.map((m) => InkWell(
          onTap: () => _showMemberTasks(m),
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.colors.border, width: 0.5))),
          child: Row(children: [
            Expanded(flex: 3, child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: _roleColor(m.globalRole).withOpacity(0.15),
                    shape: BoxShape.circle),
                child: Center(child: Text(m.initials,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _roleColor(m.globalRole)))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(m.fullName,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.text1),
                  overflow: TextOverflow.ellipsis)),
            ])),
            Expanded(flex: 2, child: Text(m.email,
                style: TextStyle(fontSize: 11, color: context.colors.text2),
                overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _roleColor(m.globalRole).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _roleColor(m.globalRole).withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_roleIcon(m.globalRole),
                      size: 10, color: _roleColor(m.globalRole)),
                  const SizedBox(width: 4),
                  Text(m.globalRole.replaceAll('_', ' '),
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _roleColor(m.globalRole))),
                ]),
              ),
            ])),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: m.active
                      ? context.colors.green.withOpacity(0.1)
                      : context.colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(m.active ? 'Actif' : 'Inactif',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: m.active ? context.colors.green : context.colors.red)),
            )),
            if (_userRole == 'MANAGER')
              SizedBox(width: 34, child: _roleMenu(m)),
          ]),
        ))),
      ]),
    );
  }

  /// Carte membre pour mobile : mêmes informations que la ligne de tableau
  /// desktop (avatar+nom, email, rôle, statut) mais empilées verticalement.
  Widget _buildMemberCard(MemberModel m) {
    return InkWell(
      onTap: () => _showMemberTasks(m),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.colors.border, width: 0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: _roleColor(m.globalRole).withOpacity(0.15),
                  shape: BoxShape.circle),
              child: Center(child: Text(m.initials,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _roleColor(m.globalRole)))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.fullName,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.text1),
                    overflow: TextOverflow.ellipsis),
                Text(m.email,
                    style: TextStyle(fontSize: 11, color: context.colors.text2),
                    overflow: TextOverflow.ellipsis),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: m.active
                      ? context.colors.green.withOpacity(0.1)
                      : context.colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(m.active ? 'Actif' : 'Inactif',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: m.active ? context.colors.green : context.colors.red)),
            ),
            if (_userRole == 'MANAGER') _roleMenu(m),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _roleColor(m.globalRole).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _roleColor(m.globalRole).withOpacity(0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_roleIcon(m.globalRole),
                  size: 10, color: _roleColor(m.globalRole)),
              const SizedBox(width: 4),
              Text(m.globalRole.replaceAll('_', ' '),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _roleColor(m.globalRole))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, size: 48, color: context.colors.text3),
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

class _MemberTasksSheet extends StatefulWidget {
  final MemberModel member;
  const _MemberTasksSheet({required this.member});

  @override
  State<_MemberTasksSheet> createState() => _MemberTasksSheetState();
}

class _MemberTasksSheetState extends State<_MemberTasksSheet> {
  List<TaskModel> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tasks = await ApiService.getTasksByUser(widget.member.id);
      if (mounted) setState(() { _tasks = tasks; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = apiErrorMessage(e, fallback: 'Impossible de charger les tâches de ce membre');
        });
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DONE': return context.colors.green;
      case 'IN_PROGRESS': return context.colors.blue;
      case 'IN_REVIEW': return context.colors.purple;
      case 'TODO': return context.colors.amber;
      case 'BACKLOG': return context.colors.text2;
      default: return context.colors.red;
    }
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
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(widget.member.fullName,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: context.colors.text1)),
            Text('Tâches assignées',
                style: TextStyle(fontSize: 11, color: context.colors.text2)),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: context.colors.accent))
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: TextStyle(color: context.colors.text2)))
                      : _tasks.isEmpty
                          ? Center(
                              child: Text('Aucune tâche assignée',
                                  style: TextStyle(color: context.colors.text2)))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _tasks.length,
                              itemBuilder: (_, i) {
                                final t = _tasks[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: context.colors.bg3,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: context.colors.border)),
                                  child: Row(children: [
                                    Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            color: _statusColor(t.status),
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.title,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: context.colors.text1)),
                                        Text(t.projectName,
                                            style: TextStyle(
                                                fontSize: 10, color: context.colors.text2)),
                                      ],
                                    )),
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