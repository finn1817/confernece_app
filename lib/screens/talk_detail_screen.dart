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
  bool isFavorite = false; // New feature: favorite talks
  final FirebaseService _firebaseService = FirebaseService();
  
  // all controllers for the edit fields in the app
  late TextEditingController titleController;
  late TextEditingController speakerController;
  late TextEditingController descriptionController;
  late TextEditingController timeController;
  late TextEditingController locationController;
  late TextEditingController trackController;
  late TextEditingController dayController;
  late TextEditingController durationController;
  late TextEditingController attendeesController; // newest database add - for attendees (users)
  
  @override
  void initState() {
    super.initState();
    talk = Map<String, dynamic>.from(widget.talk);
    
    // Check if this talk is already a favorite
    isFavorite = talk['isFavorite'] ?? false;
    
    // start the controllers with these existing values
    titleController = TextEditingController(text: talk['title'] ?? '');
    speakerController = TextEditingController(text: talk['speaker'] ?? '');
    descriptionController = TextEditingController(text: talk['description'] ?? '');
    timeController = TextEditingController(text: talk['time'] ?? '');
    locationController = TextEditingController(text: talk['location'] ?? '');
    trackController = TextEditingController(text: talk['track'] ?? '');
    dayController = TextEditingController(text: talk['day'] ?? '');
    durationController = TextEditingController(text: talk['duration'] ?? '');
    attendeesController = TextEditingController(text: talk['attendees'] ?? ''); // start call on attendees
  }

  @override
  void dispose() {
    // clear old data from controllers
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
        // save feature before exiting edit mode
        talk['title'] = titleController.text;
        talk['speaker'] = speakerController.text;
        talk['description'] = descriptionController.text;
        talk['time'] = timeController.text;
        talk['location'] = locationController.text;
        talk['track'] = trackController.text;
        talk['day'] = dayController.text;
        talk['duration'] = durationController.text;
        talk['attendees'] = attendeesController.text.trim();
        
        // update widget through callback
        widget.onUpdate(talk);
        
        CommonWidgets.showNotificationBanner(
          context,
          message: 'Talk updated successfully',
        );
      }
      
      isEditing = !isEditing;
    });
  }
  
  // New feature: Toggle favorite status
  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
      talk['isFavorite'] = isFavorite;
      
      // Update in Firebase
      _firebaseService.updateTalk(talk['id'], {'isFavorite': isFavorite}).then((_) {
        CommonWidgets.showNotificationBanner(
          context,
          message: isFavorite ? 'Added to favorites' : 'Removed from favorites',
        );
      }).catchError((error) {
        // Revert state if error
        setState(() {
          isFavorite = !isFavorite;
          talk['isFavorite'] = isFavorite;
        });
        
        CommonWidgets.showNotificationBanner(
          context,
          message: 'Error updating favorite status: $error',
          isError: true,
        );
      });
    });
  }
  
  // New feature: Export talk details
  void _exportTalkDetails() {
    // In a real app, this would generate a PDF or calendar event
    CommonWidgets.showNotificationBanner(
      context,
      message: 'Talk details exported to calendar',
    );
  }
  
  // show the delete confirmation log at the bottom of the app when used
  Future<void> _showDeleteConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) { // used dialogContext instead of context for packaging
        return AlertDialog(
          title: Text('Delete Talk'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this talk?'),
                SizedBox(height: 8),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.red[300],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                // delete the event
                _firebaseService.deleteTalk(talk['id']).then((_) {
                  // first the app closes the dialog
                  Navigator.of(dialogContext).pop(); 
                  
                  // then the app navigates back to previous screen
                  Navigator.of(context).pop(true);  // The app passes true to show the delete feature worked
                  
                  // shows the confirmation to the user
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Talk deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }).catchError((error) {
                  // close dialogContext on error too
                  Navigator.of(dialogContext).pop();
                  
                  // Show error (if there is an error)
                  CommonWidgets.showNotificationBanner(
                    context,
                    message: 'Error deleting talk: $error',
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
    // convert color code text & banner to color (Used AI for help coding this)
    Color talkColor = talk.containsKey('colorCode')
        ? Color(int.parse(talk['colorCode'].substring(1, 7), radix: 16) + 0xFF000000)
        : AppTheme.primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Talk' : 'Talk Details'),
        backgroundColor: talkColor,
        actions: [
          // New feature: Favorite button
          if (!isEditing)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : null,
              ),
              onPressed: _toggleFavorite,
              tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            ),
            
          // New feature: Export button
          if (!isEditing)
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: _exportTalkDetails,
              tooltip: 'Export to calendar',
            ),
            
          if (widget.isAdmin) ...[
            IconButton(
              icon: Icon(isEditing ? Icons.save : Icons.edit),
              onPressed: _toggleEdit,
            ),
            // add the delete button
            if (!isEditing)
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: _showDeleteConfirmation,
              ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // New feature: Countdown widget if the talk is in the future
            _buildCountdownWidget(),
            
            // Admin warnings
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
                            Text(
                              'Admin Alert',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            if (talk['hasMissingRegistration'] ?? false)
                              Text(
                                'Registration data missing',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            if (talk['hasMissingCopyright'] ?? false)
                              Text(
                                'Copyright notice missing',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Title
            _buildField(
              label: 'Title',
              value: talk['title'] ?? 'Untitled Talk',
              controller: titleController,
              isEditing: isEditing,
            ),
            
            const SizedBox(height: 16),
            
            // Speaker info
            _buildField(
              label: 'Speaker',
              value: talk['speaker'] ?? 'Unknown Speaker',
              controller: speakerController,
              isEditing: isEditing,
              icon: Icons.person,
            ),
            
            const SizedBox(height: 16),

            // Attendees - New field
            _buildField(
              label: 'Attendees',
              value: talk['attendees'] ?? 'No attendees listed',
              controller: attendeesController,
              isEditing: isEditing,
              icon: Icons.people,
            ),
            
            const SizedBox(height: 16),
            
            // Schedule info row
            Row(
              children: [
                // Day
                Expanded(
                  child: _buildField(
                    label: 'Day',
                    value: talk['day'] ?? 'TBD',
                    controller: dayController,
                    isEditing: isEditing,
                    icon: Icons.calendar_today,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Time
                Expanded(
                  child: _buildField(
                    label: 'Time',
                    value: talk['time'] ?? 'TBD',
                    controller: timeController,
                    isEditing: isEditing,
                    icon: Icons.access_time,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Location and track row
            Row(
              children: [
                // Location
                Expanded(
                  child: _buildField(
                    label: 'Location',
                    value: talk['location'] ?? 'TBD',
                    controller: locationController,
                    isEditing: isEditing,
                    icon: Icons.location_on,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Duration
                Expanded(
                  child: _buildField(
                    label: 'Duration',
                    value: talk['duration'] ?? 'TBD',
                    controller: durationController,
                    isEditing: isEditing,
                    icon: Icons.timer,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Track
            _buildField(
              label: 'Track',
              value: talk['track'] ?? 'General',
              controller: trackController,
              isEditing: isEditing,
              icon: Icons.category,
            ),
            
            const SizedBox(height: 24),
            
            // info / description
            _buildField(
              label: 'Description',
              value: talk['description'] ?? 'No description available',
              controller: descriptionController,
              isEditing: isEditing,
              isMultiline: true,
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons for editing - removed Add to Schedule and Share
            if (isEditing) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: CommonWidgets.appButton(
                      text: 'Cancel',
                      onPressed: () {
                        setState(() {
                          // Reset controllers to original values
                          titleController.text = widget.talk['title'] ?? '';
                          speakerController.text = widget.talk['speaker'] ?? '';
                          descriptionController.text = widget.talk['description'] ?? '';
                          timeController.text = widget.talk['time'] ?? '';
                          locationController.text = widget.talk['location'] ?? '';
                          trackController.text = widget.talk['track'] ?? '';
                          dayController.text = widget.talk['day'] ?? '';
                          durationController.text = widget.talk['duration'] ?? '';
                          attendeesController.text = widget.talk['attendees'] ?? ''; // Reset attendees
                          
                          // Exit edit mode
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
              ),
            ],
            
            // New feature: QR code for talk (placeholder)
            if (!isEditing) ...[
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(
                        Icons.qr_code_2,
                        size: 100,
                        color: talkColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Talk ID: ${talk['id']?.substring(0, 8) ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // New feature: Countdown widget
  Widget _buildCountdownWidget() {
    // Only show countdown if we have date and time information
    if ((talk['day'] ?? '').isEmpty || (talk['time'] ?? '').isEmpty) {
      return const SizedBox.shrink();
    }
    
    // This is placeholder code - in a real app, you would parse the date and time properly
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.timelapse, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coming up on ${talk['day']} at ${talk['time']}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Don\'t miss this event!',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
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
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  value,
                  style: isMultiline
                      ? Theme.of(context).textTheme.bodyMedium
                      : Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
      ],
    );
  }
}