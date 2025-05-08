// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:conference_app/app_theme.dart';
import 'package:conference_app/widgets/common_widgets.dart';
import 'package:conference_app/router.dart';
import 'package:conference_app/services/firebase_service.dart';
import 'package:conference_app/main.dart' as main;
import 'package:url_launcher/url_launcher.dart'; // Add this import for URL launching

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const HomeScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final FirebaseService _firebaseService = FirebaseService();
  bool isAdmin = false;
  bool isLoading = true;
  int upcomingTalksCount = 0;
  // store all fetched talks
  List<Map<String, dynamic>> talks = [];
  // store favorite talks
  List<Map<String, dynamic>> favoriteTalks = [];

  // GitHub repository URL
  final String githubUrl = "https://github.com/finn1817/confernece_app";

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

  // Function to launch URL
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        CommonWidgets.showNotificationBanner(
          context,
          message: 'Could not launch $url',
          isError: true,
        );
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final talks = await _firebaseService.getUpcomingTalks();
      if (!mounted) return;
      
      // Filter favorite talks
      final favorites = talks.where((talk) => talk['isFavorite'] == true).toList();
      
      setState(() {
        upcomingTalksCount = talks.length;
        this.talks = talks; // store the entire list
        this.favoriteTalks = favorites; // store favorites
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
        title: 'Conference App',
        actions: [
          // Theme toggle button
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          // Logout/Admin button
          IconButton(
            icon: Icon(isAdmin 
                ? Icons.logout
                : Icons.login),
            onPressed: isAdmin 
                ? _showLogoutConfirmation 
                : () => Navigator.of(context).pushReplacementNamed(AppRouter.login),
            tooltip: isAdmin ? 'Logout' : 'Login',
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
                    if (isAdmin)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.primary),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Admin Mode',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(
                      width: double.infinity, // ensures full width
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome to the our Android Conference App!',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This was made as our CSIT 425 Final Project.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ),

                    // Favorites Section - New!
                    if (favoriteTalks.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.star, 
                            size: 20, 
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Text('Favorite Events', 
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: favoriteTalks.length > 1 ? 280 : 140, // Adjust height based on number of favorites
                        child: ListView.builder(
                          itemCount: favoriteTalks.length > 2 ? 2 : favoriteTalks.length, // Show max 2 favorites
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) => _buildNextTalkCard(favoriteTalks[index]),
                        ),
                      ),
                      if (favoriteTalks.length > 2)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: const Text('See all favorites'),
                            onPressed: () {
                              // Navigate to favorites screen instead of schedule
                              Navigator.pushNamed(context, AppRouter.favorites);
                            },
                          ),
                        ),
                    ],

                    const SizedBox(height: 12),
                    Text('Upcoming Talks', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),

                    if (upcomingTalksCount > 0)
                      SizedBox(
                        height: 400, // fits about 3 cards cleanly
                        child: ListView.builder(
                          itemCount: talks.length >= 3 ? 3 : talks.length,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) => _buildNextTalkCard(talks[index]),
                        ),
                      )
                    else
                      CommonWidgets.emptyState(
                        message: 'No upcoming talks scheduled',
                        icon: Icons.event_busy,
                      ),

                    const SizedBox(height: 12),
                    Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 5),

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
                        _buildActionButton(
                          icon: Icons.star,
                          label: 'Favorites',
                          onTap: () {
                            // Updated to use the Favorites screen
                            if (favoriteTalks.isEmpty) {
                              CommonWidgets.showNotificationBanner(
                                context,
                                message: 'Star talks in their detail view to add favorites',
                              );
                            } else {
                              // Use the router's navigation method
                              AppRouter.navigateToFavorites(context);
                            }
                          },
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
                            textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          onPressed: () {
                            AppRouter.navigateToUserManagement(context);
                          },
                        ),
                      ),
                    ],

                    // Footer with GitHub link
                    const SizedBox(height: 32),
                    InkWell(
                      onTap: () => _launchUrl(githubUrl),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.code, 
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Open Source Project',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'View project on GitHub',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'MIT License © 2025',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Credits section
                    Center(
                      child: Text(
                        'Created by: Dan, Greg, Aurora, and Jiwon',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNextTalkCard(Map<String, dynamic> talk) {
    final talkColor = talk.containsKey('colorCode')
        ? Color(
            int.parse(talk['colorCode'].substring(1), radix: 16) |
                0xFF000000)
        : Theme.of(context).colorScheme.primary;

    final bool isFavorite = talk['isFavorite'] == true;

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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people,
                size: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(width: 4),
            Text(
              '$count attendees',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
            )
          ],
        ),
      );
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4), // smaller vertical margin
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
              _firebaseService
                  .updateTalk(updatedTalk['id'], updatedTalk);
              _loadData();
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10), // smaller inner padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      talk['title'] ?? 'Untitled Talk',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  Row(
                    children: [
                      if (isFavorite)
                        Icon(Icons.star, color: Colors.amber, size: 20),
                      if (isAdmin &&
                          ((talk['hasMissingRegistration'] ??
                                  false) ||
                              (talk['hasMissingCopyright'] ??
                                  false)))
                        const SizedBox(width: 4),
                      if (isAdmin &&
                          ((talk['hasMissingRegistration'] ??
                                  false) ||
                              (talk['hasMissingCopyright'] ??
                                  false)))
                        const Icon(Icons.warning,
                            color: AppTheme.warningColor),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6), // reduced spacing
              Row(
                children: [
                  const Icon(Icons.person,
                      size: 16,
                      color:
                          AppTheme.textSecondaryColor),
                  const SizedBox(width: 4),
                  Text(talk['speaker'] ?? 'Unknown Speaker',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (attendeeBadge is! SizedBox)
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 8),
                      child: attendeeBadge,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 4),
                        Text(talk['time'] ?? 'TBD', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            talk['location'] ?? 'TBD',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  CommonWidgets.appButton(
                    text: 'View Details',
                    onPressed: () {
                      AppRouter.navigateToTalkDetail(
                        context,
                        talk: talk,
                        isAdmin: isAdmin,
                        onUpdate: (updatedTalk) {
                          _firebaseService.updateTalk(updatedTalk['id'], updatedTalk);
                          _loadData();
                        },
                      );
                    },
                    isOutlined: true,
                  ),
                ],
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
    return KeyedSubtree(
      key: UniqueKey(), // prevents GlobalKey duplication issues
      child: InkWell(
        onTap: onTap,
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}