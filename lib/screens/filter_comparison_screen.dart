import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/filter_options.dart';
import '../models/analysis_stats.dart';
import '../models/comparison_result.dart';
import '../services/sms_service.dart';
import 'comparison_screen.dart';

class FilterComparisonScreen extends StatefulWidget {
  final FilterOptions initialFilter;

  const FilterComparisonScreen({
    Key? key,
    required this.initialFilter,
  }) : super(key: key);

  @override
  State<FilterComparisonScreen> createState() => _FilterComparisonScreenState();
}

class _FilterComparisonScreenState extends State<FilterComparisonScreen> {
  final SmsService _smsService = SmsService();
  bool _isLoading = true;
  String _errorMessage = '';
  List<MapEntry<String, int>> _topSenders = [];

  // Selected filter (second filter for comparison)
  FilterType _selectedFilterType = FilterType.all;
  String? _selectedSender;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // First filter data
  AnalysisStats? _firstFilterStats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Make sure messages are loaded
      await _smsService.loadAllMessages();

      // Get filter data for the initial filter
      final firstFilterMessages = await _smsService.getFilteredMessages(widget.initialFilter);
      final firstFilterStats = _smsService.analyzeMessages(firstFilterMessages);

      // Get top senders for sender selection
      final topSenders = _smsService.getTopOtpSenders(5);

      // Set defaults for second filter
      if (topSenders.isNotEmpty) {
        // Choose a different sender than the first filter if possible
        if (widget.initialFilter.type == FilterType.bySender && topSenders.length > 1) {
          for (var sender in topSenders) {
            if (sender.key != widget.initialFilter.sender) {
              _selectedSender = sender.key;
              break;
            }
          }
        } else {
          _selectedSender = topSenders.first.key;
        }
      }

      // Get all messages for date range
      final allMessages = await _smsService.getFilteredMessages(FilterOptions.all());
      if (allMessages.isNotEmpty) {
        // Set date range defaults (different from first filter if possible)
        final dates = allMessages.map((msg) => msg.date).toList();
        final earliestDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
        final latestDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);

        // If the first filter is a date range, try to set a different range
        if (widget.initialFilter.type == FilterType.byDateRange) {
          final midpoint = widget.initialFilter.startDate!.add(
              Duration(
                  milliseconds: (widget.initialFilter.endDate!.difference(widget.initialFilter.startDate!).inMilliseconds ~/ 2)
              )
          );

          // Choose between earlier or later half
          if (midpoint.isAfter(earliestDate.add(const Duration(days: 15)))) {
            // Use earlier half
            _startDate = earliestDate;
            _endDate = midpoint;
          } else {
            // Use later half
            _startDate = midpoint;
            _endDate = latestDate;
          }
        } else {
          // Default to full range
          _startDate = earliestDate;
          _endDate = latestDate;
        }
      }

      setState(() {
        _firstFilterStats = firstFilterStats;
        _topSenders = topSenders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _proceedWithComparison() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Create second filter based on selection
      FilterOptions secondFilter;

      switch (_selectedFilterType) {
        case FilterType.all:
          secondFilter = FilterOptions.all();
          break;
        case FilterType.bySender:
          secondFilter = FilterOptions.bySender(_selectedSender!);
          break;
        case FilterType.byDateRange:
          secondFilter = FilterOptions.byDateRange(_startDate, _endDate);
          break;
      }

      // Get analysis for second filter
      final secondFilterMessages = await _smsService.getFilteredMessages(secondFilter);
      final secondFilterStats = _smsService.analyzeMessages(secondFilterMessages);

      // Create comparison result
      final comparison = ComparisonResult(
        firstStats: _firstFilterStats!,
        secondStats: secondFilterStats,
        firstFilter: widget.initialFilter,
        secondFilter: secondFilter,
      );

      setState(() {
        _isLoading = false;
      });

      // Navigate to comparison screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComparisonScreen(comparison: comparison),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to compare: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare with Another Filter'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentFilterCard(),
          const SizedBox(height: 24),

          const Text(
            'Choose a filter to compare with:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Filter options
          _buildFilterOption(
            title: 'All OTP Messages',
            description: 'Compare with all OTPs on your device',
            filterType: FilterType.all,
            icon: Icons.all_inclusive,
          ),

          const SizedBox(height: 16),
          _buildFilterOption(
            title: 'Filter by Sender',
            description: 'Compare with OTPs from a specific sender',
            filterType: FilterType.bySender,
            icon: Icons.person,
          ),

          // Show sender options if "Filter by Sender" is selected
          if (_selectedFilterType == FilterType.bySender)
            _buildSenderOptions(),

          const SizedBox(height: 16),
          _buildFilterOption(
            title: 'Filter by Date Range',
            description: 'Compare with OTPs from a specific time period',
            filterType: FilterType.byDateRange,
            icon: Icons.date_range,
          ),

          // Show date picker options if "Filter by Date Range" is selected
          if (_selectedFilterType == FilterType.byDateRange)
            _buildDateRangeOptions(),

          const SizedBox(height: 32),

          // Proceed button
          Center(
            child: ElevatedButton(
              onPressed: _proceedWithComparison,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Compare Filters',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentFilterCard() {
    String filterDescription;
    IconData filterIcon;

    switch (widget.initialFilter.type) {
      case FilterType.all:
        filterDescription = 'All OTP messages';
        filterIcon = Icons.all_inclusive;
        break;
      case FilterType.bySender:
        filterDescription = 'OTPs from ${widget.initialFilter.sender}';
        filterIcon = Icons.person;
        break;
      case FilterType.byDateRange:
        final dateFormat = DateFormat('MMM dd, yyyy');
        filterDescription = 'OTPs from ${dateFormat.format(widget.initialFilter.startDate!)} to ${dateFormat.format(widget.initialFilter.endDate!)}';
        filterIcon = Icons.date_range;
        break;
    }

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(filterIcon, color: Colors.blue[700]),
                const SizedBox(width: 12),
                const Text(
                  'Current Filter',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              filterDescription,
              style: TextStyle(
                color: Colors.blue[800],
                fontSize: 16,
              ),
            ),
            if (_firstFilterStats != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Found ${_firstFilterStats!.otpMessagesCount} OTP messages',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption({
    required String title,
    required String description,
    required FilterType filterType,
    required IconData icon,
  }) {
    final isSelected = _selectedFilterType == filterType;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilterType = filterType;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue[50] : Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? Theme.of(context).primaryColor : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderOptions() {
    if (_topSenders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No OTP senders found'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a sender:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...List.generate(_topSenders.length, (index) {
            final sender = _topSenders[index];
            return RadioListTile<String>(
              title: Text(sender.key),
              subtitle: Text('${sender.value} OTP messages'),
              value: sender.key,
              groupValue: _selectedSender,
              onChanged: (value) {
                setState(() {
                  _selectedSender = value;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDateRangeOptions() {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select date range:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Start date
          Row(
            children: [
              const Text('Start Date:'),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2000),
                      lastDate: _endDate,
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(dateFormat.format(_startDate)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // End date
          Row(
            children: [
              const Text('End Date:'),
              const SizedBox(width: 21),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: _startDate,
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(dateFormat.format(_endDate)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}