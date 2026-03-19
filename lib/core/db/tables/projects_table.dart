import 'package:drift/drift.dart';

class ProjectsTable extends Table {
  TextColumn get id => text()();
  TextColumn get slug => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get mode => text().withDefault(const Constant('active'))();
  TextColumn get stacks => text().withDefault(const Constant('[]'))(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
