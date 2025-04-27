import 'package:flutter/material.dart';
import 'talk_form_screen.dart';

class TalkDetailScreen extends StatelessWidget {
  final Map<String, dynamic> talk;
  final bool isAdmin;
  final Function(Map<String, dynamic>) onUpdate;

  TalkDetailScreen({
    required this.talk, 
    this.isAdmin = false,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    Color talkColor = Color(int.parse(talk['colorCode'].substring(1, 7), radix: 16) + 0xFF000000);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Talk Details'),
        backgroundColor: talkColor,
        actions: isAdmin ? [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TalkFormScreen(
                    talk: talk, // Pass existing talk for editing
                    onSave: (updatedTalk) {
                      onUpdate(updatedTalk);
                      Navigator.pop(context); // Go back to details after update
                    },
                  ),
                ),
              );
            },
          ),
        ] : null,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              talk['title'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Speaker: ${talk['speaker']}'),
            Text('Time: ${talk['time']}'),
            Text('Location: ${talk['location']}'),
            SizedBox(height: 16),
            if (isAdmin) ...[
              Divider(),
              Text('ADMIN CONTROLS', style: TextStyle(fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: Text('Missing Registration'),
                value: talk['hasMissingRegistration'] ?? false,
                onChanged: (value) {
                  Map<String, dynamic> updatedTalk = {...talk};
                  updatedTalk['hasMissingRegistration'] = value;
                  onUpdate(updatedTalk);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Registration status updated')),
                  );
                },
              ),
              SwitchListTile(
                title: Text('Missing Copyright'),
                value: talk['hasMissingCopyright'] ?? false,
                onChanged: (value) {
                  Map<String, dynamic> updatedTalk = {...talk};
                  updatedTalk['hasMissingCopyright'] = value;
                  onUpdate(updatedTalk);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copyright status updated')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}