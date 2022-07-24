import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'constants.dart';
import 'network_helper.dart';
import 'repo.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: ((context) => RepoModel()),
      child: MaterialApp(
        title: 'PHP Project demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'PHP Projects in GitHub'),
      ),
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

  late String path;
  late Database database;
  late var rawData;
  var dbItemList = [];
  List<Repo> repoList = [];
  var showList = false;
  var isLoading = true;
  late RepoModel repoModel;
  var dbHasData = false;
  var count;

  void setupDB() async {
    // var databasesPath = await getDatabasesPath();
    Directory dbpath = await getApplicationDocumentsDirectory();
    path = join(dbpath.path, 'demo.db');

    // open the database
    database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      // When creating the db, create the table
      await db.execute(
          'CREATE TABLE $tableName ($columnId INTEGER PRIMARY KEY, $columnRepoId INTEGER, $columnName TEXT, $columnDescription TEXT, $columnUrl TEXT, $columnStarCount INTEGER, $columnCreatedAt DATETIME, $columnPushedAt DATETIME)');
    });

    count = Sqflite.firstIntValue(
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
    // if (repoList.isEmpty) {
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
    // }
    // if (repoList.isNotEmpty) {
    //   repoList = [];
    // }
    addToRepoList();
  }

  void refreshRecord() async {
    // Delete a record

    await database.rawDelete('DELETE FROM $tableName');

    if (count == 0) {
      repoList = [];
      fetchAddData();
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

  void deleteDB() async {
    await deleteDatabase(path);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    repoModel = Provider.of<RepoModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: refreshRecord,
          ),
        ],
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InkWell(
              onTap: refreshRecord,
              child: const Text(
                'Most popular PHP Projects in Github',
              ),
            ),
            // const SizedBox(
            //   height: 30,
            // ),
            // InkWell(
            //   onTap: fetchRecord,
            //   child: const Text(
            //     'Fetch Data',
            //   ),
            // ),
            const SizedBox(
              height: 15,
            ),
            // InkWell(
            //   onTap: toggleShowList,
            //   child: const Text(
            //     'Show Data',
            //   ),
            // ),
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
            // if (showList)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              // child: Text('List goes on.. with this ${repoList.first.name}'),
              child: Consumer<RepoModel>(
                builder: ((context, value, _) => ListView.builder(
                      itemCount: value.getRepo().length,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 5,
                          ),
                          child: ListTile(
                            onTap: (() => showModalBottomSheet(
                                context: context,
                                builder: (bCtx) {
                                  return SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.6,
                                    child: Column(
                                      children: [
                                        ListTile(
                                          leading: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: const [
                                                Text('Name', style: TextStyle(fontWeight: FontWeight.bold),),
                                                Text('Repo ID', style: TextStyle(fontWeight: FontWeight.bold),),
                                              ]),
                                          title: Row(
                                            children: [
                                              Text(value.getRepo()[index].name),
                                              const SizedBox(
                                                width: 20,
                                              ),
                                              const Icon(
                                                Icons.star_border,
                                                size: 16,
                                              ),
                                              Text(value
                                                  .getRepo()[index]
                                                  .stargazersCount
                                                  .toString()),
                                            ],
                                          ),
                                          subtitle: Text(value
                                              .getRepo()[index]
                                              .id
                                              .toString()),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold),),
                                              Text(value
                                                  .getRepo()[index]
                                                  .description),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                children: [
                                                  const Text('URL: ', style: TextStyle(fontWeight: FontWeight.bold),),
                                                  Text(value
                                                      .getRepo()[index]
                                                      .htmlUrl),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                children: [
                                                  const Text('Created: ', style: TextStyle(fontWeight: FontWeight.bold),),
                                                  Text(
                                                    value
                                                        .getRepo()[index]
                                                        .createdAt,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                children: [
                                                  const Text('Last pushed: ', style: TextStyle(fontWeight: FontWeight.bold),),
                                                  Text(value
                                                      .getRepo()[index]
                                                      .pushedAt),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })),
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(value
                                    .getRepo()[index]
                                    .stargazersCount
                                    .toString()),
                                const Text('stars')
                              ],
                            ),
                            title: Text(value.getRepo()[index].name),
                            subtitle: Text(
                                value.getRepo()[index].description.length > 80
                                    ? value
                                        .getRepo()[index]
                                        .description
                                        .replaceRange(
                                            80,
                                            value
                                                .getRepo()[index]
                                                .description
                                                .length,
                                            '...')
                                    : value.getRepo()[index].description),
                          ),
                        );

                        //     Card(
                        //   elevation: 5,
                        //   margin: EdgeInsets.symmetric(
                        //     vertical: 8,
                        //     horizontal: 5,
                        //   ),
                        //   child: ListTile(
                        //     leading: CircleAvatar(
                        //       radius: 30,
                        //       child: Padding(
                        //         padding: EdgeInsets.all(6),
                        //         child: FittedBox(
                        //           child: Text('\$${transactions[index].amount}'),
                        //         ),
                        //       ),
                        //     ),
                        //     title: Text(
                        //       transactions[index].title,
                        //       style: Theme.of(context).textTheme.title,
                        //     ),
                        //     subtitle: Text(
                        //       DateFormat.yMMMd().format(transactions[index].date),
                        //     ),
                        //   ),
                        // );
                      },
                    )),
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

class RepoModel extends ChangeNotifier {
  late List<Repo> repos;

  RepoModel({List<Repo>? newRepos}) {
    repos = newRepos ?? <Repo>[];
  }

  void updateRepo(List<Repo> newRepos) {
    repos = newRepos;
    notifyListeners();
  }

  List<Repo> getRepo() {
    return repos;
  }
}
