import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hackfest/login_page.dart';
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

  Future<String> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Handle permission denied
      return '';
    }

    if (permission == LocationPermission.deniedForever) {
      // Handle permanently denied
      return '';
    }

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print(position.toString());
    return position.toString();
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    TextEditingController nameController = TextEditingController();
    TextEditingController adharCardController = TextEditingController();
    TextEditingController numberOfPeopleController = TextEditingController();
    TextEditingController locationController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: adharCardController,
            decoration: InputDecoration(labelText: 'Adhar Card Number'),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: numberOfPeopleController,
            decoration: InputDecoration(labelText: 'Number of People'),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: locationController,
            decoration: InputDecoration(labelText: 'Location'),
          ),
          SizedBox(height: 10),
          Text(locationController.text),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              String location = await _getCurrentLocation();
              locationController.text = location;
            },
            child: Text('Get Current Location'),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _registerUser(
                nameController.text,
                adharCardController.text,
                numberOfPeopleController.text,
                locationController.text,
                emailController.text,
                passwordController.text,
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text('Register'),
          ),
        ],
      ),
    );
  }
}
