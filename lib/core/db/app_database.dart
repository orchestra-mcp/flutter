import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:orchestra/core/db/tables/agents_table.dart';
import 'package:orchestra/core/db/tables/delegations_table.dart';
import 'package:orchestra/core/db/tables/features_table.dart';
import 'package:orchestra/core/db/tables/health_logs_table.dart';
import 'package:orchestra/core/db/tables/notes_table.dart';
import 'package:orchestra/core/db/tables/notifications_table.dart';
import 'package:orchestra/core/db/tables/projects_table.dart';
import 'package:orchestra/core/db/tables/sessions_table.dart';
import 'package:orchestra/core/db/tables/settings_table.dart';
import 'package:orchestra/core/db/tables/sync_queue_table.dart';
import 'package:orchestra/core/db/tables/users_table.dart';
import 'package:orchestra/core/db/tables/workflows_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  UsersTable,
  FeaturesTable,
  ProjectsTable,
  NotesTable,
  HealthLogsTable,
  NotificationsTable,
  SessionsTable,
  SyncQueueTable,
  AgentsTable,
  WorkflowsTable,
  SettingsTable,
  DelegationsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'orchestra');
  }
}
