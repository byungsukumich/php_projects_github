import 'package:flutter/material.dart';
import 'repo.dart';

class RepoModel extends ChangeNotifier {
  late List<Repo> repos;
  var updatedAt = '';

  RepoModel({List<Repo>? newRepos}) {
    repos = newRepos ?? <Repo>[];
  }

  void updateRepo(List<Repo> newRepos) {
    repos = newRepos;
    notifyListeners();
  }

  void updateTimeStamp(String newTime) {
    updatedAt = newTime;
    notifyListeners();
  }

  List<Repo> getRepo() {
    return repos;
  }

  String getTimeStamp() {
    return updatedAt;
  }
}