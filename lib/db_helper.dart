import 'dart:io';
import 'constants.dart';
import 'network_helper.dart';
import 'repo.dart';
import 'providers.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  late String path;
  late Database database;
  late dynamic feedData;
  var dbItemList = [];
  List<Repo> repoList = [];
  late RepoModel repoModel;
  late DateTime timeStamp;

  void setupDB() async {
    Directory dbpath = await getApplicationDocumentsDirectory();
    path = join(dbpath.path, 'repo.db');

    database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute(
          'CREATE TABLE $tableName ($columnId INTEGER PRIMARY KEY, $columnRepoId INTEGER, $columnName TEXT, $columnDescription TEXT, $columnUrl TEXT, $columnStarCount INTEGER, $columnCreatedAt DATETIME, $columnPushedAt DATETIME)');
    });

    var count = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM $tableName'));

    if (count == 0) {
      // if no data in db, try to fetch data from github api
      fetchAddData();
    } else {
      // if data is available in db, lets use them
      addToRepoList();
    }
  }

  void addRecord(List input) async {
    // Insert records
    await database.transaction((txn) async {
      await txn.rawInsert(
          'INSERT INTO $tableName($columnRepoId, $columnName, $columnDescription, $columnUrl, $columnStarCount, $columnCreatedAt, $columnPushedAt) VALUES(?,?,?,?,?,?,?)',
          input);
    });
  }

  void fetchAddData() async {
    // get feed data from github api using network helper
    feedData = await NetworkHelper().getData();

    if (feedData != null) {
      var repoItems = feedData['items'];

      for (var item in repoItems) {
        List<dynamic> dbItem = [
          item['id'],
          item['name'],
          item['description'],
          item['html_url'],
          item['stargazers_count'],
          item['created_at'],
          item['pushed_at']
        ];
        dbItemList.add(dbItem);
        addRecord(dbItem);
      }
    } else {
      // if result feed is null for some reason, pass empty repo list to show the status
      repoModel.updateRepo(<Repo>[]);
    }

    addToRepoList();
  }

  void refreshRecord() async {
    // Delete the existing records
    await database.rawDelete('DELETE FROM $tableName');

    // make sure all data erased
    var count = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM $tableName'));

    if (count == 0) {
      repoList = <Repo>[];
      repoModel.updateRepo(repoList);

      // lets fetch fresh data from github api
      fetchAddData();

      var timeStamp = DateTime.now();

      // lets format time without using package since this is fairly simple and only one time
      var formatedTime =
          "${timeStamp.year.toString()}-${timeStamp.month.toString().padLeft(2, '0')}-${timeStamp.day.toString().padLeft(2, '0')} ${timeStamp.hour.toString().padLeft(2, '0')}:${timeStamp.minute.toString().padLeft(2, '0')}:${timeStamp.second.toString().padLeft(2, '0')}";

      // update repo model's updatedAt property to show the updated time
      repoModel.updateTimeStamp(formatedTime);
    }
  }

  void addToRepoList() async {
    // get data from repo.db
    List<Map<dynamic, dynamic>> list =
        await database.rawQuery('SELECT * FROM $tableName');

    for (var row in list) {
      // creating list of repo using model's fromMap method
      repoList.add(Repo.fromMap(row));
    }

    // update repo model's repo list property to show repo list
    repoModel.updateRepo(repoList);
  }
}
