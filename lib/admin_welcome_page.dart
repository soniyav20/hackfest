import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hackfest/map_page.dart';

class AdminWelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('distress').snapshots(),
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

          List<Map<String, dynamic>> distressList = [];
          snapshot.data!.docs.forEach((DocumentSnapshot doc) {
            distressList.add(doc.data() as Map<String, dynamic>);
          });

          return ListView.builder(
            itemCount: distressList.length,
            itemBuilder: (BuildContext context, int index) {
              Map<String, dynamic> distress = distressList[index];
              return ListTile(
                title: Text(distress['type']),
                subtitle: Text('Location: ${distress['location']}'),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MapPage(location: distress['location']),
                      ),
                    );
                  },
                  child: Text('Show on Map'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
