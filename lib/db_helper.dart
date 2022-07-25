import 'dart:io';
import 'constants.dart';
import 'network_helper.dart';
import 'repo.dart';
import 'providers.dart';
import 'package:flutter/material.dart';
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
  var dbHasData = false;
  late DateTime timeStamp;

  void setupDB() async {
    // var databasesPath = await getDatabasesPath();
    Directory dbpath = await getApplicationDocumentsDirectory();
    path = join(dbpath.path, 'repo.db');

    // open the database
    database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      // When creating the db, create the table
      await db.execute(
          'CREATE TABLE $tableName ($columnId INTEGER PRIMARY KEY, $columnRepoId INTEGER, $columnName TEXT, $columnDescription TEXT, $columnUrl TEXT, $columnStarCount INTEGER, $columnCreatedAt DATETIME, $columnPushedAt DATETIME)');
    });

    var count = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM $tableName'));

    print('this is row count: $count');

    if (count == 0) {
      fetchAddData();
    } else {
      addToRepoList();
    }
  }

  void checkDataAvailable() async {
    var row = await database.rawQuery('SELECT 1 FROM $tableName');
    if (row.isNotEmpty) {
      dbHasData = true;
    }
  }

  void fetchRecord() async {
    var isActive = await databaseExists(path);
    // Get the records
    if (isActive) {
      List<Map> list = await database.rawQuery('SELECT * FROM $tableName');
    } else {
      print('no records in db');
    }
  }

  void addRecord(List input) async {
    // Insert some records in a transaction
    await database.transaction((txn) async {
      int id1 = await txn.rawInsert(
          'INSERT INTO $tableName($columnRepoId, $columnName, $columnDescription, $columnUrl, $columnStarCount, $columnCreatedAt, $columnPushedAt) VALUES(?,?,?,?,?,?,?)',
          input);
      print('inserted1: $id1');
    });
  }

  void fetchAddData() async {
    feedData = await NetworkHelper().getData();

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

    addToRepoList();
  }

  void refreshRecord() async {
    // Delete a record

    await database.rawDelete('DELETE FROM $tableName');

    var count = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM $tableName'));

    if (count == 0) {
      print('table data is erased');
      repoList = [];
      fetchAddData();
      var timeStamp = DateTime.now();
      var formatedTime =
          "${timeStamp.year.toString()}-${timeStamp.month.toString().padLeft(2, '0')}-${timeStamp.day.toString().padLeft(2, '0')} ${timeStamp.hour.toString().padLeft(2, '0')}:${timeStamp.minute.toString().padLeft(2, '0')}:${timeStamp.second.toString().padLeft(2, '0')}";
      repoModel.updateTimeStamp(formatedTime);
    }

    print('succefully refreshed repo data from github');
  }

  void addToRepoList() async {
    List<Map<dynamic, dynamic>> list =
        await database.rawQuery('SELECT * FROM $tableName');

    if (list.isEmpty) {
      print('empty list!');
    }

    for (var row in list) {
      repoList.add(Repo.fromMap(row));
      print('repo name: ${Repo.fromMap(row).name}');
    }
    print('list of list count : ${list.length}');
    print('list of repo count : ${repoList.length}');

    repoModel.updateRepo(repoList);
  }


}