import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'ProjectFlow'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In fr, this message translates to:
  /// **'Gestion de projets & équipes'**
  String get appTagline;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get create;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder'**
  String get save;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get registerTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Accédez à votre espace de travail'**
  String get loginSubtitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez votre équipe sur ProjectFlow'**
  String get registerSubtitle;

  /// No description provided for @tabLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get tabLogin;

  /// No description provided for @tabRegister.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get tabRegister;

  /// No description provided for @fieldFirstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get fieldFirstName;

  /// No description provided for @fieldLastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get fieldLastName;

  /// No description provided for @fieldEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get fieldPassword;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPasswordLink;

  /// No description provided for @loginButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get registerButton;

  /// No description provided for @restrictedAccessNotice.
  ///
  /// In fr, this message translates to:
  /// **'Accès réservé aux membres enregistrés.'**
  String get restrictedAccessNotice;

  /// No description provided for @errorFillAllFields.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir tous les champs'**
  String get errorFillAllFields;

  /// No description provided for @errorPasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères'**
  String get errorPasswordTooShort;

  /// No description provided for @errorLoginFailed.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect'**
  String get errorLoginFailed;

  /// No description provided for @errorRegisterFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'inscription. Cet email est peut-être déjà utilisé.'**
  String get errorRegisterFailed;

  /// No description provided for @forgotPasswordAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get forgotPasswordAppBarTitle;

  /// No description provided for @resetPasswordStepTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le mot de passe'**
  String get resetPasswordStepTitle;

  /// No description provided for @newPasswordStepTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPasswordStepTitle;

  /// No description provided for @resetEmailPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre email pour recevoir un code de réinitialisation'**
  String get resetEmailPrompt;

  /// No description provided for @resetCodePrompt.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code reçu par email et votre nouveau mot de passe'**
  String get resetCodePrompt;

  /// No description provided for @fieldResetCode.
  ///
  /// In fr, this message translates to:
  /// **'Code reçu par email'**
  String get fieldResetCode;

  /// No description provided for @fieldNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get fieldNewPassword;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get fieldConfirmPassword;

  /// No description provided for @sendCodeButton.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le code'**
  String get sendCodeButton;

  /// No description provided for @resetPasswordButton.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le mot de passe'**
  String get resetPasswordButton;

  /// No description provided for @resendCodeLink.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer un code'**
  String get resendCodeLink;

  /// No description provided for @errorEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir votre email'**
  String get errorEmailRequired;

  /// No description provided for @errorPasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get errorPasswordMismatch;

  /// No description provided for @infoCodeSent.
  ///
  /// In fr, this message translates to:
  /// **'Un code de réinitialisation a été envoyé à votre adresse email'**
  String get infoCodeSent;

  /// No description provided for @errorSendCodeFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer le code. Vérifiez que l\'email est correct.'**
  String get errorSendCodeFailed;

  /// No description provided for @errorResetCodeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code invalide ou expiré. Veuillez redemander un code.'**
  String get errorResetCodeInvalid;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte et apparence'**
  String get settingsSubtitle;

  /// No description provided for @saveSettingsButton.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder'**
  String get saveSettingsButton;

  /// No description provided for @savedButton.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardé !'**
  String get savedButton;

  /// No description provided for @settingsSavedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres sauvegardés !'**
  String get settingsSavedSnack;

  /// No description provided for @myAccountSection.
  ///
  /// In fr, this message translates to:
  /// **'MON COMPTE'**
  String get myAccountSection;

  /// No description provided for @emailNotEditable.
  ///
  /// In fr, this message translates to:
  /// **'Email (non modifiable)'**
  String get emailNotEditable;

  /// No description provided for @localOnlyNotice.
  ///
  /// In fr, this message translates to:
  /// **'* Le prénom et le nom sont mis à jour localement uniquement.'**
  String get localOnlyNotice;

  /// No description provided for @changePasswordSection.
  ///
  /// In fr, this message translates to:
  /// **'CHANGER LE MOT DE PASSE'**
  String get changePasswordSection;

  /// No description provided for @fieldCurrentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get fieldCurrentPassword;

  /// No description provided for @updatePasswordButton.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour le mot de passe'**
  String get updatePasswordButton;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe mis à jour avec succès'**
  String get passwordUpdatedSuccess;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Ancien mot de passe incorrect'**
  String get currentPasswordIncorrect;

  /// No description provided for @appearanceSection.
  ///
  /// In fr, this message translates to:
  /// **'APPARENCE'**
  String get appearanceSection;

  /// No description provided for @themeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Thème de l\'interface'**
  String get themeLabel;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @themeAppliesNotice.
  ///
  /// In fr, this message translates to:
  /// **'Le thème s\'applique immédiatement à toute l\'application.'**
  String get themeAppliesNotice;

  /// No description provided for @languageSection.
  ///
  /// In fr, this message translates to:
  /// **'LANGUE'**
  String get languageSection;

  /// No description provided for @languageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'application'**
  String get languageLabel;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageArabic.
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @securitySection.
  ///
  /// In fr, this message translates to:
  /// **'SÉCURITÉ'**
  String get securitySection;

  /// No description provided for @accountSecure.
  ///
  /// In fr, this message translates to:
  /// **'Compte sécurisé'**
  String get accountSecure;

  /// No description provided for @jwtActive.
  ///
  /// In fr, this message translates to:
  /// **'Authentification JWT active'**
  String get jwtActive;

  /// No description provided for @activeStatus.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get activeStatus;

  /// No description provided for @logoutButton.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logoutButton;

  /// No description provided for @logoutDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logoutDialogTitle;

  /// No description provided for @logoutDialogContent.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter ?'**
  String get logoutDialogContent;

  /// No description provided for @comingSoonSection.
  ///
  /// In fr, this message translates to:
  /// **'FONCTIONNALITÉS À VENIR'**
  String get comingSoonSection;

  /// No description provided for @comingSoonGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Google (nécessite Firebase)'**
  String get comingSoonGoogle;

  /// No description provided for @comingSoonPushNotif.
  ///
  /// In fr, this message translates to:
  /// **'Notifications push'**
  String get comingSoonPushNotif;

  /// No description provided for @comingSoonEmailChange.
  ///
  /// In fr, this message translates to:
  /// **'Changement d\'email'**
  String get comingSoonEmailChange;

  /// No description provided for @comingSoonExport.
  ///
  /// In fr, this message translates to:
  /// **'Export des données personnelles'**
  String get comingSoonExport;

  /// No description provided for @dashboardGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {name} 👋'**
  String dashboardGreeting(String name);

  /// No description provided for @dashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboardTitle;

  /// No description provided for @newProjectButton.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau projet'**
  String get newProjectButton;

  /// No description provided for @memberViewBadge.
  ///
  /// In fr, this message translates to:
  /// **'Vue membre'**
  String get memberViewBadge;

  /// No description provided for @kpiActiveProjects.
  ///
  /// In fr, this message translates to:
  /// **'Projets actifs'**
  String get kpiActiveProjects;

  /// No description provided for @kpiCompletionRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de complétion'**
  String get kpiCompletionRate;

  /// No description provided for @kpiCompletedTasks.
  ///
  /// In fr, this message translates to:
  /// **'Tâches terminées'**
  String get kpiCompletedTasks;

  /// No description provided for @kpiLoggedHours.
  ///
  /// In fr, this message translates to:
  /// **'Heures loggées'**
  String get kpiLoggedHours;

  /// No description provided for @projectsPortfolioTitle.
  ///
  /// In fr, this message translates to:
  /// **'PORTEFEUILLE PROJETS'**
  String get projectsPortfolioTitle;

  /// No description provided for @noProjects.
  ///
  /// In fr, this message translates to:
  /// **'Aucun projet'**
  String get noProjects;

  /// No description provided for @statusActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get statusActive;

  /// No description provided for @statusPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Planif.'**
  String get statusPlanning;

  /// No description provided for @statusPaused.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get statusPaused;

  /// No description provided for @statusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get statusCompleted;

  /// No description provided for @activeCount.
  ///
  /// In fr, this message translates to:
  /// **'Actifs ({count})'**
  String activeCount(int count);

  /// No description provided for @planningCount.
  ///
  /// In fr, this message translates to:
  /// **'Planning ({count})'**
  String planningCount(int count);

  /// No description provided for @teamLoadTitle.
  ///
  /// In fr, this message translates to:
  /// **'CHARGE ÉQUIPE'**
  String get teamLoadTitle;

  /// No description provided for @noTeamLoadData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée de charge disponible'**
  String get noTeamLoadData;

  /// No description provided for @alertsTitle.
  ///
  /// In fr, this message translates to:
  /// **'ALERTES'**
  String get alertsTitle;

  /// No description provided for @noAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Aucune alerte pour le moment'**
  String get noAlerts;

  /// No description provided for @taskOverdue.
  ///
  /// In fr, this message translates to:
  /// **'{title} en retard'**
  String taskOverdue(String title);

  /// No description provided for @newProjectDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau projet'**
  String get newProjectDialogTitle;

  /// No description provided for @fieldProjectName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du projet'**
  String get fieldProjectName;

  /// No description provided for @fieldProjectKey.
  ///
  /// In fr, this message translates to:
  /// **'Clé (ex: PROJ1)'**
  String get fieldProjectKey;

  /// No description provided for @fieldDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// No description provided for @fieldBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget (€)'**
  String get fieldBudget;

  /// No description provided for @createProjectButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer le projet'**
  String get createProjectButton;

  /// No description provided for @projectCreatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Projet créé avec succès !'**
  String get projectCreatedSuccess;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String errorGeneric(String error);

  /// No description provided for @myTasksTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes tâches'**
  String get myTasksTitle;

  /// No description provided for @tasksAssignedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} tâches assignées'**
  String tasksAssignedCount(int count);

  /// No description provided for @filterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get filterAll;

  /// No description provided for @filterInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get filterInProgress;

  /// No description provided for @filterTodo.
  ///
  /// In fr, this message translates to:
  /// **'À faire'**
  String get filterTodo;

  /// No description provided for @filterDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get filterDone;

  /// No description provided for @newTaskButton.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle tâche'**
  String get newTaskButton;

  /// No description provided for @createTaskButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer une tâche'**
  String get createTaskButton;

  /// No description provided for @noTasksFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune tâche trouvée'**
  String get noTasksFound;

  /// No description provided for @sectionInReview.
  ///
  /// In fr, this message translates to:
  /// **'En revue'**
  String get sectionInReview;

  /// No description provided for @sectionBacklog.
  ///
  /// In fr, this message translates to:
  /// **'Backlog'**
  String get sectionBacklog;

  /// No description provided for @statusDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get statusDone;

  /// No description provided for @statusInProgressLabel.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get statusInProgressLabel;

  /// No description provided for @statusInReview.
  ///
  /// In fr, this message translates to:
  /// **'En revue'**
  String get statusInReview;

  /// No description provided for @statusTodo.
  ///
  /// In fr, this message translates to:
  /// **'À faire'**
  String get statusTodo;

  /// No description provided for @statusBacklog.
  ///
  /// In fr, this message translates to:
  /// **'Backlog'**
  String get statusBacklog;

  /// No description provided for @statusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get statusCancelled;

  /// No description provided for @statusUpdatedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Statut mis à jour : {status}'**
  String statusUpdatedSnack(String status);

  /// No description provided for @changeStatusTitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer le statut'**
  String get changeStatusTitle;

  /// No description provided for @editMenuItem.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editMenuItem;

  /// No description provided for @overdueChip.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get overdueChip;

  /// No description provided for @newTaskDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle tâche'**
  String get newTaskDialogTitle;

  /// No description provided for @editTaskDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la tâche'**
  String get editTaskDialogTitle;

  /// No description provided for @fieldTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get fieldTitle;

  /// No description provided for @fieldProject.
  ///
  /// In fr, this message translates to:
  /// **'Projet'**
  String get fieldProject;

  /// No description provided for @fieldPriority.
  ///
  /// In fr, this message translates to:
  /// **'Priorité'**
  String get fieldPriority;

  /// No description provided for @selectProjectHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un projet'**
  String get selectProjectHint;

  /// No description provided for @taskCreatedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Tâche créée !'**
  String get taskCreatedSnack;

  /// No description provided for @taskEditedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Modifié !'**
  String get taskEditedSnack;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
