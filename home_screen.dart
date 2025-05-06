import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:conference_app/app_theme.dart';
import 'package:conference_app/widgets/common_widgets.dart';
import 'package:conference_app/router.dart';
import 'package:conference_app/services/firebase_service.dart';
import 'package:conference_app/main.dart' as main;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final FirebaseService _firebaseService = FirebaseService();
  bool isAdmin = false;
  bool isLoading = true;
  int upcomingTalksCount = 0;
  Map<String, dynamic>? nextTalk;

  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAdminStatus();
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAdminStatus();
      _loadData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAdminStatus();
    _loadData();
  }

  void _checkAdminStatus() {
    setState(() {
      isAdmin = main.isAdminGlobal;
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final talks = await _firebaseService.getUpcomingTalks();
      if (!mounted) return;
      setState(() {
        upcomingTalksCount = talks.length;
        nextTalk = talks.isNotEmpty ? talks[0] : null;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      CommonWidgets.showNotificationBanner(
        context,
        message: 'Error loading data: $e',
        isError: true,
      );
    }
  }

  Future<void> _showLoginDialog() async {
    if (isAdmin) {
      // log out via helper
      main.logoutAdmin();
      setState(() => isAdmin = false);
      CommonWidgets.showNotificationBanner(
        context,
        message: 'Logged out of admin mode',
      );
      return;
    }

    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Admin Login'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Please enter admin credentials'),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Login'),
              onPressed: () async {
                final success = await main.loginAdmin(
                  usernameController.text.trim(),
                  passwordController.text,
                );
                Navigator.of(dialogContext).pop();
                if (success) {
                  setState(() => isAdmin = true);
                  CommonWidgets.showNotificationBanner(
                    context,
                    message: 'Admin mode activated',
                  );
                } else {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4C7F91), // Soft blue color for AppBar
        title: const Text(
          'Conference App',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: Colors.white),
            onPressed: _showLoginDialog,
          ),
        ],
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
          isLoading
              ? CommonWidgets.loadingIndicator()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isAdmin)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primaryColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.admin_panel_settings,
                                    color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Admin Mode',
                                  style: AppTheme.bodyTextStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome to the Conference!',
                                  style: AppTheme.headingStyle.copyWith(
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Check out all current talks/events, create your schedule, and connect with other speakers in CSIT 425!',
                                  style: AppTheme.bodyTextStyle.copyWith(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),
                        Text(
                          'Upcoming Talks',
                          style: AppTheme.subheadingStyle.copyWith(
                            fontSize: 15,  // Reduced font size
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (nextTalk != null)
                          _buildNextTalkCard(nextTalk!)
                        else
                          CommonWidgets.emptyState(
                            message: 'No upcoming talks scheduled',
                            icon: Icons.event_busy,
                          ),

                        const SizedBox(height: 16), // Adjusted space after the upcoming talks section

                        Text(
                          'Quick Actions',
                          style: AppTheme.subheadingStyle.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: Icons.event,
                              label: 'Schedule',
                              onTap: () {
                                Navigator.pushNamed(
                                    context, AppRouter.schedule);
                              },
                            ),
                            if (isAdmin)
                              _buildActionButton(
                                icon: Icons.add_circle,
                                label: 'Add Talk',
                                onTap: () {
                                  AppRouter.navigateToTalkForm(
                                    context,
                                    onSave: (newTalk) {
                                      _firebaseService
                                          .addTalk(newTalk)
                                          .then((_) {
                                        CommonWidgets.showNotificationBanner(
                                          context,
                                          message: 'New talk added',
                                        );
                                        _loadData();
                                      }).catchError((error) {
                                        CommonWidgets.showNotificationBanner(
                                          context,
                                          message:
                                              'Error adding talk: $error',
                                          isError: true,
                                        );
                                      });
                                    },
                                  );
                                },
                              ),
                            _buildActionButton(
                              icon: Icons.refresh,
                              label: 'Refresh',
                              onTap: _loadData,
                            ),
                          ],
                        ),

                        // Add Manage Users button at bottom if admin
                        if (isAdmin) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.supervised_user_circle),
                              label: const Text('Manage Users'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                textStyle: AppTheme.bodyTextStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed: () {
                                AppRouter.navigateToUserManagement(context);
                              },
                            ),
                          ),
                        ],

                        // Add calendar box with custom size
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),  // Adjusted margin for calendar container
                          padding: const EdgeInsets.all(5),
                          height: 275,  // Reduced height for calendar box
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Transform.translate(
                            offset: Offset(0,-25),
                            child: Transform.scale(
                              scale: 0.75,
                              child: TableCalendar(
                                firstDay: DateTime.utc(2020, 1, 1),
                                lastDay: DateTime.utc(2030, 12, 31),
                                focusedDay: _focusedDay,
                                selectedDayPredicate: (day) {
                                  return isSameDay(_selectedDay, day);
                              },
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                              },
                              onPageChanged: (focusedDay) {},
                              calendarFormat: _calendarFormat,
                              availableGestures: AvailableGestures.all,
                            ),
                          ),
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

  Widget _buildNextTalkCard(Map<String, dynamic> talk) {
    final talkColor = talk.containsKey('colorCode')
        ? Color(
            int.parse(talk['colorCode'].substring(1), radix: 16) |
                0xFF000000)
        : AppTheme.primaryColor;

    Widget attendeeBadge = const SizedBox.shrink();
    if (talk.containsKey('attendees') &&
        (talk['attendees'] as String).isNotEmpty) {
      final count = (talk['attendees'] as String)
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .length;
      attendeeBadge = Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 18),
            const SizedBox(width: 4),
            Text('$count attendees'),
          ],
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next Talk: ${talk['title'] ?? 'No Title'}',
              style: AppTheme.headingStyle,
            ),
            const SizedBox(height: 8),
            Text(
              talk['description'] ?? 'No Description Available',
              style: AppTheme.bodyTextStyle,
            ),
            const SizedBox(height: 8),
            attendeeBadge,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
