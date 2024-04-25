import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hackfest'),
        backgroundColor: Colors.black12,
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
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
