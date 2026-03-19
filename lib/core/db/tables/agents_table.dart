import 'package:drift/drift.dart';

class AgentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get provider => text().withDefault(const Constant('claude'))();
  TextColumn get model => text()();
  TextColumn get systemPrompt => text().nullable()();
  TextColumn get tools => text().withDefault(const Constant('[]'))(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
