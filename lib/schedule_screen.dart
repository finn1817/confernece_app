import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets/common_widgets.dart';
import 'router.dart';
import 'services/firebase_service.dart';
import 'package:conference_app/app_theme.dart';
import 'main.dart' as main;

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool isLoading = true;
  List<Map<String, dynamic>> allTalks = [];
  List<Map<String, dynamic>> filteredTalks = [];
  
  // Filtering options
  String _selectedDay = 'All Days';
  String _selectedTrack = 'All Tracks';
  String _selectedAttendee = 'All Attendees'; // New filter for attendees
  String _searchQuery = '';
  
  List<String> availableDays = ['All Days'];
  List<String> availableTracks = ['All Tracks'];
  List<String> availableAttendees = ['All Attendees']; // New list for attendees
  
  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadTalks();
  }
  
  // Admin status
  bool isAdmin = false;
  
  void _checkAdminStatus() {
    setState(() {
      isAdmin = main.isAdminGlobal;
    });
  }

  void _loadTalks() {
    _firebaseService.getTalks().listen((talksList) {
      setState(() {
        allTalks = talksList;
        
        // Extract available days, tracks, and attendees for filtering
        Set<String> daysSet = {'All Days'};
        Set<String> tracksSet = {'All Tracks'};
        Set<String> attendeesSet = {'All Attendees'};
        
        for (var talk in talksList) {
          if (talk.containsKey('day') && talk['day'] != null) {
            daysSet.add(talk['day']);
          }
          if (talk.containsKey('track') && talk['track'] != null) {
            tracksSet.add(talk['track']);
          }
          
          // Extract attendees from comma-separated list
          if (talk.containsKey('attendees') && talk['attendees'] != null) {
            String attendeesStr = talk['attendees'] as String;
            if (attendeesStr.isNotEmpty) {
              List<String> talkAttendees = attendeesStr.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
              attendeesSet.addAll(talkAttendees);
            }
          }
        }
        
        availableDays = daysSet.toList()..sort();
        availableTracks = tracksSet.toList()..sort();
        availableAttendees = attendeesSet.toList()..sort();
        
        _applyFilters();
        isLoading = false;
      });
    }, onError: (error) {
      print('Error loading talks: $error');
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        CommonWidgets.showNotificationBanner(
          context,
          message: 'Error loading talks: $error',
          isError: true,
        );
      }
    });
  }
  
  void _applyFilters() {
    setState(() {
      filteredTalks = allTalks.where((talk) {
        // Apply day filter
        bool matchesDay = _selectedDay == 'All Days' || 
                         talk['day'] == _selectedDay;
        
        // Apply track filter
        bool matchesTrack = _selectedTrack == 'All Tracks' || 
                           talk['track'] == _selectedTrack;
        
        // Apply attendee filter
        bool matchesAttendee = _selectedAttendee == 'All Attendees';
        if (!matchesAttendee && talk.containsKey('attendees') && talk['attendees'] != null) {
          String attendeesStr = talk['attendees'] as String;
          List<String> talkAttendees = attendeesStr.split(',').map((a) => a.trim()).toList();
          matchesAttendee = talkAttendees.contains(_selectedAttendee);
        }
        
        // Apply search filter
        bool matchesSearch = _searchQuery.isEmpty || 
                           (talk['title']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                           (talk['speaker']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                           (talk['description']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                           (talk['attendees']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        
        return matchesDay && matchesTrack && matchesAttendee && matchesSearch;
      }).toList();
      
      // Sort by time
      filteredTalks.sort((a, b) {
        if (a['day'] != b['day'] && a['day'] != null && b['day'] != null) {
          return a['day'].compareTo(b['day']);
        }
        if (a['time'] != null && b['time'] != null) {
          return a['time'].compareTo(b['time']);
        }
        return 0;
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
      appBar: CommonWidgets.standardAppBar(
        title: 'Conference Schedule',
        actions: [
          IconButton(
            icon: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person),
            onPressed: () {
              _showLoginDialog();
            },
          ),
        ],
      ),
      body: isLoading
          ? CommonWidgets.loadingIndicator()
          : Column(
              children: [
                // Search and filter bar
                _buildFilterBar(),
                
                // Schedule list
                Expanded(
                  child: filteredTalks.isEmpty
                      ? CommonWidgets.emptyState(
                          message: 'No talks match your filters',
                          icon: Icons.event_busy,
                          onAction: () {
                            setState(() {
                              _selectedDay = 'All Days';
                              _selectedTrack = 'All Tracks';
                              _selectedAttendee = 'All Attendees';
                              _searchQuery = '';
                            });
                            _applyFilters();
                          },
                          actionLabel: 'Clear Filters',
                        )
                      : ListView.builder(
                          itemCount: filteredTalks.length,
                          itemBuilder: (context, index) {
                            final talk = filteredTalks[index];
                            final String prevDay = index > 0 ? filteredTalks[index - 1]['day'] ?? '' : '';
                            final String currentDay = talk['day'] ?? '';
                            
                            // Show day header if this is a new day
                            final bool showDayHeader = index == 0 || prevDay != currentDay;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showDayHeader && currentDay.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                    child: Text(
                                      currentDay,
                                      style: AppTheme.subheadingStyle.copyWith(
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  
                                _buildTalkCard(talk),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          AppRouter.navigateToTalkForm(
            context,
            onSave: (newTalk) {
              _firebaseService.addTalk(newTalk).then((_) {
                CommonWidgets.showNotificationBanner(
                  context,
                  message: 'New talk added',
                );
              }).catchError((error) {
                CommonWidgets.showNotificationBanner(
                  context,
                  message: 'Error adding talk: $error',
                  isError: true,
                );
              });
            },
          );
        },
      ) : null, // Only show the button for admin users
    );
  }
  
  // Show login dialog for admin access
  Future<void> _showLoginDialog() async {
    if (isAdmin) {
      // If already admin, log out
      main.isAdminGlobal = false;
      setState(() {
        isAdmin = false;
      });
      CommonWidgets.showNotificationBanner(
        context,
        message: 'Logged out of admin mode',
      );
      return;
    }
    
    // Show login dialog
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Admin Login'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Please enter admin credentials'),
                SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
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
              child: Text('Login'),
              onPressed: () {
                // Check credentials (hardcoded for now)
                if (usernameController.text == 'Admin' && 
                    passwordController.text == 'CSIT425') {
                  main.isAdminGlobal = true;
                  setState(() {
                    isAdmin = true;
                  });
                  Navigator.of(dialogContext).pop();
                  CommonWidgets.showNotificationBanner(
                    context,
                    message: 'Admin mode activated',
                  );
                } else {
                  Navigator.of(dialogContext).pop();
                  CommonWidgets.showNotificationBanner(
                    context,
                    message: 'Invalid credentials',
                    isError: true,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Column(
        children: [
          // Search field
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search talks or speakers...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
          ),
          
          const SizedBox(height: 8),
          
          // Filter dropdowns - first row
          Row(
            children: [
              // Day filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  value: _selectedDay,
                  items: availableDays.map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text(day, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDay = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Track filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Track',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  value: _selectedTrack,
                  items: availableTracks.map((track) {
                    return DropdownMenuItem(
                      value: track,
                      child: Text(track, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTrack = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Attendee filter - second row
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Attendee',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            value: _selectedAttendee,
            items: availableAttendees.map((attendee) {
              return DropdownMenuItem(
                value: attendee,
                child: Text(attendee, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedAttendee = value!;
              });
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildTalkCard(Map<String, dynamic> talk) {
    // Convert color code string to Color if it exists
    Color talkColor = talk.containsKey('colorCode')
        ? Color(int.parse(talk['colorCode'].substring(1, 7), radix: 16) + 0xFF000000)
        : AppTheme.primaryColor;
    
    // Track tag
    Widget trackTag = talk.containsKey('track') && talk['track'] != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: talkColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              talk['track'],
              style: TextStyle(
                color: talkColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : const SizedBox.shrink();
    
    // Attendee count badge
    Widget attendeeBadge = Container();
    if (talk.containsKey('attendees') && talk['attendees'] != null && talk['attendees'].toString().isNotEmpty) {
      int count = talk['attendees'].toString().split(',').where((s) => s.trim().isNotEmpty).length;
      if (count > 0) {
        attendeeBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people, size: 12, color: AppTheme.textSecondaryColor),
              SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        );
      }
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: talkColor, width: 2),
      ),
      child: InkWell(
        onTap: () {
          AppRouter.navigateToTalkDetail(
            context,
            talk: talk,
            isAdmin: isAdmin,
            onUpdate: updateTalk,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time column
                  Container(
                    width: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          talk['time'] ?? 'TBD',
                          style: AppTheme.bodyTextStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (talk.containsKey('duration') && talk['duration'] != null)
                          Text(
                            talk['duration'],
                            style: AppTheme.smallTextStyle,
                          ),
                      ],
                    ),
                  ),
                  
                  // Content column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                talk['title'] ?? 'Untitled Talk',
                                style: AppTheme.subheadingStyle,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            if (isAdmin && (talk['hasMissingRegistration'] ?? false || talk['hasMissingCopyright'] ?? false))
                              const Icon(Icons.warning, color: AppTheme.warningColor),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          talk['speaker'] ?? 'Unknown Speaker',
                          style: AppTheme.bodyTextStyle,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondaryColor),
                            const SizedBox(width: 4),
                            Text(
                              talk['location'] ?? 'TBD',
                              style: AppTheme.smallTextStyle,
                            ),
                            const SizedBox(width: 8),
                            trackTag,
                            if (talk.containsKey('attendees') && talk['attendees'] != null && talk['attendees'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: attendeeBadge,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}