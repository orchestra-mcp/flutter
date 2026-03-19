import 'package:drift/drift.dart';

class WorkflowsTable extends Table {
  TextColumn get id => text()(); // WFL-XXX
  TextColumn get projectId => text().withDefault(const Constant(''))();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get initialState => text().withDefault(const Constant('todo'))();
  TextColumn get states =>
      text().withDefault(const Constant('{}'))(); // JSON map
  TextColumn get transitions =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get gates =>
      text().withDefault(const Constant('{}'))(); // JSON map
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
