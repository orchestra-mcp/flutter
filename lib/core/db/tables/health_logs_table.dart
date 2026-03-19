import 'package:drift/drift.dart';

class HealthLogsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get category =>
      text()(); // hydration | caffeine | nutrition | weight | sleep | pomodoro
  RealColumn get value => real()();
  TextColumn get unit => text().nullable()();
  TextColumn get metadata => text().withDefault(const Constant('{}'))(); // JSON
  DateTimeColumn get loggedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
