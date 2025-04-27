import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets/common_widgets.dart';
import 'router.dart';
import 'services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool isAdmin = false;
  bool isLoading = true;
  int upcomingTalksCount = 0;
  Map<String, dynamic>? nextTalk;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Get the upcoming talks count
      final talks = await _firebaseService.getUpcomingTalks();
      
      setState(() {
        upcomingTalksCount = talks.length;
        nextTalk = talks.isNotEmpty ? talks[0] : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        CommonWidgets.showNotificationBanner(
          context, 
          message: 'Error loading data: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonWidgets.standardAppBar(
        title: 'Conference App',
        actions: [
          IconButton(
            icon: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person),
            onPressed: () {
              setState(() {
                isAdmin = !isAdmin;
              });
              CommonWidgets.showNotificationBanner(
                context,
                message: isAdmin ? 'Admin mode activated' : 'User mode activated',
              );
            },
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
                    // Welcome card
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
                              'check out all curerent talks / events, create your schedule, and connect with other speakers in CSIT 425!',
                              style: AppTheme.bodyTextStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Upcoming talks section
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
                    
                    // Quick actions
                    Text('Quick Actions', style: AppTheme.subheadingStyle),
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.event,
                          label: 'Schedule',
                          onTap: () {
                            Navigator.pushNamed(context, AppRouter.schedule);
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
                                    _loadData(); // Refresh data
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
    // Convert color code string to Color if it exists
    Color talkColor = talk.containsKey('colorCode')
        ? Color(int.parse(talk['colorCode'].substring(1, 7), radix: 16) + 0xFF000000)
        : AppTheme.primaryColor;
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
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
            onUpdate: (updatedTalk) {
              _firebaseService.updateTalk(updatedTalk['id'], updatedTalk);
              _loadData(); // Refresh data after update
            },
          );
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
                      _loadData(); // Refresh data after update
                    },
                  );
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