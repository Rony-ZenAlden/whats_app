import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:whats_app/Colors/default_color.dart';
import 'package:whats_app/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool doseUserWantToSignUp = false;
  Uint8List? selectedImage;
  bool errorInPicture = false;
  bool errorInName = false;
  bool errorInEmail = false;
  bool errorInPassword = false;
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  bool loadingOn = false;

  chooseImage() async {
    FilePickerResult? chosenImageFile =
        await FilePicker.platform.pickFiles(type: FileType.image);

    setState(() {
      selectedImage = chosenImageFile!.files.single.bytes;
    });
  }

  uploadImageToStorage(UserModel userData) {
    if (selectedImage != null) {
      Reference imageRef =
          FirebaseStorage.instance.ref('ProfileImages/${userData.uid}.jpg');
      UploadTask task = imageRef.putData(selectedImage!);
      task.whenComplete(() async {
        String urlImage = await task.snapshot.ref.getDownloadURL();
        userData.image = urlImage;

        //3. save userData to firestore database
        await FirebaseAuth.instance.currentUser
            ?.updateDisplayName(userData.name);
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(urlImage);

        final usersReference = FirebaseFirestore.instance.collection("users");
        usersReference.doc(userData.uid).set(userData.toJson()).then((value) {
          setState(() {
            loadingOn = false;
          });
          Navigator.pushReplacementNamed(context, "/home");
        });
      });
    } else {
      var snackBar = SnackBar(
        backgroundColor: DefaultColors.primaryColor,
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          backgroundColor: Colors.grey.shade300.withOpacity(0.2),
          onPressed: () {},
        ),
        content: const Text(
          'Please Choose Image',
          style: TextStyle(fontSize: 18),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  //1. create new user in firebase authentication
  signUpUserNow(nameInput, emailInput, passwordInput) async {
    final userCreated =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailInput,
      password: passwordInput,
    );

    //2. upload image to storage
    String? uidOfCreatedUser = userCreated.user!.uid;
    if (uidOfCreatedUser != null) {
      final userData =
          UserModel(uidOfCreatedUser, nameInput, emailInput, passwordInput);
      uploadImageToStorage(userData);
    }
  }

  loginUserNow(emailInput, passwordInput) {
    FirebaseAuth.instance
        .signInWithEmailAndPassword(
        email: emailInput, password: passwordInput)
        .then((value) {
      setState(() {
        loadingOn = false;
      });
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  formValidation() {
    setState(() {
      loadingOn = true;
      errorInEmail = false;
      errorInPassword = false;
      errorInName = false;
      errorInPicture = false;
    });

    String nameInput = nameTextEditingController.text.trim();
    String emailInput = emailTextEditingController.text.trim();
    String passwordInput = passwordTextEditingController.text.trim();

    if (emailInput.isNotEmpty && emailInput.contains("@")) {
      if (passwordInput.isNotEmpty && passwordInput.length > 7) {
        if (doseUserWantToSignUp == true) // signup form
        {
          if (nameInput.isNotEmpty && nameInput.length >= 3) {
            signUpUserNow(nameInput, emailInput, passwordInput);
          } else {
            var snackBar = SnackBar(
              backgroundColor: DefaultColors.primaryColor,
              duration: const Duration(days: 1),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                backgroundColor: Colors.grey.shade300.withOpacity(0.2),
                onPressed: () {},
              ),
              content: const Text(
                'Name is not valid',
                style: TextStyle(fontSize: 18),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        } else // login form
        {
          loginUserNow(emailInput, passwordInput);
        }
      } else {
        var snackBar = SnackBar(
          backgroundColor: DefaultColors.primaryColor,
          duration: const Duration(days: 1),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            backgroundColor: Colors.grey.shade300.withOpacity(0.2),
            onPressed: () {},
          ),
          content: const Text(
            'Password is not valid',
            style: TextStyle(fontSize: 18),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        setState(() {
          loadingOn = false;
        });
      }
    } else {
      // showDialog(
      //   context: context,
      //   builder: (ctx) => AlertDialog(
      //     alignment: Alignment.topLeft,
      //     title: const Text(
      //       'Invalid input',
      //       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
      //     ),
      //     content: const Text(
      //       'Please Enter Your Email Correct',
      //       style: TextStyle(fontSize: 15),
      //     ),
      //     actions: [
      //       TextButton(
      //         onPressed: () => Navigator.of(context).pop(),
      //         child: Text(
      //           'Okay',
      //           style: TextStyle(
      //               color: Colors.grey.shade800,
      //               fontWeight: FontWeight.bold,
      //               fontSize: 16),
      //         ),
      //       ),
      //     ],
      //   ),
      // );
      var snackBar = SnackBar(
        backgroundColor: DefaultColors.primaryColor,
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          backgroundColor: Colors.grey.shade300.withOpacity(0.2),
          onPressed: () {},
        ),
        content: const Text(
          'Email is not valid',
          style: TextStyle(fontSize: 18),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      setState(() {
        loadingOn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: DefaultColors.backgroundColor,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Positioned(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.5,
                color: DefaultColors.primaryColor,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Card(
                    elevation: 6,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      width: 500,
                      child: Column(
                        children: [
                          //profile Image

                          Visibility(
                            visible: doseUserWantToSignUp,
                            child: ClipOval(
                              child: selectedImage != null
                                  ? Image.memory(
                                      selectedImage!,
                                      width: 124,
                                      height: 124,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/images/avatar.png',
                                      width: 124,
                                      height: 124,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          //OutlinedButton Choose picture

                          Visibility(
                            visible: doseUserWantToSignUp,
                            child: OutlinedButton(
                              onPressed: () {
                                chooseImage();
                              },
                              style: errorInPicture
                                  ? OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          width: 3, color: Colors.red),
                                    )
                                  : null,
                              child: const Text('Choose Picture'),
                            ),
                          ),

                          //name text field
                          Visibility(
                            visible: doseUserWantToSignUp,
                            child: TextField(
                              keyboardType: TextInputType.text,
                              controller: nameTextEditingController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                hintText: 'write your name...',
                                suffixIcon: const Icon(Icons.person_outline),
                                enabledBorder: errorInName
                                    ? const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            width: 3, color: Colors.red),
                                      )
                                    : null,
                              ),
                            ),
                          ),

                          //email text field
                          TextField(
                            keyboardType: TextInputType.emailAddress,
                            controller: emailTextEditingController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'write your email...',
                              suffixIcon: const Icon(Icons.mail_outline),
                              enabledBorder: errorInEmail
                                  ? const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          width: 3, color: Colors.red),
                                    )
                                  : null,
                            ),
                          ),

                          //password text field
                          TextField(
                            keyboardType: TextInputType.text,
                            obscureText: true,
                            controller: passwordTextEditingController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: doseUserWantToSignUp
                                  ? "Must have Greater than 7 characters"
                                  : 'write your password...',
                              suffixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              enabledBorder: errorInPassword
                                  ? const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          width: 3, color: Colors.red),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(
                            height: 22,
                          ),
                          //login signup button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                formValidation();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DefaultColors.primaryColor,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: loadingOn
                                    ? const SizedBox(
                                        height: 19,
                                        width: 19,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        doseUserWantToSignUp
                                            ? 'Sign Up'
                                            : 'Login',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                              ),
                            ),
                          ),

                          //toggle button
                          Row(
                            children: [
                              const Text('Login'),
                              Switch(
                                value: doseUserWantToSignUp,
                                onChanged: (bool value) {
                                  setState(() {
                                    doseUserWantToSignUp = value;
                                  });
                                },
                              ),
                              const Text('Sign Up'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
