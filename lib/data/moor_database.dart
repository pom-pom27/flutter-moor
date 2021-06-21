import 'package:moor/moor.dart';
import 'package:moor_flutter/moor_flutter.dart';

// Moor works by source gen. This file will all the generated code.
part 'moor_database.g.dart';

class Tasks extends Table {
  // autoIncrement automatically sets this to be the primary key
  IntColumn get id => integer().autoIncrement()();
  // If the length constraint is not fulfilled, the Task will not
  // be inserted into the database and an exception will be thrown.
  TextColumn get name => text().withLength(min: 1, max: 50)();
  // DateTime is not natively supported by SQLite
  // Moor converts it to & from UNIX seconds
  DateTimeColumn get dueDate => dateTime().nullable()();
  // Booleans are not supported as well, Moor converts them to integers
  // Simple default values are specified as Constants
  BoolColumn get completed => boolean().withDefault(Constant(false))();
}

// This annotation tells the code generator which tables this DB works with
@UseMoor(tables: [Tasks], daos: [TaskDao])
// _$AppDatabase is the name of the generated class
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      // Specify the location of the database file
      : super((FlutterQueryExecutor.inDatabaseFolder(
          path: 'db.sqlite',
          // Good for debugging - prints SQL in the console
          logStatements: true,
        )));

  // Bump this when changing tables and columns.
  // Migrations will be covered in the next part.
  @override
  int get schemaVersion => 1;
}

// Denote which tables this DAO can access
@UseDao(tables: [
  Tasks
], queries: {
  'completedTasksGenerated':
      'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date DESC, name;'
})
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  final AppDatabase db;

  // Called by the AppDatabase class
  TaskDao(this.db) : super(db);

  Future<List<Task>> getAllTasks() => select(tasks).get();
  Future insertTask(Insertable<Task> task) => into(tasks).insert(task);
  Future updateTask(Insertable<Task> task) => update(tasks).replace(task);
  Future deleteTask(Insertable<Task> task) => delete(tasks).delete(task);

  // Updated to use the orderBy statement
  Stream<List<Task>> watchAllTasks() {
    // Wrap the whole select statement in parenthesis
    return (select(tasks)
          // Statements like orderBy and where return void => the need to use a cascading ".." operator
          ..orderBy(
            ([
              // Primary sorting by due date
              (t) =>
                  OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
              // Secondary alphabetical sorting
              (t) => OrderingTerm(expression: t.name),
            ]),
          ))
        // watch the whole select statement
        .watch();
  }

  // Watching complete tasks with a custom query
  Stream<List<Task>> watchCompletedTasksCustom() {
    return customSelect(
      'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date DESC, name;',
      // The Stream will emit new values when the data inside the Tasks table changes
      readsFrom: {tasks},
    ).watch()
        // customSelect or customSelectStream gives us QueryRow list
        // This runs each time the Stream emits a new value.
        .map((rows) {
      // Turning the data of a row into a Task object
      return rows.map((row) => Task.fromData(row.data, db)).toList();
    });
  }

  // Stream<List<Task>> watchCompletedTasks() {
  //   // where returns void, need to use the cascading operator
  //   return (select(tasks)
  //         ..orderBy(
  //           ([
  //             // Primary sorting by due date
  //             (t) =>
  //                 OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
  //             // Secondary alphabetical sorting
  //             (t) => OrderingTerm(expression: t.name),
  //           ]),
  //         )
  //         ..where((t) => t.completed.equals(true)))
  //       .watch();
  // }

}
