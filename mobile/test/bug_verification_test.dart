// Verification widget tests for BUG 1 (dropdown crash in Suivi des temps)
// and BUG 2 (Actifs/Archivés filters). These pump the real production
// screens (TimeScreen, ProjectsScreen) and drive them with WidgetTester
// taps/entries against the real running local backend (localhost:8080) —
// not mocks, not curl. A regression of BUG 1 would surface here as a
// thrown FlutterError from DropdownButton's "exactly one item" assertion,
// which flutter_test fails the test on automatically.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/core/storage/storage_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/time/presentation/screens/time_screen.dart';
import 'package:mobile/features/projects/presentation/screens/projects_screen.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );

Future<void> _loginAs(String email) async {
  SharedPreferences.setMockInitialValues({});
  ApiService.init();
  final user = await ApiService.login(email, 'Test1234!');
  await StorageService.saveUser(
    token: user.accessToken,
    userId: user.id,
    email: user.email,
    fullName: user.fullName,
    role: user.globalRole,
  );
}

// pump() borné au lieu de pumpAndSettle() : tant qu'un CircularProgressIndicator
// (animation indéterminée, donc jamais "settled") reste monté — ex. le petit
// spinner du bouton Enregistrer pendant l'appel réseau — pumpAndSettle() boucle
// indéfiniment et ne se termine qu'au timeout global de 10 min de `flutter test`.
// C'est très probablement ce qui a fait échouer la 1ère tentative (TimeoutException
// after 10 minutes). On avance donc par pas de temps fixes et bornés.
Future<void> _settle(WidgetTester tester,
    {int steps = 20, Duration step = const Duration(milliseconds: 300)}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'BUG 1 — Time Tracking: select project+task, log time, Save does not crash',
      (tester) async {
    debugPrint('[BUG1] login...');
    await _loginAs('test.chef@projectflow.local');

    debugPrint('[BUG1] fetching real data...');
    final projects = await ApiService.getProjects();
    expect(projects, isNotEmpty, reason: 'test.chef doit avoir au moins un projet');
    final project = projects.first;
    final tasks = await ApiService.getTasksByProject(project.id);
    expect(tasks, isNotEmpty, reason: 'Le projet de test doit avoir au moins une tâche');
    final task = tasks.first;
    debugPrint('[BUG1] project=${project.name} task=${task.title}');

    await tester.pumpWidget(_wrap(const TimeScreen()));
    await _settle(tester);
    debugPrint('[BUG1] initial load settled');

    await tester.tap(find.text('Sélectionner un projet'));
    await _settle(tester, steps: 5);
    debugPrint('[BUG1] project dropdown opened, tapping "${project.name}"');
    await tester.tap(find.text(project.name).last);
    await _settle(tester, steps: 15);
    debugPrint('[BUG1] project selected, tasks should be loaded');

    await tester.tap(find.text('Sélectionner une tâche'));
    await _settle(tester, steps: 5);
    debugPrint('[BUG1] task dropdown opened, tapping "${task.title}"');
    await tester.tap(find.text(task.title).last);
    await _settle(tester, steps: 5);
    debugPrint('[BUG1] task selected');

    await tester.enterText(find.byType(TextField).first, '1.5');
    await _settle(tester, steps: 2);
    final saveButton = find.widgetWithText(ElevatedButton, 'Enregistrer');
    expect(saveButton, findsOneWidget);
    debugPrint('[BUG1] tapping Save — this triggers _save() -> _load() -> '
        'refetch _projects, the exact BUG1 crash trigger');
    await tester.tap(saveButton);

    // Si le DropdownButton lève une assertion pendant le rebuild post-_load(),
    // flutter_test capture l'exception au prochain pump() et fait échouer le test.
    await _settle(tester, steps: 25);
    debugPrint('[BUG1] settled after save, checking result banner');

    expect(find.textContaining('Temps enregistré avec succès'), findsOneWidget,
        reason: 'La sauvegarde doit aboutir sans crash de dropdown');
    debugPrint('[BUG1] PASSED — no dropdown assertion, save succeeded');

    final logs = await ApiService.getMyTimeLogs();
    final created = logs.where((l) => l.taskId == task.id).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    if (created.isNotEmpty) {
      await ApiService.deleteTimeLog(created.first.id);
      debugPrint('[BUG1] cleanup: deleted test time log ${created.first.id}');
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets(
      'BUG 2 — Projects: Archivés tab shows archived project, Actifs filter runs cleanly',
      (tester) async {
    debugPrint('[BUG2] login...');
    await _loginAs('test.manager@projectflow.local');

    await tester.pumpWidget(_wrap(const ProjectsScreen()));
    await _settle(tester);
    debugPrint('[BUG2] initial load settled');

    expect(find.text('spring'), findsNothing,
        reason: '"spring" est archivé, il ne doit pas figurer sous "Tous"');
    debugPrint('[BUG2] "Tous" correctly excludes archived project');

    await tester.tap(find.text('Archivés'));
    await _settle(tester, steps: 5);
    expect(find.text('spring'), findsOneWidget,
        reason: 'Le projet archivé "spring" doit apparaître sous l\'onglet Archivés');
    debugPrint('[BUG2] "Archivés" correctly shows the archived project');

    await tester.tap(find.text('Actifs'));
    await _settle(tester, steps: 5);
    expect(find.text('spring'), findsNothing,
        reason: '"spring" est archivé, ne doit pas apparaître sous Actifs même si son statut changeait');
    debugPrint('[BUG2] PASSED — "Actifs" filter runs cleanly, no crash, correct exclusion');
  }, timeout: const Timeout(Duration(minutes: 1)));
}
