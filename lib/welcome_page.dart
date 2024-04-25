import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hackfest/main.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class WelcomePage extends StatefulWidget {
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  Color _statusColor = Colors.green; // Default color is red

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hackfest'),
      ),
      body: Column(
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
          Center(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .get(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text("Something went wrong");
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Text("User not found");
                }

                Map<String, dynamic> data =
                    snapshot.data!.data() as Map<String, dynamic>;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Welcome, ${data['name']}"),
                    SizedBox(height: 10),
                    Text("Adhar Card Number: ${data['adharCardNumber']}"),
                    SizedBox(height: 10),
                    Text("Number of People: ${data['numberOfPeople']}"),
                    SizedBox(height: 10),
                    Text("Location: ${data['location']}"),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => InternetStatusPage()),
          );
        },
        child: Icon(Icons.logout),
      ),
    );
  }
}
