import 'dart:io';
import 'constants.dart';
import 'network_helper.dart';
import 'repo.dart';
import 'providers.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
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
          primarySwatch: Colors.green,
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
              child: Consumer<RepoModel>(
                builder: (context, repo, _) => repo.getTimeStamp() == ''
                    ? const Text(
                        'Most popular PHP Projects in Github',
                      )
                    : Text('Last updated at ${repo.getTimeStamp()}'),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
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
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(value
                                    .getRepo()[index]
                                    .stargazersCount
                                    .toString()),
                                const Icon(
                                  Icons.star_border,
                                  color: Colors.lightGreen,
                                )
                              ],
                            ),
                            title: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                value.getRepo()[index].name,
                                style: boldStyle,
                              ),
                            ),
                            subtitle: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(0, 5.0, 0, 5.0),
                              child: Text(
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
                            onTap: (() => showModalBottomSheet(
                                context: context,
                                builder: (_) {
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
                                                Text(
                                                  genericName,
                                                  style: boldStyle,
                                                ),
                                              ]),
                                          title: Row(
                                            children: [
                                              Text(
                                                value.getRepo()[index].name,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green),
                                              ),
                                              const SizedBox(
                                                width: 20,
                                              ),
                                              const Icon(
                                                Icons.star_border,
                                                color: Colors.lightGreen,
                                                size: 16,
                                              ),
                                              Text(value
                                                  .getRepo()[index]
                                                  .stargazersCount
                                                  .toString()),
                                            ],
                                          ),
                                          subtitle: Row(
                                            children: [
                                              const Text(
                                                genericRepoId,
                                              ),
                                              Text(value
                                                  .getRepo()[index]
                                                  .id
                                                  .toString()),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                genericDescription,
                                                style: boldStyle,
                                              ),
                                              const SizedBox(
                                                height: 2,
                                              ),
                                              Text(value
                                                  .getRepo()[index]
                                                  .description),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                children: [
                                                  const Text(
                                                    genericUrl,
                                                    style: boldStyle,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      value
                                                          .getRepo()[index]
                                                          .htmlUrl,
                                                      softWrap: true,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                children: [
                                                  const Text(
                                                    genericCreatedAt,
                                                    style: boldStyle,
                                                  ),
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
                                                  const Text(
                                                    genericLastPushedAt,
                                                    style: boldStyle,
                                                  ),
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
                          ),
                        );
                      },
                    )),
              ),
            )
          ],
        ),
      ),
    );
  }
}
