import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AddWarningPage extends StatefulWidget {
  @override
  _AddWarningPageState createState() => _AddWarningPageState();
}

class _AddWarningPageState extends State<AddWarningPage> {
// Variables to store input values

  // Variables to store input values
  String disasterType = '';
  bool isSevere = false;
  String suggestion = '';
  TextEditingController locationController = TextEditingController();
  String location = '';

  // // Function to get current location
  // Future<void> _getCurrentLocation() async {
  //   Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);
  //   setState(() {
  //     locationController.text = '${position.latitude}, ${position.longitude}';
  //     location = '${position.latitude}, ${position.longitude}';
  //   });
  // }
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

  // Function to add warning to Firebase
  Future<void> _addWarningToFirebase() async {
    try {
      await FirebaseFirestore.instance.collection('updates').add({
        'disasterType': disasterType,
        'isSevere': isSevere,
        'suggestion': suggestion,
        'location': location,
        'timestamp': DateTime.now(),
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Warning Posted Successfully')));
      Navigator.pop(context);
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
            Row(
              children: [
                Checkbox(
                  value: isSevere,
                  onChanged: (value) {
                    setState(() {
                      isSevere = value!;
                    });
                  },
                ),
                Text('Is Severe?'),
              ],
            ),
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
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(labelText: 'Suggestion'),
              onChanged: (value) {
                setState(() {
                  suggestion = value;
                });
              },
            ),
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
