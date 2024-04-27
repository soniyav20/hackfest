import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hackfest/add_warning_page.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminWelcomePage extends StatefulWidget {
  @override
  State<AdminWelcomePage> createState() => _AdminWelcomePageState();
}

class _AdminWelcomePageState extends State<AdminWelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('What do people around\n me need?'),
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

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              Map<String, dynamic> distress =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              // Fetch user details using user ID
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(distress['userID'])
                    .get(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(
                      title: Text(distress['type'].toString().toUpperCase()),
                      subtitle: Text('User not found'),
                    );
                  }

                  Map<String, dynamic> userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  String location = userData['location'];

                  return ListTile(
                    title: Text(
                      distress['type'].toString().toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      children: [
                        Text('Name: ${userData['name']}'),
                        Text('People: ${userData['numberOfPeople']}'),
                        Text(
                            'Time: ${distress['time'].toDate().toString().substring(0, 16)}'),
                        Text('Location: ${location}'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Future<void> _launchUrl() async {
                          if (!await launchUrl(
                              Uri.parse("https://www.google.com/maps/"))) {
                            throw Exception(
                                'Could not launch https://www.google.com/maps/');
                          }
                        }

                        _launchUrl();

                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => MapPage(location: location),
                        //   ),
                        // );
                      },
                      child: Text('Show on Map'),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => AddWarningPage()));
        },
        child: Icon(
          Icons.warning,
          color: Colors.red,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}
