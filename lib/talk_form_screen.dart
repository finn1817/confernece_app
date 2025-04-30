import 'package:flutter/material.dart';

class TalkFormScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? talk; // optional talk for editing

  TalkFormScreen({required this.onSave, this.talk});

  @override
  _TalkFormScreenState createState() => _TalkFormScreenState();
}

class _TalkFormScreenState extends State<TalkFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _speakerController;
  late TextEditingController _timeController;
  late TextEditingController _locationController;
  late TextEditingController _dayController;
  late TextEditingController _trackController;
  late TextEditingController _durationController;
  late TextEditingController _descriptionController;
  late TextEditingController _attendeesController; // newest field we added for users (we call them meeting attendees
  late String _selectedColor;

  // color options
  final List<Map<String, dynamic>> colorOptions = [
    {'name': 'Red', 'code': '#FF5733'},
    {'name': 'Green', 'code': '#33FF57'},
    {'name': 'Blue', 'code': '#3357FF'},
    {'name': 'Purple', 'code': '#8333FF'},
    {'name': 'Orange', 'code': '#FF8C33'},
  ];

  @override
  void initState() {
    super.initState();
    // initialize controllers with existing values if editing
    _titleController = TextEditingController(text: widget.talk?['title'] ?? '');
    _speakerController = TextEditingController(text: widget.talk?['speaker'] ?? '');
    _timeController = TextEditingController(text: widget.talk?['time'] ?? '');
    _locationController = TextEditingController(text: widget.talk?['location'] ?? '');
    _dayController = TextEditingController(text: widget.talk?['day'] ?? '');
    _trackController = TextEditingController(text: widget.talk?['track'] ?? '');
    _durationController = TextEditingController(text: widget.talk?['duration'] ?? '');
    _descriptionController = TextEditingController(text: widget.talk?['description'] ?? '');
    _attendeesController = TextEditingController(text: widget.talk?['attendees'] ?? '');
    _selectedColor = widget.talk?['colorCode'] ?? '#FF5733';
  }

  // validate date format (00/00/00)
  String? _validateDateFormat(String? value) {
    if (value == null || value.isEmpty) {
      return null; // allow empty dates
    }
    
    // check if it matches the 00/00/00 format
    RegExp dateRegex = RegExp(r'^\d{2}/\d{2}/\d{2}$');
    if (!dateRegex.hasMatch(value)) {
      return 'Please use format: 00/00/00';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.talk == null ? 'Add New Talk' : 'Edit Talk'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title for the event';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _speakerController,
                decoration: InputDecoration(
                  labelText: 'Host',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the hosts name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // attendees field - newest
              TextFormField(
                controller: _attendeesController,
                decoration: InputDecoration(
                  labelText: 'Users Included',
                  border: OutlineInputBorder(),
                  hintText: 'ex) John Doe, Jane Smith (comma separated)',
                ),
              ),
              SizedBox(height: 16),

              // date field - with validation
              TextFormField(
                controller: _dayController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  hintText: 'ex) 01/01/25 Month/Date/Year',
                ),
                validator: _validateDateFormat,
                keyboardType: TextInputType.datetime,
              ),
              SizedBox(height: 16),

              // time
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Time',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 10:00 AM',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a time';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Duration field
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: 'Duration',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 1 Hour',
                ),
              ),
              SizedBox(height: 16),

              // event subject
              TextFormField(
                controller: _trackController,
                decoration: InputDecoration(
                  labelText: 'Event Subject (known as its Track)',
                  border: OutlineInputBorder(),
                  hintText: 'ex) School, Work, etc... (can be anything!)',
                ),
              ),
              SizedBox(height: 16),
              
              // Color dropdown - fixed to avoid duplicate values
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Color Category',
                  border: OutlineInputBorder(),
                ),
                value: colorOptions.any((color) => color['code'] == _selectedColor) 
                    ? _selectedColor 
                    : colorOptions[0]['code'],
                items: colorOptions.map((color) {
                  return DropdownMenuItem<String>(
                    value: color['code'],
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(int.parse(color['code'].substring(1, 7), radix: 16) + 0xFF000000),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(color['name']),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedColor = value;
                    });
                  }
                },
              ),
              SizedBox(height: 16),

              // description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Enter a description of your event here!',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(widget.talk == null ? 'Save Talk' : 'Update Talk'),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final updatedTalk = widget.talk == null 
                      ? {
                          'id': DateTime.now().millisecondsSinceEpoch.toString(), // Generate a unique ID for new talks
                          'title': _titleController.text,
                          'speaker': _speakerController.text,
                          'time': _timeController.text,
                          'location': _locationController.text,
                          'day': _dayController.text,
                          'duration': _durationController.text,
                          'track': _trackController.text,
                          'description': _descriptionController.text,
                          'attendees': _attendeesController.text.trim(), // Add attendees
                          'colorCode': _selectedColor,
                          'hasMissingRegistration': false,
                          'hasMissingCopyright': false,
                        }
                      : {
                          ...widget.talk!,
                          'title': _titleController.text,
                          'speaker': _speakerController.text,
                          'time': _timeController.text,
                          'location': _locationController.text,
                          'day': _dayController.text,
                          'duration': _durationController.text,
                          'track': _trackController.text,
                          'description': _descriptionController.text,
                          'attendees': _attendeesController.text.trim(), // Add attendees
                          'colorCode': _selectedColor,
                        };
                    
                    widget.onSave(updatedTalk);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _speakerController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _dayController.dispose();
    _trackController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _attendeesController.dispose(); // Dispose the new controller
    super.dispose();
  }
}