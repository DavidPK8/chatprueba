import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyBJYcyDDWfl7XDELbrlSDM6nMSBjJkNOSI",
        authDomain: "flutterfirebase-12e3f.firebaseapp.com",
        databaseURL:
            "https://flutterfirebase-12e3f-default-rtdb.firebaseio.com",
        projectId: "flutterfirebase-12e3f",
        storageBucket: "flutterfirebase-12e3f.appspot.com",
        messagingSenderId: "293048034606",
        appId: "1:293048034606:web:432155ac5368e3f21246bf"),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(), 
    );
  }
}
