import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AddWarningPage extends StatefulWidget {
  @override
  _AddWarningPageState createState() => _AddWarningPageState();
}

class _AddWarningPageState extends State<AddWarningPage> {
// Variables to store input values
  String disasterType = '';
  String severity = '';
  String suggestion = '';
  String location = '';

// Function to get current location
  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      location = '${position.latitude}, ${position.longitude}';
    });
  }

// Function to add warning to Firebase
  Future<void> _addWarningToFirebase() async {
    try {
      await FirebaseFirestore.instance.collection('updates').add({
        'disasterType': disasterType,
        'severity': severity,
        'suggestion': suggestion,
        'location': location,
        'timestamp': DateTime.now(),
      });
      // Show success message or navigate back to previous screen
      // You can handle this based on your UI/UX flow
    } catch (e) {
      // Show error message
      print('Error adding warning: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Warning'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Disaster Type'),
              onChanged: (value) {
                setState(() {
                  disasterType = value;
                });
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Severity'),
              onChanged: (value) {
                setState(() {
                  severity = value;
                });
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Suggestion'),
              onChanged: (value) {
                setState(() {
                  suggestion = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: Text('Get Current Location'),
            ),
            Text(location), // Display current location
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _addWarningToFirebase,
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
