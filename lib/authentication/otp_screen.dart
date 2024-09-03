import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/admin/directory_v1.dart';
import 'package:pinput/pinput.dart';
import '../methods/common_methods.dart';
import '../pages/home_page.dart';
import '../widgets/loading_dialog.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String userName = '';
  final String userPhone ='';

  const OtpScreen({
    Key? key,
    required this.verificationId,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final CommonMethods _commonMethods = CommonMethods();

  Future<void> _verifyOtp() async {
    String otpCode = _otpController.text.trim();
    if (otpCode.isNotEmpty) {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpCode,
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            LoadingDialog(messageText: "Verifying OTP..."),
      );

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        if (!context.mounted) return;
        Navigator.pop(context); // Close the loading dialog
        Navigator.pop(context); // Navigate back to the login screen

        final DatabaseReference usersRef = FirebaseDatabase.instance
            .ref()
            .child("users")
            .child(userCredential.user!.uid);

        await usersRef.once().then((snap) {
          if (snap.snapshot.value != null) {
            // User exists, navigate to the home page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else {
            // User does not exist, sign them out
            FirebaseAuth.instance.signOut();
            _commonMethods.displaySnackBar(
                "Your record does not exist as a User.", context);
          }
        });
      } catch (e) {
        Navigator.pop(context); // Close the loading dialog
        _commonMethods.displaySnackBar(
            "Invalid OTP. Please try again.", context);
      }
    } else {
      _commonMethods.displaySnackBar(
          "Please enter the OTP sent to your phone.", context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Enter the OTP sent to your phone",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: "OTP Code",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _verifyOtp,
              child: const Text("Verify"),
            ),
          ],
        ),
      ),
    );
  }
}