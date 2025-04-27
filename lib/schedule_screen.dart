import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets/common_widgets.dart';
import 'router.dart';
import 'services/firebase_service.dart';
import 'package:conference_app/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool isAdmin = false;
  bool isLoading = true;
  List<Map<String, dynamic>> allTalks = [];
  List<Map<String, dynamic>> filteredTalks = [];
  
  // Filtering options
  String _selectedDay = 'All Days';
  String _selectedTrack = 'All Tracks';
  String _searchQuery = '';
  
  List<String> availableDays = ['All Days'];
  List<String> availableTracks = ['All Tracks'];
  
  @override
  void initState() {
    super.initState();
    _loadTalks();
  }
  
  void _loadTalks() {
    _firebaseService.getTalks().listen((talksList) {
      setState(() {
        allTalks = talksList;
        
        // Extract available days and tracks for filtering
        Set<String> daysSet = {'All Days'};
        Set<String> tracksSet = {'All Tracks'};
        
        for (var talk in talksList) {
          if (talk.containsKey('day') && talk['day'] != null) {
            daysSet.add(talk['day']);
          }
          if (talk.containsKey('track') && talk['track'] != null) {
            tracksSet.add(talk['track']);
          }
        }
        
        availableDays = daysSet.toList()..sort();
        availableTracks = tracksSet.toList()..sort();
        
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
        
        // Apply search filter
        bool matchesSearch = _searchQuery.isEmpty || 
                           (talk['title']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                           (talk['speaker']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                           (talk['description']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        
        return matchesDay && matchesTrack && matchesSearch;
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
          // Use a simple admin toggle for now (without the future builder)
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
          
          // Filter dropdowns
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