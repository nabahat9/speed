import 'package:flutter/material.dart';

class OtpProvider with ChangeNotifier {
  String _otpCode = "";

  String get otpCode => _otpCode;

  void updateOtpCode(String value) {
    _otpCode = value;
    notifyListeners();
  }
}
