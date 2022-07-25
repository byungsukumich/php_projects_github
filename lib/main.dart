import 'package:flutter/material.dart';
import 'constants.dart';
import 'db_helper.dart';
import 'providers.dart';
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
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: const RepoListHome(title: appTitle),
      ),
    );
  }
}

class RepoListHome extends StatefulWidget {
  const RepoListHome({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<RepoListHome> createState() => _RepoListHomeState();
}

class _RepoListHomeState extends State<RepoListHome> {
  DBHelper dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    dbHelper.setupDB();
  }

  @override
  Widget build(BuildContext context) {
    dbHelper.repoModel = Provider.of<RepoModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: dbHelper.refreshRecord,
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
              onTap: dbHelper.refreshRecord,
              child: Consumer<RepoModel>(
                builder: (context, repo, _) => repo.getTimeStamp() == ''
                    ? const Text(
                        appBarTitle,
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
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 2, 16, 16),
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
