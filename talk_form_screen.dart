import 'package:flutter/material.dart';

class TalkFormScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? talk;

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
  late TextEditingController _attendeesController;
  late String _selectedColor;

  final List<Map<String, dynamic>> colorOptions = [
    {'name': 'Red - Issues', 'code': '#FF5733'},
    {'name': 'Green - Meetings', 'code': '#33FF57'},
    {'name': 'Blue - Projects', 'code': '#3357FF'},
    {'name': 'Purple - Activities', 'code': '#8333FF'},
    {'name': 'Orange - Other Events', 'code': '#FF8C33'},
  ];

  @override
  void initState() {
    super.initState();
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

  String? _validateDateFormat(String? value) {
    if (value == null || value.isEmpty) return null;
    final RegExp dateRegex = RegExp(r'^\d{2}/\d{2}/\d{2}\$');
    if (!dateRegex.hasMatch(value)) return 'Please use format: 00/00/00';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.talk == null ? 'Add New Talk' : 'Edit Talk'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/im2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
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
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _speakerController,
                          decoration: const InputDecoration(
                            labelText: 'Host',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the host\'s name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _attendeesController,
                          decoration: const InputDecoration(
                            labelText: 'Users Included',
                            border: OutlineInputBorder(),
                            hintText: 'ex) John Doe, Jane Smith',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dayController,
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            hintText: '01/01/25',
                          ),
                          validator: _validateDateFormat,
                          keyboardType: TextInputType.datetime,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _timeController,
                          decoration: const InputDecoration(
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _durationController,
                          decoration: const InputDecoration(
                            labelText: 'Duration',
                            border: OutlineInputBorder(),
                            hintText: 'e.g. 1 Hour',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _trackController,
                          decoration: const InputDecoration(
                            labelText: 'Event Subject (Track)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Color Category',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedColor,
                          items: colorOptions.map((color) {
                            return DropdownMenuItem<String>(
                              value: color['code'],
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Color(
                                        int.parse(color['code'].substring(1, 7), radix: 16) + 0xFF000000,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 5,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final updatedTalk = {
                                ...?widget.talk,
                                'id': widget.talk?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                'title': _titleController.text,
                                'speaker': _speakerController.text,
                                'time': _timeController.text,
                                'location': _locationController.text,
                                'day': _dayController.text,
                                'duration': _durationController.text,
                                'track': _trackController.text,
                                'description': _descriptionController.text,
                                'attendees': _attendeesController.text.trim(),
                                'colorCode': _selectedColor,
                                'hasMissingRegistration': widget.talk?['hasMissingRegistration'] ?? false,
                                'hasMissingCopyright': widget.talk?['hasMissingCopyright'] ?? false,
                              };
                              widget.onSave(updatedTalk);
                              Navigator.pop(context);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(widget.talk == null ? 'Save Talk' : 'Update Talk'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    _attendeesController.dispose();
    super.dispose();
  }
}
