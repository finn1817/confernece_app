import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets/common_widgets.dart';
import 'services/firebase_service.dart';

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
  
  // Controllers for editable fields
  late TextEditingController titleController;
  late TextEditingController speakerController;
  late TextEditingController descriptionController;
  late TextEditingController timeController;
  late TextEditingController locationController;
  late TextEditingController trackController;
  late TextEditingController dayController;
  late TextEditingController durationController;
  
  @override
  void initState() {
    super.initState();
    talk = Map<String, dynamic>.from(widget.talk);
    
    // Initialize controllers with existing values
    titleController = TextEditingController(text: talk['title'] ?? '');
    speakerController = TextEditingController(text: talk['speaker'] ?? '');
    descriptionController = TextEditingController(text: talk['description'] ?? '');
    timeController = TextEditingController(text: talk['time'] ?? '');
    locationController = TextEditingController(text: talk['location'] ?? '');
    trackController = TextEditingController(text: talk['track'] ?? '');
    dayController = TextEditingController(text: talk['day'] ?? '');
    durationController = TextEditingController(text: talk['duration'] ?? '');
  }

  @override
  void dispose() {
    // Dispose controllers
    titleController.dispose();
    speakerController.dispose();
    descriptionController.dispose();
    timeController.dispose();
    locationController.dispose();
    trackController.dispose();
    dayController.dispose();
    durationController.dispose();
    super.dispose();
  }
  
  void _toggleEdit() {
    setState(() {
      if (isEditing) {
        // Save changes before exiting edit mode
        talk['title'] = titleController.text;
        talk['speaker'] = speakerController.text;
        talk['description'] = descriptionController.text;
        talk['time'] = timeController.text;
        talk['location'] = locationController.text;
        talk['track'] = trackController.text;
        talk['day'] = dayController.text;
        talk['duration'] = durationController.text;
        
        // Update via callback
        widget.onUpdate(talk);
        
        CommonWidgets.showNotificationBanner(
          context,
          message: 'Talk updated successfully',
        );
      }
      
      isEditing = !isEditing;
    });
  }
  
  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) { // Use dialogContext instead of context
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
                Navigator.of(dialogContext).pop(); // Use dialogContext
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                // Delete the talk
                _firebaseService.deleteTalk(talk['id']).then((_) {
                  // First close the dialog
                  Navigator.of(dialogContext).pop(); 
                  
                  // Then go back to previous screen
                  Navigator.of(context).pop(true);  // Pass true to indicate deletion
                  
                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Talk deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }).catchError((error) {
                  // Close dialog on error too
                  Navigator.of(dialogContext).pop();
                  
                  // Show error
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
    // Convert color code string to Color if it exists
    Color talkColor = talk.containsKey('colorCode')
        ? Color(int.parse(talk['colorCode'].substring(1, 7), radix: 16) + 0xFF000000)
        : AppTheme.primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Talk' : 'Talk Details'),
        actions: [
          if (widget.isAdmin) ...[
            IconButton(
              icon: Icon(isEditing ? Icons.save : Icons.edit),
              onPressed: _toggleEdit,
            ),
            // Add delete button
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
                              style: AppTheme.bodyTextStyle.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            if (talk['hasMissingRegistration'] ?? false)
                              Text(
                                'Registration data missing',
                                style: AppTheme.smallTextStyle,
                              ),
                            if (talk['hasMissingCopyright'] ?? false)
                              Text(
                                'Copyright notice missing',
                                style: AppTheme.smallTextStyle,
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
            
            // Description
            _buildField(
              label: 'Description',
              value: talk['description'] ?? 'No description available',
              controller: descriptionController,
              isEditing: isEditing,
              isMultiline: true,
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!isEditing) ...[
                  Expanded(
                    child: CommonWidgets.appButton(
                      text: 'Add to My Schedule',
                      onPressed: () {
                        // Add to user's personal schedule
                        CommonWidgets.showNotificationBanner(
                          context,
                          message: 'Added to your schedule',
                        );
                      },
                      icon: Icons.bookmark_add,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CommonWidgets.appButton(
                      text: 'Share',
                      onPressed: () {
                        // Share talk info
                        CommonWidgets.showNotificationBanner(
                          context,
                          message: 'Sharing options',
                        );
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
                          // Reset controllers to original values
                          titleController.text = widget.talk['title'] ?? '';
                          speakerController.text = widget.talk['speaker'] ?? '';
                          descriptionController.text = widget.talk['description'] ?? '';
                          timeController.text = widget.talk['time'] ?? '';
                          locationController.text = widget.talk['location'] ?? '';
                          trackController.text = widget.talk['track'] ?? '';
                          dayController.text = widget.talk['day'] ?? '';
                          durationController.text = widget.talk['duration'] ?? '';
                          
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
              ],
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
          style: AppTheme.smallTextStyle.copyWith(
            color: AppTheme.textSecondaryColor,
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
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  value,
                  style: isMultiline
                      ? AppTheme.bodyTextStyle
                      : AppTheme.bodyTextStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
      ],
    );
  }
}