import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hackfest/user_online/welcome_page.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

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
    void _loginUser(String email, String password) async {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Navigate to welcome page after successful login
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomePage()),
        );
      } catch (e) {
        print("Error logging in: $e");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid Login')));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    String email = emailController.text;
                    String password = passwordController.text;
                    _loginUser(email, password);
                  },
                  child: Text('Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
