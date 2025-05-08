// lib/screens/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:conference_app/app_theme.dart';
import 'package:conference_app/widgets/common_widgets.dart';
import 'package:conference_app/router.dart';
import 'package:conference_app/services/firebase_service.dart';
import 'package:conference_app/main.dart' as main;

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool isLoading = true;
  bool isAdmin = false;
  List<Map<String, dynamic>> favoriteTalks = [];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadFavorites();
  }

  void _checkAdminStatus() {
    setState(() {
      isAdmin = main.isAdminGlobal;
    });
  }

  Future<void> _loadFavorites() async {
    setState(() => isLoading = true);

    try {
      // Get all talks
      final talks = await _firebaseService.getUpcomingTalks();
      
      // Filter to only favorites
      final favorites = talks.where((talk) => talk['isFavorite'] == true).toList();
      
      setState(() {
        favoriteTalks = favorites;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      CommonWidgets.showNotificationBanner(
        context,
        message: 'Error loading favorites: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavorites,
            tooltip: 'Refresh Favorites',
          ),
        ],
      ),
      body: isLoading
          ? CommonWidgets.loadingIndicator()
          : RefreshIndicator(
              onRefresh: _loadFavorites,
              child: favoriteTalks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_border,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No favorite talks yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Star talks in their detail view to add them here',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.event),
                            label: const Text('View All Talks'),
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, AppRouter.schedule);
                            },
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: favoriteTalks.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        return _buildTalkCard(favoriteTalks[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildTalkCard(Map<String, dynamic> talk) {
    final talkColor = talk.containsKey('colorCode')
        ? Color(
            int.parse(talk['colorCode'].substring(1), radix: 16) |
                0xFF000000)
        : Theme.of(context).colorScheme.primary;

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
      margin: const EdgeInsets.symmetric(vertical: 4), 
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
              _loadFavorites();
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                      Icon(Icons.star, color: Colors.amber),
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
              const SizedBox(height: 6),
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
                          _loadFavorites();
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
}