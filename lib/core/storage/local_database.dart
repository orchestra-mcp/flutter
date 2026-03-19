import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:orchestra/core/db/tables/entity_sync_metadata_table.dart';
import 'package:orchestra/core/db/tables/sync_version_history_table.dart';
import 'package:orchestra/core/db/tables/team_shares_table.dart';

part 'local_database.g.dart';

// ── Tables ───────────────────────────────────────────────────────────────────

/// Projects table — mirrors the REST API project model.
class LocalProjects extends Table {
  TextColumn get id => text()();
  TextColumn get slug => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get mode => text().withDefault(const Constant('active'))();
  TextColumn get stacks => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Features table — mirrors the REST API feature model.
class LocalFeatures extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('todo'))();
  TextColumn get kind => text().withDefault(const Constant('feature'))();
  TextColumn get priority => text().withDefault(const Constant('P2'))();
  TextColumn get estimate => text().nullable()();
  TextColumn get assigneeId => text().nullable()();
  TextColumn get labels => text().withDefault(const Constant('[]'))();
  TextColumn get evidence => text().nullable()();
  TextColumn get body => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Notes table — mirrors the REST API note model.
class LocalNotes extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get content => text().withDefault(const Constant(''))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Agents table — mirrors the REST API agent model.
class LocalAgents extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get provider => text().withDefault(const Constant('claude'))();
  TextColumn get model => text()();
  TextColumn get systemPrompt => text().nullable()();
  TextColumn get tools => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Skills table — skills attached to agents or projects.
class LocalSkills extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get command => text()();
  TextColumn get description => text().nullable()();
  TextColumn get source => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Workflows table — multi-step workflow definitions.
class LocalWorkflows extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get steps => text().withDefault(const Constant('[]'))();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Docs table — markdown documents attached to projects.
class LocalDocs extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get path => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sessions table — AI chat sessions.
class LocalSessions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get accountId => text()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get metadata => text().withDefault(const Constant('{}'))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Delegations table — task delegations between users/agents.
class LocalDelegations extends Table {
  TextColumn get id => text()();
  TextColumn get fromUserId => text()();
  TextColumn get toUserId => text()();
  TextColumn get task => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get featureId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Labels table — labels attached to features.
class LocalLabels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get featureId => text()();
  TextColumn get label => text()();
}

/// Dependencies table — dependency edges between features.
class LocalDependencies extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get featureId => text()();
  TextColumn get dependsOnId => text()();
}

// ── FTS5 virtual tables (raw SQL, not Drift table classes) ───────────────────

/// FTS5 index for full-text search across projects, features, and notes.
/// Created via migration SQL — see [LocalDatabase.migration].

// ── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  LocalProjects,
  LocalFeatures,
  LocalNotes,
  LocalAgents,
  LocalSkills,
  LocalWorkflows,
  LocalDocs,
  LocalSessions,
  LocalDelegations,
  LocalLabels,
  LocalDependencies,
  TeamSharesTable,
  EntitySyncMetadataTable,
  SyncVersionHistoryTable,
])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase({String? workspacePath})
      : super(_openConnection(workspacePath));
  LocalDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  static QueryExecutor _openConnection(String? workspacePath) {
    if (workspacePath == null) {
      return driftDatabase(name: 'orchestra_local');
    }
    // Workspace-scoped DB: hash the path to create a unique name per workspace.
    final hash = workspacePath.hashCode.toUnsigned(32).toRadixString(16);
    return driftDatabase(name: 'orchestra_ws_$hash');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Create FTS5 virtual tables for full-text search.
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS fts_projects USING fts5(
              id UNINDEXED,
              name,
              description,
              slug,
              stacks,
              content='local_projects',
              content_rowid='rowid'
            )
          ''');
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS fts_features USING fts5(
              id UNINDEXED,
              title,
              description,
              body,
              labels,
              content='local_features',
              content_rowid='rowid'
            )
          ''');
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS fts_notes USING fts5(
              id UNINDEXED,
              title,
              content,
              tags,
              content='local_notes',
              content_rowid='rowid'
            )
          ''');
          // Triggers to keep FTS in sync with content tables.
          await _createFtsTriggers();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // v2: Add FTS5 virtual tables.
            await customStatement('''
              CREATE VIRTUAL TABLE IF NOT EXISTS fts_projects USING fts5(
                id UNINDEXED,
                name,
                description,
                slug,
                stacks,
                content='local_projects',
                content_rowid='rowid'
              )
            ''');
            await customStatement('''
              CREATE VIRTUAL TABLE IF NOT EXISTS fts_features USING fts5(
                id UNINDEXED,
                title,
                description,
                body,
                labels,
                content='local_features',
                content_rowid='rowid'
              )
            ''');
            await customStatement('''
              CREATE VIRTUAL TABLE IF NOT EXISTS fts_notes USING fts5(
                id UNINDEXED,
                title,
                content,
                tags,
                content='local_notes',
                content_rowid='rowid'
              )
            ''');
            await _createFtsTriggers();
            // Rebuild FTS indexes with existing data.
            await rebuildFtsIndexes();
          }
          if (from < 3) {
            // v3: Add team sharing and sync metadata tables.
            await m.createTable(teamSharesTable);
            await m.createTable(entitySyncMetadataTable);
            await m.createTable(syncVersionHistoryTable);
          }
        },
      );

  /// Creates triggers that keep the FTS5 indexes in sync with content tables.
  Future<void> _createFtsTriggers() async {
    // ── Projects triggers ──────────────────────────────────────────────
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS fts_projects_ai AFTER INSERT ON local_projects BEGIN
        INSERT INTO fts_projects(rowid, id, name, description, slug, stacks)
        VALUES (new.rowid, new.id, new.name, COALESCE(new.description, ''), new.slug, new.stacks);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS fts_projects_ad AFTER DELETE ON local_projects BEGIN
        INSERT INTO fts_projects(fts_projects, rowid, id, name, description, slug, stacks)
        VALUES ('delete', old.rowid, old.id, old.name, COALESCE(old.description, ''), old.slug, old.stacks);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS fts_projects_au AFTER UPDATE ON local_projects BEGIN
        INSERT INTO fts_projects(fts_projects, rowid, id, name, description, slug, stacks)
        VALUES ('delete', old.rowid, old.id, old.name, COALESCE(old.description, ''), old.slug, old.stacks);
        INSERT INTO fts_projects(rowid, id, name, description, slug, stacks)
        VALUES (new.rowid, new.id, new.name, COALESCE(new.description, ''), new.slug, new.stacks);
      END
    ''');

    // ── Features triggers ─────────────────────────────────────────────
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS fts_features_ai AFTER INSERT ON local_features BEGIN
        INSERT INTO fts_features(rowid, id, title, description, body, labels)
        VALUES (new.rowid, new.id, new.title, COALESCE(new.description, ''), COALESCE(new.body, ''), new.labels);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS fts_features_ad AFTER DELETE ON local_features BEGIN
        INSERT INTO fts_features(fts_features, rowid, id, title, description, body, labels)
        VALUES ('delete', old.rowid, old.id, old.title, COALESCE(old.description, ''), COALESCE(old.body, ''), old.labels);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS fts_features_au AFTER UPDATE ON local_features BEGIN
        INSERT INTO fts_features(fts_features, rowid, id, title, description, body, labels)
        VALUES ('delete', old.rowid, old.id, old.title, COALESCE(old.description, ''), COALESCE(old.body, ''), old.labels);
        INSERT INTO fts_features(rowid, id, title, description, body, labels)
        VALUES (new.rowid, new.id, new.title, COALESCE(new.description, ''), COALESCE(new.body, ''), new.labels);
      END
    ''');

    // ── Notes triggers ────────────────────────────────────────────────
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS fts_notes_ai AFTER INSERT ON local_notes BEGIN
        INSERT INTO fts_notes(rowid, id, title, content, tags)
        VALUES (new.rowid, new.id, new.title, new.content, new.tags);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS fts_notes_ad AFTER DELETE ON local_notes BEGIN
        INSERT INTO fts_notes(fts_notes, rowid, id, title, content, tags)
        VALUES ('delete', old.rowid, old.id, old.title, old.content, old.tags);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS fts_notes_au AFTER UPDATE ON local_notes BEGIN
        INSERT INTO fts_notes(fts_notes, rowid, id, title, content, tags)
        VALUES ('delete', old.rowid, old.id, old.title, old.content, old.tags);
        INSERT INTO fts_notes(rowid, id, title, content, tags)
        VALUES (new.rowid, new.id, new.title, new.content, new.tags);
      END
    ''');
  }

  /// Rebuild all FTS5 indexes from current content table data.
  /// Call this after bulk imports or migration from v1.
  Future<void> rebuildFtsIndexes() async {
    await customStatement(
        "INSERT INTO fts_projects(fts_projects) VALUES('rebuild')");
    await customStatement(
        "INSERT INTO fts_features(fts_features) VALUES('rebuild')");
    await customStatement(
        "INSERT INTO fts_notes(fts_notes) VALUES('rebuild')");
  }

  /// Full-text search across projects. Returns matching project IDs ranked
  /// by relevance using BM25.
  Future<List<FtsResult>> searchProjects(String query) async {
    final escaped = _escapeFtsQuery(query);
    final results = await customSelect(
      'SELECT id, rank FROM fts_projects WHERE fts_projects MATCH ? ORDER BY rank',
      variables: [Variable.withString(escaped)],
    ).get();
    return results
        .map((row) => FtsResult(
              id: row.read<String>('id'),
              rank: row.read<double>('rank'),
            ))
        .toList();
  }

  /// Full-text search across features.
  Future<List<FtsResult>> searchFeatures(String query) async {
    final escaped = _escapeFtsQuery(query);
    final results = await customSelect(
      'SELECT id, rank FROM fts_features WHERE fts_features MATCH ? ORDER BY rank',
      variables: [Variable.withString(escaped)],
    ).get();
    return results
        .map((row) => FtsResult(
              id: row.read<String>('id'),
              rank: row.read<double>('rank'),
            ))
        .toList();
  }

  /// Full-text search across notes.
  Future<List<FtsResult>> searchNotes(String query) async {
    final escaped = _escapeFtsQuery(query);
    final results = await customSelect(
      'SELECT id, rank FROM fts_notes WHERE fts_notes MATCH ? ORDER BY rank',
      variables: [Variable.withString(escaped)],
    ).get();
    return results
        .map((row) => FtsResult(
              id: row.read<String>('id'),
              rank: row.read<double>('rank'),
            ))
        .toList();
  }

  /// Escapes user input for safe FTS5 queries.
  /// Wraps each token in double-quotes to prevent FTS5 syntax injection.
  String _escapeFtsQuery(String query) {
    final tokens = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map((t) => '"${t.replaceAll('"', '""')}"');
    return tokens.join(' ');
  }
}

/// A single FTS5 search result with the matched entity ID and BM25 rank.
class FtsResult {
  const FtsResult({required this.id, required this.rank});

  final String id;

  /// BM25 rank — lower (more negative) is better.
  final double rank;
}
