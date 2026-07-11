class AppConstants {
  static const String appName = 'ProjectFlow';
  static const String version = '1.0.0';
  
  static const Map<String, String> statusLabels = {
    'BACKLOG': 'Backlog',
    'TODO': 'A faire',
    'IN_PROGRESS': 'En cours',
    'IN_REVIEW': 'En revue',
    'DONE': 'Termine',
    'CANCELLED': 'Annule',
  };

  static const Map<String, String> priorityLabels = {
    'CRITICAL': 'Critique',
    'HIGH': 'Haute',
    'MEDIUM': 'Moyenne',
    'LOW': 'Basse',
  };

  static const Map<String, String> projectStatusLabels = {
    'PLANNING': 'Planification',
    'ACTIVE': 'Actif',
    'ON_HOLD': 'En pause',
    'COMPLETED': 'Termine',
    'CANCELLED': 'Annule',
  };
}
