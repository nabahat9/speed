import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication package
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database package
import 'package:flutter/material.dart'; // Import Flutter Material package for UI components
import 'package:intl_phone_number_input/intl_phone_number_input.dart'; // Import package for international phone number input
import 'package:user_app/authentication/otp_screen.dart';
import 'package:user_app/global/global_var.dart'; // Import global variables
import 'package:user_app/widgets/info_dialog.dart'; // Import custom dialog widget for displaying information
import '../methods/common_methods.dart'; // Import common methods used across the app
import '../pages/home_page.dart'; // Import the home page of the app
import '../widgets/loading_dialog.dart'; // Import custom loading dialog widget

class LoginScreen extends StatefulWidget {
   
  const LoginScreen({super.key});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
    String userName = "";
  String userPhone = "";
  // Controllers for user input fields
  TextEditingController numberTextEditingController = TextEditingController();
  TextEditingController userNameTextEditingController = TextEditingController();

  // Initial phone number setup with the country code for Algeria
  PhoneNumber initialPhoneNumber = PhoneNumber(isoCode: 'DZ', phoneNumber: '');

  // Instance of CommonMethods to use utility functions
  CommonMethods cMethods = CommonMethods();

  // Function to check network availability before proceeding with the login
  checkIfNetworkIsAvailable() {
    cMethods.checkConnectivity(context); // Check network connectivity
    signInFormValidation(); // Validate the sign-in form
  }

  // Function to validate the sign-in form
  signInFormValidation() {
    String phoneNumber = numberTextEditingController.text.trim();
    // Regular expression to validate Algerian phone numbers
    if (!RegExp(r'^(0(5|6|7)[0-9]{8}|(\+213)(5|6|7)[0-9]{8})$')
        .hasMatch(phoneNumber)) {
      // Show error dialog if phone number is invalid
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => InfoDialog(
                title: "Incorrect Phone Number",
                description:
                    "Please enter a valid phone number, including the correct country code.",
              ));
    } else {
      signInUser(); // Proceed with signing in the user
    }
  }

  // Function to sign in the user using phone number
  signInUser() async {
    // Show a loading dialog while the user is being authenticated
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          LoadingDialog(messageText: "Allowing you to Login..."),
    );

    String phoneNumber = numberTextEditingController.text.trim();
    if (!phoneNumber.startsWith("+")) {
      // If the phone number does not include a country code, add it
      phoneNumber = "+213" + phoneNumber.substring(1); // Remove leading '0'
    }

    // Firebase Authentication instance for signing in the user
    FirebaseAuth auth = FirebaseAuth.instance;

    // Verify the phone number and handle different stages of the verification process
    auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60), // Timeout duration for the verification
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Automatically sign in the user if the verification is completed
        UserCredential userCredential =
            await auth.signInWithCredential(credential);
        if (!context.mounted) return;
        handleUserSignIn(userCredential.user); // Handle post-sign-in logic
      },
      verificationFailed: (FirebaseAuthException e) {
        Navigator.pop(context); // Close the loading dialog
        cMethods.displaySnackBar(e.message.toString(), context); // Show error message
      },
      codeSent: (String verificationId, int? resendToken) async {
        // Navigate to the OTP screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              verificationId: verificationId,
              phoneNumber: phoneNumber,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Handle the timeout of auto-retrieval of the SMS code
      },
    );
  }

  // Function to handle user sign-in and navigate to the home page
  handleUserSignIn(User? userFirebase) async {
    Navigator.pop(context); // Close the loading dialog
    if (userFirebase != null) {
      // Reference to the user's data in the Firebase Realtime Database
      DatabaseReference usersRef = FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(userFirebase.uid);
      
      await usersRef.once().then((snap) {
        if (snap.snapshot.value != null) {
          // Check if the user's account is not blocked
          if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
            // Retrieve the user's name and phone number
            userName = (snap.snapshot.value as Map)["name"];
            userPhone = (snap.snapshot.value as Map)["phone"];
            // Navigate to the home page
            Navigator.push(
                context, MaterialPageRoute(builder: (c) => const HomePage()));
          } else {
            // Sign out the user if they are blocked and show an error message
            FirebaseAuth.instance.signOut();
            cMethods.displaySnackBar(
                "You are blocked. Contact admin: alizeb875@gmail.com", context);
          }
        } else {
          // Sign out the user if their record does not exist in the database
          FirebaseAuth.instance.signOut();
          cMethods.displaySnackBar(
              "Your record does not exist as a User.", context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Image.asset("assets/images/logo.png"), // App logo
              const Text(
                "Login as a User",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    InternationalPhoneNumberInput(
                      selectorConfig: const SelectorConfig(
                        selectorType: PhoneInputSelectorType.BOTTOM_SHEET, // Selector for country codes
                        setSelectorButtonAsPrefixIcon: true,
                        leadingPadding: 20,
                        useEmoji: true, // Show emoji flags
                      ),
                      hintText: 'Phone number', // Hint text for phone number input
                      validator: (userInput) {
                        // Validator for phone number input
                        if (userInput!.isEmpty) {
                          return 'Please enter your phone number';
                        }

                        if (!RegExp(r'^(\+|00)?[0-9]+$').hasMatch(userInput)) {
                          return 'Please enter a valid phone number';
                        }

                        return null; // Return null when the input is valid
                      },
                      onInputChanged: (PhoneNumber number) {
                        userPhone = number.phoneNumber ?? ''; // Handle null
                      },
                      onInputValidated: (bool value) {},
                      ignoreBlank: false,
                      autoValidateMode: AutovalidateMode.onUserInteraction, // Validate while user is typing
                      selectorTextStyle: const TextStyle(color: Colors.black),
                      initialValue: initialPhoneNumber, // Initial phone number
                      textFieldController: numberTextEditingController, // Controller for phone number input
                      formatInput: true,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                      onSaved: (PhoneNumber number) {
                        userPhone = number.phoneNumber ?? ''; // Handle null
                      },
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        checkIfNetworkIsAvailable(); // Check network and validate sign-in form
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 80, vertical: 10)),
                      child: const Text("Login"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}