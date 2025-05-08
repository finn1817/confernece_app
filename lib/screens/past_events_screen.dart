// lib/screens/past_events_screen.dart

import 'package:flutter/material.dart';
import 'package:conference_app/app_theme.dart';
import 'package:conference_app/widgets/common_widgets.dart';
import 'package:conference_app/router.dart';
import 'package:conference_app/services/firebase_service.dart';
import 'package:conference_app/utils/date_utils.dart';

class PastEventsScreen extends StatefulWidget {
  @override
  _PastEventsScreenState createState() => _PastEventsScreenState();
}

class _PastEventsScreenState extends State<PastEventsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool isLoading = true;
  List<Map<String, dynamic>> pastTalks = [];
  
  @override
  void initState() {
    super.initState();
    _loadPastEvents();
  }
  
  Future<void> _loadPastEvents() async {
    setState(() => isLoading = true);
    
    try {
      final talks = await _firebaseService.getPastTalks();
      
      // Sort by most recent first
      talks.sort((a, b) {
        final dateA = ConferenceDateUtils.parseConferenceDate(
            a['day'] ?? '', a['time'] ?? '');
        final dateB = ConferenceDateUtils.parseConferenceDate(
            b['day'] ?? '', b['time'] ?? '');
        
        // Most recent first (descending)
        return dateB.compareTo(dateA);
      });
      
      setState(() {
        pastTalks = talks;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        CommonWidgets.showNotificationBanner(
          context,
          message: 'Error loading past events: $e',
          isError: true,
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonWidgets.standardAppBar(
        title: 'Past Events',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPastEvents,
          ),
        ],
      ),
      body: isLoading
          ? CommonWidgets.loadingIndicator()
          : RefreshIndicator(
              onRefresh: _loadPastEvents,
              child: pastTalks.isEmpty
                  ? CommonWidgets.emptyState(
                      message: 'No past events found',
                      icon: Icons.history,
                    )
                  : ListView.builder(
                      itemCount: pastTalks.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final talk = pastTalks[index];
                        return _buildPastEventCard(talk);
                      },
                    ),
            ),
    );
  }
  
  Widget _buildPastEventCard(Map<String, dynamic> talk) {
    final talkColor = talk.containsKey('colorCode')
        ? Color(
            int.parse(talk['colorCode'].substring(1), radix: 16) | 0xFF000000)
        : Theme.of(context).colorScheme.primary;
    
    // Convert date string to DateTime for better display
    final eventDate = ConferenceDateUtils.parseConferenceDate(
        talk['day'] ?? '', talk['time'] ?? '');
    final formattedDate = ConferenceDateUtils.formatDateForDisplay(eventDate);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: talkColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () {
          AppRouter.navigateToTalkDetail(
            context,
            talk: talk,
            isAdmin: true, // Admin-only screen
            onUpdate: (updatedTalk) {
              _firebaseService.updateTalk(updatedTalk['id'], updatedTalk);
              _loadPastEvents(); // Refresh after update
            },
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date label with "Past Event" indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Past Event',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Event title
              Text(
                talk['title'] ?? 'Untitled Talk',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Speaker
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    talk['speaker'] ?? 'Unknown Speaker',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Date and time info
              Row(
                children: [
                  const Icon(Icons.event, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    talk['time'] ?? 'Unknown time',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Location and track
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      talk['location'] ?? 'Unknown location',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (talk['track'] != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: talkColor.withOpacity(0.1),
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
                    ),
                ],
              ),
              
              // View button
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                  onPressed: () {
                    AppRouter.navigateToTalkDetail(
                      context,
                      talk: talk,
                      isAdmin: true,
                      onUpdate: (updatedTalk) {
                        _firebaseService.updateTalk(updatedTalk['id'], updatedTalk);
                        _loadPastEvents();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}