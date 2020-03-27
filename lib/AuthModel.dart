import 'package:provider/provider.dart';
import 'package:draw/draw.dart';
import 'package:flutter/foundation.dart';

class AuthModel with ChangeNotifier {
  Reddit reddit;

  void updateReddit(client) {
    reddit = client;
    notifyListeners();
  }
}
