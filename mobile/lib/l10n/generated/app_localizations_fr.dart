// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'ProjectFlow';

  @override
  String get appTagline => 'Gestion de projets & équipes';

  @override
  String get cancel => 'Annuler';

  @override
  String get create => 'Créer';

  @override
  String get edit => 'Modifier';

  @override
  String get save => 'Sauvegarder';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get registerTitle => 'Créer un compte';

  @override
  String get loginSubtitle => 'Accédez à votre espace de travail';

  @override
  String get registerSubtitle => 'Rejoignez votre équipe sur ProjectFlow';

  @override
  String get tabLogin => 'Connexion';

  @override
  String get tabRegister => 'Inscription';

  @override
  String get fieldFirstName => 'Prénom';

  @override
  String get fieldLastName => 'Nom';

  @override
  String get fieldEmail => 'Adresse email';

  @override
  String get fieldPassword => 'Mot de passe';

  @override
  String get forgotPasswordLink => 'Mot de passe oublié ?';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get registerButton => 'Créer mon compte';

  @override
  String get restrictedAccessNotice => 'Accès réservé aux membres enregistrés.';

  @override
  String get errorFillAllFields => 'Veuillez remplir tous les champs';

  @override
  String get errorPasswordTooShort =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get errorLoginFailed => 'Email ou mot de passe incorrect';

  @override
  String get errorRegisterFailed =>
      'Erreur lors de l\'inscription. Cet email est peut-être déjà utilisé.';

  @override
  String get forgotPasswordAppBarTitle => 'Mot de passe oublié';

  @override
  String get resetPasswordStepTitle => 'Réinitialiser le mot de passe';

  @override
  String get newPasswordStepTitle => 'Nouveau mot de passe';

  @override
  String get resetEmailPrompt =>
      'Saisissez votre email pour recevoir un code de réinitialisation';

  @override
  String get resetCodePrompt =>
      'Saisissez le code reçu par email et votre nouveau mot de passe';

  @override
  String get fieldResetCode => 'Code reçu par email';

  @override
  String get fieldNewPassword => 'Nouveau mot de passe';

  @override
  String get fieldConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get sendCodeButton => 'Envoyer le code';

  @override
  String get resetPasswordButton => 'Réinitialiser le mot de passe';

  @override
  String get resendCodeLink => 'Renvoyer un code';

  @override
  String get errorEmailRequired => 'Veuillez saisir votre email';

  @override
  String get errorPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get infoCodeSent =>
      'Un code de réinitialisation a été envoyé à votre adresse email';

  @override
  String get errorSendCodeFailed =>
      'Impossible d\'envoyer le code. Vérifiez que l\'email est correct.';

  @override
  String get errorResetCodeInvalid =>
      'Code invalide ou expiré. Veuillez redemander un code.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsSubtitle => 'Compte et apparence';

  @override
  String get saveSettingsButton => 'Sauvegarder';

  @override
  String get savedButton => 'Sauvegardé !';

  @override
  String get settingsSavedSnack => 'Paramètres sauvegardés !';

  @override
  String get myAccountSection => 'MON COMPTE';

  @override
  String get emailNotEditable => 'Email (non modifiable)';

  @override
  String get localOnlyNotice =>
      '* Le prénom et le nom sont mis à jour localement uniquement.';

  @override
  String get changePasswordSection => 'CHANGER LE MOT DE PASSE';

  @override
  String get fieldCurrentPassword => 'Mot de passe actuel';

  @override
  String get updatePasswordButton => 'Mettre à jour le mot de passe';

  @override
  String get passwordUpdatedSuccess => 'Mot de passe mis à jour avec succès';

  @override
  String get currentPasswordIncorrect => 'Ancien mot de passe incorrect';

  @override
  String get appearanceSection => 'APPARENCE';

  @override
  String get themeLabel => 'Thème de l\'interface';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeAppliesNotice =>
      'Le thème s\'applique immédiatement à toute l\'application.';

  @override
  String get languageSection => 'LANGUE';

  @override
  String get languageLabel => 'Langue de l\'application';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageArabic => 'العربية';

  @override
  String get securitySection => 'SÉCURITÉ';

  @override
  String get accountSecure => 'Compte sécurisé';

  @override
  String get jwtActive => 'Authentification JWT active';

  @override
  String get activeStatus => 'Actif';

  @override
  String get logoutButton => 'Se déconnecter';

  @override
  String get logoutDialogTitle => 'Déconnexion';

  @override
  String get logoutDialogContent => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get comingSoonSection => 'FONCTIONNALITÉS À VENIR';

  @override
  String get comingSoonGoogle => 'Connexion Google (nécessite Firebase)';

  @override
  String get comingSoonPushNotif => 'Notifications push';

  @override
  String get comingSoonEmailChange => 'Changement d\'email';

  @override
  String get comingSoonExport => 'Export des données personnelles';

  @override
  String dashboardGreeting(String name) {
    return 'Bonjour, $name 👋';
  }

  @override
  String get dashboardTitle => 'Tableau de bord';

  @override
  String get newProjectButton => 'Nouveau projet';

  @override
  String get memberViewBadge => 'Vue membre';

  @override
  String get kpiActiveProjects => 'Projets actifs';

  @override
  String get kpiCompletionRate => 'Taux de complétion';

  @override
  String get kpiCompletedTasks => 'Tâches terminées';

  @override
  String get kpiLoggedHours => 'Heures loggées';

  @override
  String get projectsPortfolioTitle => 'PORTEFEUILLE PROJETS';

  @override
  String get noProjects => 'Aucun projet';

  @override
  String get statusActive => 'Actif';

  @override
  String get statusPlanning => 'Planif.';

  @override
  String get statusPaused => 'Pause';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String activeCount(int count) {
    return 'Actifs ($count)';
  }

  @override
  String planningCount(int count) {
    return 'Planning ($count)';
  }

  @override
  String get teamLoadTitle => 'CHARGE ÉQUIPE';

  @override
  String get noTeamLoadData => 'Aucune donnée de charge disponible';

  @override
  String get alertsTitle => 'ALERTES';

  @override
  String get noAlerts => 'Aucune alerte pour le moment';

  @override
  String taskOverdue(String title) {
    return '$title en retard';
  }

  @override
  String get newProjectDialogTitle => 'Nouveau projet';

  @override
  String get fieldProjectName => 'Nom du projet';

  @override
  String get fieldProjectKey => 'Clé (ex: PROJ1)';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldBudget => 'Budget (€)';

  @override
  String get createProjectButton => 'Créer le projet';

  @override
  String get projectCreatedSuccess => 'Projet créé avec succès !';

  @override
  String errorGeneric(String error) {
    return 'Erreur : $error';
  }

  @override
  String get myTasksTitle => 'Mes tâches';

  @override
  String tasksAssignedCount(int count) {
    return '$count tâches assignées';
  }

  @override
  String get filterAll => 'Tous';

  @override
  String get filterInProgress => 'En cours';

  @override
  String get filterTodo => 'À faire';

  @override
  String get filterDone => 'Terminées';

  @override
  String get newTaskButton => 'Nouvelle tâche';

  @override
  String get createTaskButton => 'Créer une tâche';

  @override
  String get noTasksFound => 'Aucune tâche trouvée';

  @override
  String get sectionInReview => 'En revue';

  @override
  String get sectionBacklog => 'Backlog';

  @override
  String get statusDone => 'Terminé';

  @override
  String get statusInProgressLabel => 'En cours';

  @override
  String get statusInReview => 'En revue';

  @override
  String get statusTodo => 'À faire';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get statusCancelled => 'Annulé';

  @override
  String statusUpdatedSnack(String status) {
    return 'Statut mis à jour : $status';
  }

  @override
  String get changeStatusTitle => 'Changer le statut';

  @override
  String get editMenuItem => 'Modifier';

  @override
  String get overdueChip => 'En retard';

  @override
  String get newTaskDialogTitle => 'Nouvelle tâche';

  @override
  String get editTaskDialogTitle => 'Modifier la tâche';

  @override
  String get fieldTitle => 'Titre';

  @override
  String get fieldProject => 'Projet';

  @override
  String get fieldPriority => 'Priorité';

  @override
  String get selectProjectHint => 'Sélectionner un projet';

  @override
  String get taskCreatedSnack => 'Tâche créée !';

  @override
  String get taskEditedSnack => 'Modifié !';
}
