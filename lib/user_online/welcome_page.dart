import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hackfest/main.dart';
import 'package:hackfest/user_offline/login_offline.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  Color _statusColor = Colors.green; // Default color is red
  void _checkInternetStatus() async {
    print(await InternetConnectionCheckerPlus().hasConnection);
    final listener = InternetConnectionCheckerPlus()
        .onStatusChange
        .listen((InternetConnectionStatus status) {
      setState(() {
        _statusColor = status == InternetConnectionStatus.connected
            ? Colors.green
            : Colors.red;
        if (InternetConnectionStatus.connected == true) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => OfflineLoginPage()));
        }
      });
    });
  }

  static const List<String> _pageTitles = [
    'Updates',
    'Distress',
    'History',
    'Profile Details',
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _getCurrentLocationAndSave() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    String location = '${position.latitude}, ${position.longitude}';

    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'location': location,
      });
      setState(() {
        // Update the UI with the new location
      });
    }
  }

  Widget _buildProfileDetails() {
    return Center(
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .get(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _getCurrentLocationAndSave,
                child: Text('Update Location'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUpdates() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('updates').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        final updates = snapshot.data!.docs;

        return ListView.builder(
          itemCount: updates.length,
          itemBuilder: (BuildContext context, int index) {
            final update = updates[index];
            final bool isSevere = update['isSevere'];

            return ListTile(
              title: Text(
                update['disasterType'],
                style: TextStyle(
                    color: isSevere ? Colors.red : Colors.yellow,
                    fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                children: [
                  Text(
                      update['timestamp'].toDate().toString().substring(0, 16)),
                  Text('Suggestion: ${update['suggestion']}'),
                  Text('Severity: ${isSevere ? "High" : "Low"}'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('distress')
          .where('userID', isEqualTo: user!.uid)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text("Something went wrong");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text("No distress signals found");
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (BuildContext context, int index) {
            Map<String, dynamic> data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['type'].toString().toUpperCase()),
              subtitle: Text(
                  'Time: ${data['time'].toDate().toString().substring(0, 16)}'),
            );
          },
        );
      },
    );
  }

  void _addToDistressTable(String type) {
    FirebaseFirestore.instance.collection('distress').add({
      'userID': user!.uid,
      'type': type,
      'time': DateTime.now(),
      // Add more fields as needed
    });
  }

  Widget _buildDistress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("I am safe but I need food supply"),
          ElevatedButton(
            onPressed: () {
              _showConfirmationDialog("food");
            },
            child: Text('Ask Food'),
          ),
          SizedBox(height: 20),
          Text("I am at danger, Come and Save me"),
          ElevatedButton(
            onPressed: () {
              _showConfirmationDialog("sos");
            },
            child: Text('SOS'),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content:
              Text('Are you sure you want to send a $type distress signal?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addToDistressTable(type);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Distress signal sent sucessfully'),
                  ),
                );
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 3:
        return _buildProfileDetails();
      case 0:
        return _buildUpdates();
      case 1:
        return _buildDistress();
      case 2:
        return _buildHistory();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        backgroundColor: Colors.black12,
      ),
      body: _buildPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.grey, //
        selectedItemColor: Colors.black54, // <-- add this

        backgroundColor: Colors.black12,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.update),
            label: 'Updates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Distress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
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
