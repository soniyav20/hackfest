import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCA5JJe1J3okqpAVkvICIg3eQB_CvvkJ-M",
      appId: "1:795621005285:android:985e46eb36c7a2171f410c",
      messagingSenderId: "795621005285",
      projectId: "hackfest-d74d3",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Internet Status App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InternetStatusPage(),
    );
  }
}

class InternetStatusPage extends StatefulWidget {
  @override
  _InternetStatusPageState createState() => _InternetStatusPageState();
}

class _InternetStatusPageState extends State<InternetStatusPage> {
  Color _statusColor = Colors.red; // Default color is red

  @override
  void initState() {
    super.initState();
    _checkInternetStatus();
  }

  void _checkInternetStatus() async {
    print(await InternetConnectionCheckerPlus().hasConnection);
    final listener = InternetConnectionCheckerPlus()
        .onStatusChange
        .listen((InternetConnectionStatus status) {
      setState(() {
        _statusColor = status == InternetConnectionStatus.connected
            ? Colors.green
            : Colors.red;
      });
    });
  }

  void _registerUser(String name, String adharCardNumber, String numberOfPeople,
      String location, String email, String password) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Get the user ID from userCredential
      String userID = userCredential.user!.uid;
      // Save user details to Firebase Firestore
      await FirebaseFirestore.instance.collection('users').doc(userID).set({
        'name': name,
        'adharCardNumber': adharCardNumber,
        'numberOfPeople': numberOfPeople,
        'location': location,
        'email': email,
      });
    } catch (e) {
      print("Error registering user: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Handle permission denied
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      // Handle permanently denied
      return;
    }

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print(position);
    // Handle user location
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hackfest'),
        backgroundColor: Colors.black12,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              color: _statusColor,
              width: double.infinity,
              child: Center(
                child: Text(
                  _statusColor == Colors.green ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildRegistrationForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    String name = '';
    String adharCardNumber = '';
    String numberOfPeople = '';
    String location = '';
    String email = '';
    String password = '';

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Name'),
            onChanged: (value) {
              name = value;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(labelText: 'Adhar Card Number'),
            onChanged: (value) {
              adharCardNumber = value;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(labelText: 'Number of People'),
            onChanged: (value) {
              numberOfPeople = value;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(labelText: 'Location'),
            onChanged: (value) {
              location = value;
            },
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _getCurrentLocation,
            child: Text('Get Current Location'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // Open map for selecting location
              // You can use packages like google_maps_flutter or location_picker
            },
            child: Text('Select Location on Map'),
          ),
          SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(labelText: 'Email'),
            onChanged: (value) {
              email = value;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
            onChanged: (value) {
              password = value;
            },
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _registerUser(name, adharCardNumber, numberOfPeople, location,
                  email, password);
            },
            child: Text('Register'),
          ),
        ],
      ),
    );
  }
}
