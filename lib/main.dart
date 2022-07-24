import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'constants.dart';
import 'network_helper.dart';
import 'repo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PHP Project demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'PHP Projects in GitHub'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    setupDB();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  late String path;
  late Database database;
  late var rawData;
  var dbItemList = [];
  List<Repo> repoList = [];
  var showList = false;
  var isLoading = true;

  void toggleShowList() {
    setState(() {
      showList = !showList;
    });
    addToRepoList();
  }

  void setupDB() async {
    var databasesPath = await getDatabasesPath();
    Directory dbpath = await getApplicationDocumentsDirectory();
    path = join(dbpath.path, 'demo.db');

    // open the database
    database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      // When creating the db, create the table
      await db.execute(
          'CREATE TABLE $tableName ($columnId INTEGER PRIMARY KEY, $columnRepoId INTEGER, $columnName TEXT, $columnDescription TEXT, $columnUrl TEXT, $columnStarCount INTEGER, $columnCreatedAt DATETIME, $columnPushedAt DATETIME)');
    });

    var row = await database.rawQuery('SELECT 1 FROM $tableName');
    if (row.isEmpty) {
      fetchAddData();
    }
  }

  void fetchRecord() async {
    var isActive = await databaseExists(path);
    // Get the records
    if (isActive) {
      List<Map> list = await database.rawQuery('SELECT * FROM $tableName');
      print(list);
      // print('this is rawData: $rawData');
      // print('this is repo list: $dbItemList');
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
    rawData = await NetworkHelper().getData();

    var repoItems = rawData['items'];

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
    if (repoList.isNotEmpty) {
      repoList = [];
    }
    addToRepoList();
  }

  void refreshRecord() async {
    // Delete a record
    await database.rawDelete('DELETE FROM $tableName');
    fetchAddData();

    print('succefully refreshed repo data from github');
  }

  Future<List<Repo>> addToRepoList() async {
    if (repoList.isEmpty) {
      List<Map<dynamic, dynamic>> list =
          await database.rawQuery('SELECT * FROM $tableName');

      if (list.isEmpty) {
        print('empty list!');
        return [];
      }

      for (var row in list) {
        repoList.add(Repo.fromMap(row));
        print('repo name: ${Repo.fromMap(row).name}');
      }
      print('list of repo count : ${repoList.length}');
    }

    setState(() {
      isLoading = false;
    });
    return repoList;
  }

  void deleteDB() async {
    await deleteDatabase(path);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    updateReady() {}
    // Widget showResult() {
    //   var result = 'not ready';

    //   setState(() {
    //     if (repoList.isNotEmpty) {
    //       result = repoList.first.name;
    //     }
    //   });
    //   return Text(result);
    // }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete DB',
            onPressed: deleteDB,
          ),
        ],
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            InkWell(
              onTap: refreshRecord,
              child: const Text(
                'Reload Data',
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            InkWell(
              onTap: fetchRecord,
              child: const Text(
                'Fetch Data',
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            InkWell(
              onTap: toggleShowList,
              child: const Text(
                'Show Data',
              ),
            ),
            // isLoading
            //     ? const CircularProgressIndicator()
            //     : SizedBox(
            //         height: 400,
            //         // child: Text('List goes on.. with this ${repoList.first.name}'),
            //         child: Center(
            //           child: ListView.builder(
            //             itemCount: repoList.length,
            //             itemBuilder: (BuildContext context, int index) {
            //               return ListTile(
            //                 leading: Text(
            //                     repoList[index].stargazersCount.toString()),
            //                 title: Text(repoList[index].name),
            //               );
            //             },
            //           ),
            //         ),
            //       ),
            if (showList)
              SizedBox(
                height: 400,
                // child: Text('List goes on.. with this ${repoList.first.name}'),
                child: Center(
                  child: ListView.builder(
                    itemCount: repoList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        leading:
                            Text(repoList[index].stargazersCount.toString()),
                        title: Text(repoList[index].name),
                      );
                    },
                  ),
                ),
              )
            // child: FutureBuilder<List<Repo>>(
            //   future: addToRepoList(),
            //   builder: (context, snapshot) {
            //     if (snapshot.connectionState == ConnectionState.done) {
            //       if (snapshot.hasData) {
            //         return Center(
            //           child: Text(snapshot.data?.first.name ?? ''),
            //         );
            //       } else if (snapshot.hasError) {
            //         return Center(child: Text('Error!: ${snapshot.error.toString()}'),);
            //       } else {
            //         return const Center(child: Text('What doe..'),);
            //       }
            //     }
            //     return const SizedBox(
            //           width: 60,
            //           height: 60,
            //           child: CircularProgressIndicator(),
            //         );

            //   },
            // ),
            //   ),
          ],
        ),
      ),
    );
  }
}
