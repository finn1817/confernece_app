// lib/screens/user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:conference_app/models/user.dart';
import 'package:conference_app/services/firebase_service.dart';
import 'package:conference_app/widgets/common_widgets.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _svc = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: StreamBuilder<List<User>>(
        stream: _svc.getUsers(),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return CommonWidgets.emptyState(
              message: 'Error loading users',
              icon: Icons.error,
              onAction: () => setState(() {}),
              actionLabel: 'Retry',
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snap.data!;
          if (users.isEmpty) {
            return CommonWidgets.emptyState(
              message: 'No users defined',
              icon: Icons.person_off,
              onAction: () => setState(() {}),
              actionLabel: 'Reload',
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (ctx, i) => _buildUserTile(users[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_add),
        onPressed: _showAddUserDialog,
      ),
    );
  }

  Widget _buildUserTile(User u) {
    return ListTile(
      leading: const Icon(Icons.person),
      title: Text(u.username),
      subtitle: const Text('••••••'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: u.isAdmin,
            onChanged: (val) => _toggleAdmin(u, val),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(u),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAdmin(User u, bool makeAdmin) async {
    try {
      await _svc.updateUserRole(u.id, makeAdmin);
      CommonWidgets.showNotificationBanner(
        context,
        message: 'Updated ${u.username} to ${makeAdmin ? 'Admin' : 'User'}',
      );
    } catch (e) {
      CommonWidgets.showNotificationBanner(
        context,
        message: 'Error updating role',
        isError: true,
      );
    }
  }

  Future<void> _confirmDelete(User u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        title: Text('Delete ${u.username}?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dc, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _svc.deleteUser(u.id);
        CommonWidgets.showNotificationBanner(
          context,
          message: 'Deleted ${u.username}',
        );
      } catch (e) {
        CommonWidgets.showNotificationBanner(
          context,
          message: 'Error deleting user',
          isError: true,
        );
      }
    }
  }

  Future<void> _showAddUserDialog() async {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isAdmin = false;

    await showDialog<void>(
      context: context,
      builder: (dc) => AlertDialog(
        title: const Text('Add New User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (c, setSt) => CheckboxListTile(
                value: isAdmin,
                title: const Text('Grant admin rights'),
                onChanged: (v) => setSt(() => isAdmin = v ?? false),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final u = User(
                id:       '',
                username: userCtrl.text.trim(),
                password: passCtrl.text,
                isAdmin:  isAdmin,
              );
              try {
                await _svc.addUser(u);
                Navigator.pop(dc);
                CommonWidgets.showNotificationBanner(
                  context,
                  message: 'User ${u.username} added',
                );
              } catch (e) {
                CommonWidgets.showNotificationBanner(
                  context,
                  message: 'Error adding user',
                  isError: true,
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
