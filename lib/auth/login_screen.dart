import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF72140C).withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 72,
                      color: Color(0xFF72140C),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF72140C),
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sign in to your FinTrack account',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email, color: Color(0xFF72140C)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Color(0xFF72140C), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock, color: Color(0xFF72140C)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Color(0xFF72140C), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() {
                                _isLoading = true;
                              });
                              try {
                                await Provider.of<AuthProvider>(context,
                                        listen: false)
                                    .login(
                                  _emailController.text,
                                  _passwordController.text,
                                );
                                Navigator.pushReplacementNamed(
                                    context, '/dashboard');
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Login failed: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Forgot password feature coming soon!')),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF72140C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account?',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF72140C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'By signing in, you agree to our Terms of Service and Privacy Policy',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ),
      ),
  );
}
}
