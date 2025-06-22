import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: 200,
        width: 300,
        child: Card(
          child: Column(
            children: [
              TextField(),
              TextField(),
              Text("data"),
              ElevatedButton(onPressed: () {}, child: Text("Login")),
              TextButton(onPressed: () {}, child: Text("Sign Up")),
            ],
          ),
        ),
      ),
    );
  }
}
