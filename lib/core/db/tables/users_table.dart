import 'package:drift/drift.dart';

class UsersTable extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text()();
  TextColumn get username => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get timezone => text().withDefault(const Constant('UTC'))();
  TextColumn get githubUsername => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('member'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
