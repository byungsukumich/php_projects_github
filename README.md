# php_repo_v1

An app that shows most popular PHP projects written in PHP 

<img src="https://user-images.githubusercontent.com/92888762/180819188-1b7b9e4e-05f9-42e4-886d-348adb9a656e.PNG" width="400" />.   <img src="https://user-images.githubusercontent.com/92888762/180819216-e04908d7-f235-4569-a408-0584ff13d8bc.PNG" width="400" />

## Installation note

Flutter version : 2.10.5

Packages used:
 - http : getting json data from github api
 - path, path_provider : constructing database path
 - sqflite : creating database and table
 - provider : state management


## How it works - files in MVC pattern

- main : entry point and responsible for rendering views (View)
- db_helper : creating database and table, then calling network_helper to fetch data for producing repo list (Controller)
- network_helper : getting json feed from Github Search api - top 30 results with default per_page parameter (Controller)
- repo : Repository model and constructors (Model/Data)
- providers : repo model's state management (Model/Data)
- constants : listing static variables


## Flutter in general

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
