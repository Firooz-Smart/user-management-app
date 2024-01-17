import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_management_supabase/views/account_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  bool _isRedirecting = false;
  late final TextEditingController emailController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    // TODO: implement initState
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (_isRedirecting) {
        return;
      }
      if (event.session != null) {
        _isRedirecting = true;

        Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (context) => const AccountPage(),
            ));
      }
    });

    super.initState();
  }

  Future<void> signIn() async {
    setState(() {
      _loading = true;
    });
    try {
      await Supabase.instance.client.auth.signInWithOtp(
          email: emailController.text.trim(),
          emailRedirectTo: kIsWeb
              ? null
              : 'io.supabase.flutterquickstart://login-callback/');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your email for login link'),
          ),
        );
        emailController.clear();
      }
    } on AuthException catch (e) {
      print(e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unexpected error occured'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    emailController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: _isRedirecting
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Sign in via the magic link with your email below'),
                const SizedBox(height: 18),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _loading ? null : signIn,
                  child: Text(_loading ? 'Loading' : 'Send Magic Link'),
                ),
              ],
            ),
    );
  }
}
