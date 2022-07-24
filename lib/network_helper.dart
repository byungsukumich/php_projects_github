import 'package:http/http.dart' as http;
import 'dart:convert';


class NetworkHelper {
  final String url = "https://api.github.com/search/repositories?q=php+language:php&sort=stars&order=desc";

  Future getData() async {
    http.Response response = await http.get(Uri.parse(url), headers: {'Content-type': 'application/json; charset=utf-8'});

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      return null;
    }

  }
}