import 'package:drift/drift.dart';

class FeaturesTable extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('todo'))();
  TextColumn get kind => text().withDefault(const Constant('feature'))();
  TextColumn get priority => text().withDefault(const Constant('P2'))();
  TextColumn get estimate => text().nullable()();
  TextColumn get assigneeId => text().nullable()();
  TextColumn get labels =>
      text().withDefault(const Constant('[]'))(); // JSON array
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
