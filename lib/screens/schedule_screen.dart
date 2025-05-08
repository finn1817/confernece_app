// lib/screens/schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:conference_app/app_theme.dart';
import 'package:conference_app/widgets/common_widgets.dart';
import 'package:conference_app/widgets/filter_modal.dart'; // Add this import
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
  Map<String, String> activeFilters = {};
  String searchQuery = '';

  // Filter options derived from data
  Map<String, List<String>> filterOptions = {};

  // Admin toggle
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadTalks();
  }

  void _checkAdminStatus() {
    isAdmin = main.isAdminGlobal;
  }

  void _loadTalks() {
    setState(() => isLoading = true);
    
    _firebaseService.getUpcomingTalks().then(
      (talksList) {
        if (!mounted) return;
        
        setState(() {
          allTalks = talksList;

          // Extract all filter options from data
          _extractFilterOptions();
          
          // Apply any active filters
          _applyFilters();
          
          isLoading = false;
        });
      },
      onError: (error) {
        print('Error loading talks: $error');
        if (mounted) {
          setState(() => isLoading = false);
          CommonWidgets.showNotificationBanner(
            context,
            message: 'Error loading talks: $error',
            isError: true,
          );
        }
      },
    );
  }

  void _extractFilterOptions() {
    // Initialize filter maps
    final Map<String, Set<String>> optionSets = {
      'day': {},
      'track': {},
      'speaker': {},
      'location': {},
      'colorCode': {},
    };
    
    // Extract unique values for each filter type
    for (var talk in allTalks) {
      for (var key in optionSets.keys) {
        if (talk.containsKey(key) && talk[key] != null && talk[key].toString().isNotEmpty) {
          optionSets[key]!.add(talk[key].toString());
        }
      }
    }
    
    // Convert sets to sorted lists
    filterOptions = optionSets.map((key, valueSet) {
      final valueList = valueSet.toList()..sort();
      return MapEntry(key, valueList);
    });
  }

  void _applyFilters() {
    setState(() {
      filteredTalks = allTalks.where((talk) {
        // Apply search filter
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          final matchesSearch = 
            (talk['title']?.toString().toLowerCase().contains(query) ?? false) ||
            (talk['speaker']?.toString().toLowerCase().contains(query) ?? false) ||
            (talk['location']?.toString().toLowerCase().contains(query) ?? false) ||
            (talk['track']?.toString().toLowerCase().contains(query) ?? false) ||
            (talk['description']?.toString().toLowerCase().contains(query) ?? false);
          
          if (!matchesSearch) return false;
        }
        
        // Apply each active filter
        for (var entry in activeFilters.entries) {
          final field = entry.key;
          final value = entry.value;
          
          if (talk[field] == null || talk[field].toString() != value) {
            return false;
          }
        }
        
        return true;
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

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: FilterModalScreen(
          filterOptions: filterOptions,
          currentFilters: activeFilters,
          onApplyFilters: (filters) {
            setState(() {
              activeFilters = filters;
              _applyFilters();
            });
          },
          searchQuery: searchQuery,
          onSearchChanged: (query) {
            setState(() {
              searchQuery = query;
              _applyFilters();
            });
          },
        ),
      ),
    );
  }

  void updateTalk(Map<String, dynamic> updatedTalk) {
    _firebaseService.updateTalk(updatedTalk['id'], updatedTalk);
    _loadTalks(); // Refresh data after update
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
          // Add filter icon button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterModal,
            tooltip: 'Filter Events',
          ),
          
          // Logout/login button
          IconButton(
            icon: Icon(isAdmin ? Icons.logout : Icons.login),
            onPressed: isAdmin ? _showLogoutConfirmation : _showLoginDialog,
            tooltip: isAdmin ? 'Logout' : 'Login',
          ),
        ],
      ),
      body: isLoading
          ? CommonWidgets.loadingIndicator()
          : Column(
              children: [
                // Show active filters summary
                if (activeFilters.isNotEmpty || searchQuery.isNotEmpty)
                  _buildActiveFiltersBar(),
                
                // Events list
                Expanded(
                  child: _buildScheduleList(),
                ),
              ],
            ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => AppRouter.navigateToTalkForm(
                context,
                onSave: (newTalk) {
                  _firebaseService
                      .addTalk(newTalk)
                      .then((_) {
                        CommonWidgets.showNotificationBanner(
                          context,
                          message: 'New talk added',
                        );
                        _loadTalks(); // Refresh data
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

  Widget _buildActiveFiltersBar() {
    int totalFilters = activeFilters.length + (searchQuery.isNotEmpty ? 1 : 0);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Search query chip
                if (searchQuery.isNotEmpty)
                  Chip(
                    label: Text(
                      'Search: ${searchQuery.length > 15 ? '${searchQuery.substring(0, 15)}...' : searchQuery}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        searchQuery = '';
                        _applyFilters();
                      });
                    },
                  ),
                
                // Filter chips
                ...activeFilters.entries.map((entry) {
                  // Special case for color filter
                  if (entry.key == 'colorCode') {
                    final color = Color(int.parse(entry.value.substring(1), radix: 16) | 0xFF000000);
                    return Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Color', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          activeFilters.remove(entry.key);
                          _applyFilters();
                        });
                      },
                    );
                  }
                  
                  return Chip(
                    label: Text(
                      '${_getDisplayName(entry.key)}: ${entry.value.length > 15 ? '${entry.value.substring(0, 15)}...' : entry.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        activeFilters.remove(entry.key);
                        _applyFilters();
                      });
                    },
                  );
                }).toList(),
              ],
            ),
          ),
          
          // Clear all button
          if (totalFilters > 1)
            TextButton(
              onPressed: () {
                setState(() {
                  activeFilters.clear();
                  searchQuery = '';
                  _applyFilters();
                });
              },
              child: const Text('Clear All'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    if (filteredTalks.isEmpty) {
      return CommonWidgets.emptyState(
        message: activeFilters.isEmpty && searchQuery.isEmpty
            ? 'No upcoming events scheduled'
            : 'No events match your filters',
        icon: Icons.event_busy,
        onAction: activeFilters.isEmpty && searchQuery.isEmpty
            ? null
            : () {
                setState(() {
                  activeFilters.clear();
                  searchQuery = '';
                  _applyFilters();
                });
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

  // Your existing _buildTalkCard method remains unchanged

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
                        if (talk['isFavorite'] == true)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.star, color: Colors.amber, size: 20),
                          ),
                        if (isAdmin &&
                            (talk['hasMissingRegistration'] == true ||
                                talk['hasMissingCopyright'] == true))
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.warning,
                              color: AppTheme.warningColor,
                            ),
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

  String _getDisplayName(String filterType) {
    switch (filterType) {
      case 'day':
        return 'Date';
      case 'track':
        return 'Track';
      case 'speaker':
        return 'Speaker';
      case 'location':
        return 'Location';
      case 'colorCode':
        return 'Color';
      default:
        // Capitalize the first letter
        return filterType.substring(0, 1).toUpperCase() + filterType.substring(1);
    }
  }
}