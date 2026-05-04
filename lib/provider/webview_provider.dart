import 'package:flutter/foundation.dart';

class PaymentWebViewProvider extends ChangeNotifier {
  double _progress = 0;
  String? _status;

  double get progress => _progress;
  String? get status => _status;

  void setProgress(double value) {
    _progress = value;
    notifyListeners();
  }

  void setStatus(String newStatus) {
    _status = newStatus;
    notifyListeners();
  }
}
