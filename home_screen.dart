import 'package:flutter/material.dart';
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
  
  @override
  void initState() {
    super.initState();
    // register the observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    _checkAdminStatus();
    _loadData();
  }
  
  void _checkAdminStatus() {
    setState(() {
      isAdmin = main.isAdminGlobal;
    });
  }
  
  @override
  void dispose() {
    // remove the observer when the screen is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  // this method is called when the app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // refresh when the app comes back to the foreground
    if (state == AppLifecycleState.resumed) {
      _checkAdminStatus();
      _loadData();
    }
  }
  
  // this method is called when this route is pushed on top of another route
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAdminStatus();
    _loadData();
  }
  
  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      // get the upcoming talks count
      final talks = await _firebaseService.getUpcomingTalks();
      
      if (mounted) {
        setState(() {
          upcomingTalksCount = talks.length;
          nextTalk = talks.isNotEmpty ? talks[0] : null;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        CommonWidgets.showNotificationBanner(
          context, 
          message: 'Error loading data: $e',
          isError: true,
        );
      }
    }
  }

  // show login dialog for admin access
  Future<void> _showLoginDialog() async {
    if (isAdmin) {
      // if already admin, log out
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
    
    // show login dialog
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
                // Check credentials
                if (main.checkAdminCredentials(usernameController.text, passwordController.text)) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonWidgets.standardAppBar(
        title: 'Conference App',
        actions: [
          IconButton(
            icon: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person),
            onPressed: _showLoginDialog,
          ),
        ],
      ),
      body: isLoading
          ? CommonWidgets.loadingIndicator()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // admin badge if in admin mode
                    if (isAdmin)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor),
                            SizedBox(width: 8),
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
                    
                    // welcome card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to the Conference!',
                              style: AppTheme.headingStyle,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check out all current talks/events, create your schedule, and connect with other speakers in CSIT 425!',
                              style: AppTheme.bodyTextStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // upcoming (talks / events) section
                    Text('Upcoming Talks', style: AppTheme.subheadingStyle),
                    const SizedBox(height: 8),
                    
                    if (nextTalk != null)
                      _buildNextTalkCard(nextTalk!)
                    else
                      CommonWidgets.emptyState(
                        message: 'No upcoming talks scheduled',
                        icon: Icons.event_busy,
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // quick actions
                    Text('Quick Actions', style: AppTheme.subheadingStyle),
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.event,
                          label: 'Schedule',
                          onTap: () {
                            // go to schedule screen and load data when returning
                            Navigator.pushNamed(context, AppRouter.schedule);
                            // we'll rely on didChangeDependencies for refreshing
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
                                  _firebaseService.addTalk(newTalk).then((_) {
                                    CommonWidgets.showNotificationBanner(
                                      context,
                                      message: 'New talk added',
                                    );
                                    _loadData(); // refresh data
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
                          ),
                        _buildActionButton(
                          icon: Icons.refresh,
                          label: 'Refresh',
                          onTap: _loadData,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildNextTalkCard(Map<String, dynamic> talk) {
    // convert color code string to color if it exists (AI helped w this)
    Color talkColor = talk.containsKey('colorCode')
        ? Color(int.parse(talk['colorCode'].substring(1, 7), radix: 16) + 0xFF000000)
        : AppTheme.primaryColor;
    
    // attendee count badge
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
                '$count attendees',
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
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: talkColor, width: 2),
      ),
      child: InkWell(
        onTap: () {
          // navigate to talk detail
          AppRouter.navigateToTalkDetail(
            context,
            talk: talk,
            isAdmin: isAdmin,
            onUpdate: (updatedTalk) {
              _firebaseService.updateTalk(updatedTalk['id'], updatedTalk);
              _loadData(); // refresh data after update
            },
          );
          // didChangeDependencies will handle refresh when returning
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 4),
                  Text(talk['speaker'] ?? 'Unknown Speaker', style: AppTheme.smallTextStyle),
                  if (talk.containsKey('attendees') && talk['attendees'] != null && talk['attendees'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: attendeeBadge,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 4),
                  Text(talk['time'] ?? 'TBD', style: AppTheme.smallTextStyle),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 4),
                  Text(talk['location'] ?? 'TBD', style: AppTheme.smallTextStyle),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                talk['description'] ?? 'No description available',
                style: AppTheme.bodyTextStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              CommonWidgets.appButton(
                text: 'View Details',
                onPressed: () {
                  AppRouter.navigateToTalkDetail(
                    context,
                    talk: talk,
                    isAdmin: isAdmin,
                    onUpdate: (updatedTalk) {
                      _firebaseService.updateTalk(updatedTalk['id'], updatedTalk);
                      _loadData(); // refresh data after update
                    },
                  );
                  // didChangeDependencies will handle refresh when returning
                },
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 28, color: AppTheme.primaryColor),
              const SizedBox(height: 8),
              Text(label, style: AppTheme.smallTextStyle),
            ],
          ),
        ),
      ),
    );
  }
}