// lib/widgets/filter_modal.dart

import 'package:flutter/material.dart';
import 'package:conference_app/app_theme.dart';
import 'package:conference_app/widgets/common_widgets.dart';

class FilterModalScreen extends StatefulWidget {
  final Map<String, List<String>> filterOptions;
  final Map<String, String> currentFilters;
  final Function(Map<String, String>) onApplyFilters;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const FilterModalScreen({
    Key? key,
    required this.filterOptions,
    required this.currentFilters,
    required this.onApplyFilters,
    required this.searchQuery,
    required this.onSearchChanged,
  }) : super(key: key);

  @override
  _FilterModalScreenState createState() => _FilterModalScreenState();
}

class _FilterModalScreenState extends State<FilterModalScreen> {
  late Map<String, String> selectedFilters;
  late TextEditingController _searchController;
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    selectedFilters = Map.from(widget.currentFilters);
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    bool changed = false;
    
    // Check if any filter value has changed
    widget.currentFilters.forEach((key, value) {
      if (selectedFilters[key] != value) {
        changed = true;
      }
    });
    
    // Check if any new filter has been added
    selectedFilters.forEach((key, value) {
      if (!widget.currentFilters.containsKey(key) || widget.currentFilters[key] != value) {
        changed = true;
      }
    });
    
    // Check if search query changed
    if (_searchController.text != widget.searchQuery) {
      changed = true;
    }
    
    setState(() {
      hasChanges = changed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Events'),
        actions: [
          if (hasChanges || selectedFilters.isNotEmpty || _searchController.text.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              onPressed: () {
                setState(() {
                  selectedFilters = {};
                  _searchController.clear();
                  hasChanges = true;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  hasChanges = true;
                });
              },
            ),
          ),
          
          // Filter sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                // Build each filter type
                ...widget.filterOptions.entries.map((entry) {
                  final filterType = entry.key;
                  final options = entry.value;
                  
                  // Special case for color filter
                  if (filterType == 'colorCode') {
                    return _buildColorFilter(filterType, options);
                  }
                  
                  return _buildFilterSection(filterType, options);
                }).toList(),
                
                const SizedBox(height: 100), // Bottom padding for better scrolling
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedFilters.isEmpty
                      ? 'No filters applied'
                      : '${selectedFilters.length} filter${selectedFilters.length > 1 ? 's' : ''} applied',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              ElevatedButton(
                onPressed: hasChanges
                    ? () {
                        widget.onSearchChanged(_searchController.text);
                        widget.onApplyFilters(selectedFilters);
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text('Apply Filters'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(String filterType, List<String> options) {
    final String displayName = _getDisplayName(filterType);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            // "All" option
            ChoiceChip(
              label: const Text('All'),
              selected: !selectedFilters.containsKey(filterType) || 
                      selectedFilters[filterType] == 'All',
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    if (selectedFilters.containsKey(filterType)) {
                      selectedFilters.remove(filterType);
                    }
                    hasChanges = true;
                  });
                }
              },
            ),
            
            // Each option
            ...options.map((option) {
              final bool isSelected = selectedFilters[filterType] == option;
              
              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedFilters[filterType] = option;
                    } else if (isSelected) {
                      selectedFilters.remove(filterType);
                    }
                    hasChanges = true;
                  });
                  _checkForChanges();
                },
              );
            }).toList(),
          ],
        ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildColorFilter(String filterType, List<String> colorCodes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            'Color',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: [
            // "All Colors" option
            GestureDetector(
              onTap: () {
                setState(() {
                  if (selectedFilters.containsKey(filterType)) {
                    selectedFilters.remove(filterType);
                  }
                  hasChanges = true;
                });
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: !selectedFilters.containsKey(filterType) ? 
                      Theme.of(context).colorScheme.primary : 
                      Colors.grey.shade300,
                    width: !selectedFilters.containsKey(filterType) ? 3 : 1,
                  ),
                  gradient: const LinearGradient(
                    colors: [Colors.red, Colors.green, Colors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: !selectedFilters.containsKey(filterType) ?
                  const Icon(Icons.check, color: Colors.white) : null,
              ),
            ),
            
            // Each color option
            ...colorCodes.map((colorCode) {
              final color = Color(int.parse(colorCode.substring(1), radix: 16) | 0xFF000000);
              final bool isSelected = selectedFilters[filterType] == colorCode;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedFilters.remove(filterType);
                    } else {
                      selectedFilters[filterType] = colorCode;
                    }
                    hasChanges = true;
                  });
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? 
                        Theme.of(context).colorScheme.primary : 
                        Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected ?
                    Icon(
                      Icons.check,
                      color: _isLightColor(color) ? Colors.black : Colors.white,
                    ) : null,
                ),
              );
            }).toList(),
          ],
        ),
        const Divider(height: 32),
      ],
    );
  }

  bool _isLightColor(Color color) {
    // Formula to determine if a color is light or dark
    return (color.red * 0.299 + color.green * 0.587 + color.blue * 0.114) > 186;
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