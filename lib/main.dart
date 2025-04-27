import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'talk_detail_screen.dart';
import 'talk_form_screen.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ConferenceApp());
}

class ConferenceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conference App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TalkListScreen(),
    );
  }
}

class TalkListScreen extends StatefulWidget {
  @override
  _TalkListScreenState createState() => _TalkListScreenState();
}

class _TalkListScreenState extends State<TalkListScreen> {
  bool isAdmin = false;
  bool isFirebaseConnected = true; // You can keep this for visibility
  
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> talks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load talks from Firestore
    loadTalks();
  }

  void loadTalks() {
    _firebaseService.getTalks().listen((talksList) {
      setState(() {
        talks = talksList;
        isLoading = false;
      });
    }, onError: (error) {
      print('Error loading talks: $error');
      setState(() {
        isLoading = false;
        isFirebaseConnected = false;
      });
    });
  }

  void updateTalk(Map<String, dynamic> updatedTalk) {
    _firebaseService.updateTalk(updatedTalk['id'], updatedTalk);
    // The UI will update automatically due to the stream listener
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conference Talks'),
        actions: [
          // Firebase status indicator
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              isFirebaseConnected ? Icons.cloud_done : Icons.cloud_off,
              color: isFirebaseConnected ? Colors.green : Colors.red,
            ),
          ),
          // Toggle for admin/user view
          IconButton(
            icon: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person),
            onPressed: () {
              setState(() {
                isAdmin = !isAdmin;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isAdmin ? 'Admin mode activated' : 'User mode activated')),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : talks.isEmpty
              ? Center(child: Text('No talks available. Add a talk to get started!'))
              : ListView.builder(
                  itemCount: talks.length,
                  itemBuilder: (context, index) {
                    final talk = talks[index];
                    // Convert color code string to Color
                    Color talkColor = Color(int.parse(talk['colorCode'].substring(1, 7), radix: 16) + 0xFF000000);
                    
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: talkColor, width: 2),
                      ),
                      child: ListTile(
                        title: Text(talk['title']),
                        subtitle: Text('${talk['speaker']} - ${talk['time']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(talk['location']),
                            if (isAdmin && (talk['hasMissingRegistration'] ?? false || talk['hasMissingCopyright'] ?? false))
                              Icon(Icons.warning, color: Colors.amber),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TalkDetailScreen(
                                talk: talk,
                                isAdmin: isAdmin,
                                onUpdate: updateTalk,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TalkFormScreen(
                onSave: (newTalk) {
                  _firebaseService.addTalk(newTalk).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('New talk added')),
                    );
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding talk: $error')),
                    );
                  });
                },
              ),
            ),
          );
        },
      ) : null, // Only show the button for admin users
    );
  }
}