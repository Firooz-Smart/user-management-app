import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_management_supabase/main.dart';
import 'package:user_management_supabase/views/login_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _usernameController = TextEditingController();
  final _websiteController = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getProfile();
  }

  Future<void> getProfile() async {
    setState(() {
      loading = true;
    });
    try {
      final userId = supabase.auth.currentUser!.id;
      final userData =
          await supabase.from('profiles').select().eq('id', userId).single();

      _usernameController.text = (userData['username'] ?? '') as String;
      _websiteController.text = (userData['website'] ?? '') as String;
    } on PostgrestException catch (e) {
      SnackBar(
        content: Text(e.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (e) {
      SnackBar(
        content: const Text('Unexpected error occurred'),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      loading = true;
    });
    final userName = _usernameController.text.trim();
    final website = _websiteController.text.trim();
    final user = supabase.auth.currentUser;

    final updates = {
      'id': user!.id,
      'username': userName,
      'website': website,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await supabase.from('profiles').upsert(updates);

      if (mounted) {
        const SnackBar(content: Text('Profile updated successfully!'));
      }
    } on PostgrestException catch (e) {
      SnackBar(
        content: Text(e.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (e) {
      SnackBar(
        content: const Text('Unexpected error occurred'),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      SnackBar(
        content: Text(e.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (e) {
      SnackBar(
        content: const Text('Unexpected error occurred'),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const LoginPage(),
            ));
      }
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _usernameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'User Name'),
                ),
                const SizedBox(
                  height: 18,
                ),
                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(labelText: 'Website'),
                ),
                const SizedBox(
                  height: 18,
                ),
                ElevatedButton(
                  onPressed: loading ? null : _updateProfile,
                  child: Text(loading ? 'Updating..' : 'Update'),
                ),
                const SizedBox(
                  height: 18,
                ),
                ElevatedButton(
                  onPressed: _signOut,
                  child: const Text('Sign Out'),
                ),
              ],
            ),
    );
  }
}
