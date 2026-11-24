import 'dart:convert';
import 'package:auth/api_config.dart';
import 'package:auth/user.dart';
import 'package:auth/dashboard.dart';
import 'package:auth/register.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();

  String get url => "${ApiConfig.baseUrl}/login";

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<User> save(String email, String password) async {
    var res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    print(res.body);
    if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
      return User.fromMap(jsonDecode(res.body));
    } else {
      throw Exception('Failed to login.');
    }
  }

  Future<void> handleSignIn() async {
    if (_formKey.currentState == null) return;
    if (_formKey.currentState!.validate()) {
      try {
        User u = await save(_emailController.text, _passwordController.text);
        print(u.email);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Dashboard(user: u)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not log in with these credentials!',
              style: TextStyle(fontSize: 16.0),
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  height: 520.0,
                  width: 340.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Welcome Back",
                          style: GoogleFonts.roboto(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          "Sign in to continue",
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "Email",
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is empty';
                          }
                          return null;
                        },
                        style: TextStyle(
                            fontSize: 18, color: Colors.blueGrey.shade700),
                        decoration: InputDecoration(
                          errorStyle: const TextStyle(
                              fontSize: 14, color: Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'admin@gmail.com',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "Password",
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is Empty';
                          }
                          return null;
                        },
                        style: TextStyle(
                            fontSize: 18, color: Colors.blueGrey.shade700),
                        decoration: InputDecoration(
                          errorStyle: const TextStyle(
                              fontSize: 14, color: Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: '••••••••',
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: handleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Login",
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Register()),
                    );
                  },
                  child: Text(
                    "Don't have an account? Register",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
