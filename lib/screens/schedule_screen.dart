import 'package:flutter/material.dart';
import 'package:conference_app/app_theme.dart';
import 'package:conference_app/widgets/common_widgets.dart';
import 'package:conference_app/router.dart';
import 'package:conference_app/services/firebase_service.dart';
import 'package:conference_app/main.dart' as main;

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool isLoading = true;

  // All talks from Firebase
  List<Map<String, dynamic>> allTalks = [];
  // Filtered subset
  List<Map<String, dynamic>> filteredTalks = [];

  // --- FILTER STATE ---
  String _selectedDay = 'All Dates';
  String _selectedTrack = 'All Tracks';
  String _selectedAttendee = 'All Attendees';
  String _searchQuery = '';

  // Dropdown options
  List<String> availableDays = ['All Dates'];
  List<String> availableTracks = ['All Tracks'];
  List<String> availableAttendees = ['All Attendees'];
  // Admin toggle
  bool isAdmin = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadTalks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkAdminStatus() {
    isAdmin = main.isAdminGlobal;
  }

  void _loadTalks() {
    _firebaseService.getUpcomingTalks().then(
      (talksList) {
        setState(() {
          allTalks = talksList;

          // Gather unique values (no 'All ...' in these sets)
          final Set<String> daysSet = <String>{};
          final Set<String> tracksSet = <String>{};
          final Set<String> attendeesSet = <String>{};

          for (var talk in talksList) {
            final day = talk['day']?.toString() ?? '';
            final track = talk['track']?.toString() ?? '';
            final attendeesStr = talk['attendees']?.toString() ?? '';

            if (day.isNotEmpty) daysSet.add(day);
            if (track.isNotEmpty) tracksSet.add(track);
            if (attendeesStr.isNotEmpty) {
              attendeesSet.addAll(
                attendeesStr
                    .split(',')
                    .map((a) => a.trim())
                    .where((a) => a.isNotEmpty),
              );
            }
          }

          // Prepend exactly one 'All ...' entry
          availableDays = ['All Dates']..addAll(daysSet.toList()..sort());
          availableTracks = ['All Tracks']..addAll(tracksSet.toList()..sort());
          availableAttendees = ['All Attendees']
            ..addAll(attendeesSet.toList()..sort());

          _applyFilters();
          isLoading = false;
        });
      },
      onError: (error) {
        print('Error loading talks: $error');
        setState(() => isLoading = false);
        if (mounted) {
          CommonWidgets.showNotificationBanner(
            context,
            message: 'Error loading talks: $error',
            isError: true,
          );
        }
      },
    );
  }

  void _applyFilters() {
    setState(() {
      filteredTalks =
          allTalks.where((talk) {
            final day = talk['day']?.toString() ?? '';
            final track = talk['track']?.toString() ?? '';
            final attendeesStr = talk['attendees']?.toString() ?? '';

            final matchesDay =
                _selectedDay == 'All Dates' || day == _selectedDay;
            final matchesTrack =
                _selectedTrack == 'All Tracks' || track == _selectedTrack;

            bool matchesAttendee = _selectedAttendee == 'All Attendees';
            if (!matchesAttendee && attendeesStr.isNotEmpty) {
              final list =
                  attendeesStr
                      .split(',')
                      .map((a) => a.trim())
                      .where((a) => a.isNotEmpty)
                      .toList();
              matchesAttendee = list.contains(_selectedAttendee);
            }

            final q = _searchQuery.toLowerCase();
            final matchesSearch =
                q.isEmpty ||
                (talk['title']?.toString().toLowerCase().contains(q) ??
                    false) ||
                (talk['speaker']?.toString().toLowerCase().contains(q) ??
                    false) ||
                (talk['description']?.toString().toLowerCase().contains(q) ??
                    false) ||
                attendeesStr.toLowerCase().contains(q);

            return matchesDay &&
                matchesTrack &&
                matchesAttendee &&
                matchesSearch;
          }).toList();

      // Sort first by day, then by time
      filteredTalks.sort((a, b) {
        final dayA = a['day']?.toString() ?? '';
        final dayB = b['day']?.toString() ?? '';
        if (dayA != dayB) return dayA.compareTo(dayB);
        final timeA = a['time']?.toString() ?? '';
        final timeB = b['time']?.toString() ?? '';
        return timeA.compareTo(timeB);
      });
    });
  }

  void updateTalk(Map<String, dynamic> updatedTalk) {
    _firebaseService.updateTalk(updatedTalk['id'], updatedTalk);
    // UI refreshes automatically via the stream listener
  }
  
  Future<void> _showLogoutConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // Perform logout
      main.logoutAdmin();
      
      // Reset admin status
      setState(() => isAdmin = false);
      
      // Show notification
      CommonWidgets.showNotificationBanner(
        context,
        message: 'Successfully logged out',
      );
      
      // Navigate to login screen
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonWidgets.standardAppBar(
        title: 'Conference Schedule',
        actions: [
          // Added proper logout button
          IconButton(
            icon: Icon(isAdmin ? Icons.logout : Icons.login),
            onPressed: isAdmin ? _showLogoutConfirmation : _showLoginDialog,
            tooltip: isAdmin ? 'Logout' : 'Login',
          ),
        ],
      ),
      body:
          isLoading
              ? CommonWidgets.loadingIndicator()
              : Column(
                children: [
                  _buildFilterBar(),
                  Expanded(child: _buildScheduleList()),
                ],
              ),
      floatingActionButton:
          isAdmin
              ? FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed:
                    () => AppRouter.navigateToTalkForm(
                      context,
                      onSave: (newTalk) {
                        _firebaseService
                            .addTalk(newTalk)
                            .then((_) {
                              CommonWidgets.showNotificationBanner(
                                context,
                                message: 'New talk added',
                              );
                            })
                            .catchError((e) {
                              CommonWidgets.showNotificationBanner(
                                context,
                                message: 'Error adding talk: $e',
                                isError: true,
                              );
                            });
                      },
                    ),
              )
              : null,
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search talks or speakers…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              setState(() {
                _searchQuery = v;
              });
              _applyFilters();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  value: _selectedDay,
                  items:
                      availableDays
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(d, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedDay = v!;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Track',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  value: _selectedTrack,
                  items:
                      availableTracks
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedTrack = v!;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Attendee',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            value: _selectedAttendee,
            items:
                availableAttendees
                    .map(
                      (a) => DropdownMenuItem(
                        value: a,
                        child: Text(a, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
            onChanged: (v) {
              setState(() {
                _selectedAttendee = v!;
              });
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    if (filteredTalks.isEmpty) {
      return CommonWidgets.emptyState(
        message: 'No talks match your filters',
        icon: Icons.event_busy,
        onAction: () {
          setState(() {
            _selectedDay = 'All Dates';
            _selectedTrack = 'All Tracks';
            _selectedAttendee = 'All Attendees';
            _searchQuery = '';
            _searchController.clear();
          });
          _applyFilters();
        },
        actionLabel: 'Clear Filters',
      );
    }
    return ListView.builder(
      itemCount: filteredTalks.length,
      itemBuilder: (context, index) {
        final talk = filteredTalks[index];
        final prevDay = index > 0 ? filteredTalks[index - 1]['day'] : '';
        final currDay = talk['day'] ?? '';
        final showHeader = index == 0 || prevDay != currDay;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader && currDay.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  currDay,
                  style: AppTheme.subheadingStyle.copyWith(color: AppTheme.primaryColor),
                ),
              ),
            _buildTalkCard(talk),
          ],
        );
      },
    );
  }

  Widget _buildTalkCard(Map<String, dynamic> talk) {
    final talkColor =
        talk.containsKey('colorCode')
            ? Color(
              int.parse(talk['colorCode'].substring(1), radix: 16) | 0xFF000000,
            )
            : AppTheme.primaryColor;

    final trackTag =
        talk['track'] != null
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

    Widget attendeeBadge = const SizedBox.shrink();
    final atts = talk['attendees']?.toString() ?? '';
    final count = atts.split(',').where((s) => s.trim().isNotEmpty).length;
    if (count > 0) {
      attendeeBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people,
              size: 12,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: talkColor, width: 2),
      ),
      child: InkWell(
        onTap:
            () => AppRouter.navigateToTalkDetail(
              context,
              talk: talk,
              isAdmin: isAdmin,
              onUpdate: updateTalk,
            ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(talk['time'] ?? 'TBD', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (talk['duration'] != null) Text(talk['duration'], style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            talk['title'] ?? 'Untitled Talk',
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        if (isAdmin &&
                            (talk['hasMissingRegistration'] == true ||
                                talk['hasMissingCopyright'] == true))
                          const Icon(
                            Icons.warning,
                            color: AppTheme.warningColor,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(talk['speaker'] ?? 'Unknown Speaker',
                    style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(talk['location'] ?? 'TBD', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 8),
                        trackTag,
                        if (count > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: attendeeBadge,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLoginDialog() async {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Admin Login'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please enter admin credentials'),
                const SizedBox(height: 16),
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              TextButton(
                child: const Text('Login'),
                onPressed: () {
                  if (userCtrl.text == 'Admin' && passCtrl.text == 'CSIT425') {
                    main.isAdminGlobal = true;
                    setState(() => isAdmin = true);
                    Navigator.of(ctx).pop();
                    CommonWidgets.showNotificationBanner(
                      context,
                      message: 'Admin mode activated',
                    );
                  } else {
                    Navigator.of(ctx).pop();
                    CommonWidgets.showNotificationBanner(
                      context,
                      message: 'Invalid credentials',
                      isError: true,
                    );
                  }
                },
              ),
            ],
          ),
    );
  }
}