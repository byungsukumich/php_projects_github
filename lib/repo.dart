import 'package:flutter/material.dart';
import 'constants.dart';

class Repo extends ChangeNotifier{
  late int id;
  late String name;
  late String description;
  late String htmlUrl;
  late int stargazersCount;
  late String createdAt;
  late String pushedAt;

  Repo(this.id, this.name, this.description, this.htmlUrl, this.stargazersCount,
      this.createdAt, this.pushedAt);

  Repo.fromMap(Map<dynamic, dynamic> map) {
    id = map[columnRepoId];
    name = map[columnName];
    description = map[columnDescription];
    htmlUrl = map[columnUrl];
    stargazersCount = map[columnStarCount];
    createdAt = map[columnCreatedAt];
    pushedAt = map[columnPushedAt];

  }

}
