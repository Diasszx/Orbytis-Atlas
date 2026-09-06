import 'package:flutter/foundation.dart';

final class SessionExpiredNotifier extends ChangeNotifier {
  void notifySessionExpired() {
    notifyListeners();
  }
}
