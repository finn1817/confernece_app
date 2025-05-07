import 'package:flutter/material.dart';
import 'package:conference_app/app_theme.dart';
import 'package:conference_app/widgets/common_widgets.dart';
import 'package:conference_app/services/firebase_service.dart';

class TalkDetailScreen extends StatefulWidget {
  final Map<String, dynamic> talk;
  final bool isAdmin;
  final Function(Map<String, dynamic>) onUpdate;

  const TalkDetailScreen({
    required this.talk,
    required this.isAdmin,
    required this.onUpdate,
  });

  @override
  _TalkDetailScreenState createState() => _TalkDetailScreenState();
}

class _TalkDetailScreenState extends State<TalkDetailScreen> {
  late Map<String, dynamic> talk;
  bool isEditing = false;
  final FirebaseService _firebaseService = FirebaseService();

  late TextEditingController titleController;
  late TextEditingController speakerController;
  late TextEditingController descriptionController;
  late TextEditingController timeController;
  late TextEditingController locationController;
  late TextEditingController trackController;
  late TextEditingController dayController;
  late TextEditingController durationController;
  late TextEditingController attendeesController;

  @override
  void initState() {
    super.initState();
    talk = Map<String, dynamic>.from(widget.talk);
    titleController = TextEditingController(text: talk['title'] ?? '');
    speakerController = TextEditingController(text: talk['speaker'] ?? '');
    descriptionController = TextEditingController(text: talk['description'] ?? '');
    timeController = TextEditingController(text: talk['time'] ?? '');
    locationController = TextEditingController(text: talk['location'] ?? '');
    trackController = TextEditingController(text: talk['track'] ?? '');
    dayController = TextEditingController(text: talk['day'] ?? '');
    durationController = TextEditingController(text: talk['duration'] ?? '');
    attendeesController = TextEditingController(text: talk['attendees'] ?? '');
  }

  @override
  void dispose() {
    titleController.dispose();
    speakerController.dispose();
    descriptionController.dispose();
    timeController.dispose();
    locationController.dispose();
    trackController.dispose();
    dayController.dispose();
    durationController.dispose();
    attendeesController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      if (isEditing) {
        talk['title'] = titleController.text;
        talk['speaker'] = speakerController.text;
        talk['description'] = descriptionController.text;
        talk['time'] = timeController.text;
        talk['location'] = locationController.text;
        talk['track'] = trackController.text;
        talk['day'] = dayController.text;
        talk['duration'] = durationController.text;
        talk['attendees'] = attendeesController.text.trim();
        widget.onUpdate(talk);
        CommonWidgets.showNotificationBanner(
          context,
          message: 'Talk updated successfully',
        );
      }
      isEditing = !isEditing;
    });
  }

  Future<void> _showDeleteConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Talk', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black87,
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this talk?', style: TextStyle(color: Colors.white)),
                SizedBox(height: 8),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _firebaseService.deleteTalk(talk['id']).then((_) {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Talk deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }).catchError((error) {
                  Navigator.of(dialogContext).pop();
                  CommonWidgets.showNotificationBanner(
                    context,
                    message: 'Error deleting talk: \$error',
                    isError: true,
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color talkColor = talk.containsKey('colorCode')
        ? Color(int.parse(talk['colorCode'].substring(1, 7), radix: 16) + 0xFF000000)
        : AppTheme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Talk' : 'Talk Details', style: const TextStyle(color: Colors.white)),
        backgroundColor: talkColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.isAdmin) ...[
            IconButton(
              icon: Icon(isEditing ? Icons.save : Icons.edit),
              onPressed: _toggleEdit,
            ),
            if (!isEditing)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _showDeleteConfirmation,
              ),
          ],
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/im2.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isAdmin && (talk['hasMissingRegistration'] ?? false || talk['hasMissingCopyright'] ?? false))
                    Card(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: AppTheme.warningColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Admin Alert', style: AppTheme.bodyTextStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                                  if (talk['hasMissingRegistration'] ?? false)
                                    const Text('Registration data missing', style: TextStyle(color: Colors.white70)),
                                  if (talk['hasMissingCopyright'] ?? false)
                                    const Text('Copyright notice missing', style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  _buildField(label: 'Title', value: talk['title'] ?? 'Untitled Talk', controller: titleController, isEditing: isEditing),
                  const SizedBox(height: 16),
                  _buildField(label: 'Speaker', value: talk['speaker'] ?? 'Unknown Speaker', controller: speakerController, isEditing: isEditing, icon: Icons.person),
                  const SizedBox(height: 16),
                  _buildField(label: 'Attendees', value: talk['attendees'] ?? 'No attendees listed', controller: attendeesController, isEditing: isEditing, icon: Icons.people),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildField(label: 'Day', value: talk['day'] ?? 'TBD', controller: dayController, isEditing: isEditing, icon: Icons.calendar_today)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField(label: 'Time', value: talk['time'] ?? 'TBD', controller: timeController, isEditing: isEditing, icon: Icons.access_time)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildField(label: 'Location', value: talk['location'] ?? 'TBD', controller: locationController, isEditing: isEditing, icon: Icons.location_on)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField(label: 'Duration', value: talk['duration'] ?? 'TBD', controller: durationController, isEditing: isEditing, icon: Icons.timer)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildField(label: 'Track', value: talk['track'] ?? 'General', controller: trackController, isEditing: isEditing, icon: Icons.category),
                  const SizedBox(height: 24),
                  _buildField(label: 'Description', value: talk['description'] ?? 'No description available', controller: descriptionController, isEditing: isEditing, isMultiline: true),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!isEditing) ...[
                        Expanded(
                          child: CommonWidgets.appButton(
                            text: 'Add to My Schedule',
                            onPressed: () {
                              CommonWidgets.showNotificationBanner(context, message: 'Added to your schedule');
                            },
                            icon: Icons.bookmark_add,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CommonWidgets.appButton(
                            text: 'Share',
                            onPressed: () {
                              CommonWidgets.showNotificationBanner(context, message: 'Sharing options');
                            },
                            icon: Icons.share,
                            isOutlined: true,
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: CommonWidgets.appButton(
                            text: 'Cancel',
                            onPressed: () {
                              setState(() {
                                titleController.text = widget.talk['title'] ?? '';
                                speakerController.text = widget.talk['speaker'] ?? '';
                                descriptionController.text = widget.talk['description'] ?? '';
                                timeController.text = widget.talk['time'] ?? '';
                                locationController.text = widget.talk['location'] ?? '';
                                trackController.text = widget.talk['track'] ?? '';
                                dayController.text = widget.talk['day'] ?? '';
                                durationController.text = widget.talk['duration'] ?? '';
                                attendeesController.text = widget.talk['attendees'] ?? '';
                                isEditing = false;
                              });
                            },
                            backgroundColor: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CommonWidgets.appButton(
                            text: 'Save Changes',
                            onPressed: _toggleEdit,
                            backgroundColor: AppTheme.successColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    IconData? icon,
    bool isMultiline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        if (isEditing)
          CommonWidgets.textField(
            label: label,
            controller: controller,
            isMultiline: isMultiline,
          )
        else
          Row(
            crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
