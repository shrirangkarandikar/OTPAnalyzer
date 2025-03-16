import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/filter_options.dart';
import '../services/sms_service.dart';
import '../models/sms_message.dart';
import 'dashboard_screen.dart';

class FilterSelectionScreen extends StatefulWidget {
  const FilterSelectionScreen({Key? key}) : super(key: key);

  @override
  State<FilterSelectionScreen> createState() => _FilterSelectionScreenState();
}

class _FilterSelectionScreenState extends State<FilterSelectionScreen> {
  final SmsService _smsService = SmsService();
  bool _isLoading = true;
  String _errorMessage = '';
  List<MapEntry<String, int>> _topSenders = [];
  FilterType _selectedFilterType = FilterType.all;
  List<SmsMessageModel> _allMessages = [];

  // Date range selection
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedSender;

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

      // Load all messages first
      final messages = await _smsService.loadAllMessages();
      _allMessages = messages;

      // Get top OTP senders
      final topSenders = _smsService.getTopOtpSenders(3);

      // Set date range to earliest and latest message dates
      if (messages.isNotEmpty) {
        final dates = messages.map((msg) => msg.date).toList();
        final earliestDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
        final latestDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);

        _startDate = earliestDate;
        _endDate = latestDate;
      }

      setState(() {
        _topSenders = topSenders;
        if (topSenders.isNotEmpty) {
          _selectedSender = topSenders.first.key;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load messages: $e';
        _isLoading = false;
      });
    }
  }

  void _proceedWithFilter() {
    FilterOptions filterOptions;

    switch (_selectedFilterType) {
      case FilterType.all:
        filterOptions = FilterOptions.all();
        break;
      case FilterType.bySender:
        filterOptions = FilterOptions.bySender(_selectedSender!);
        break;
      case FilterType.byDateRange:
        filterOptions = FilterOptions.byDateRange(_startDate, _endDate);
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(filterOptions: filterOptions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Analysis Options'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
          const Text(
            'Choose OTP Analysis Options',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Found ${_allMessages.length} messages in total',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),

          // Filter options
          _buildFilterOption(
            title: 'Analyze All OTP Messages',
            description: 'Include all OTP messages found on your device',
            filterType: FilterType.all,
            icon: Icons.all_inclusive,
          ),

          const SizedBox(height: 16),
          _buildFilterOption(
            title: 'Filter by Sender',
            description: 'Analyze OTPs from a specific sender',
            filterType: FilterType.bySender,
            icon: Icons.person,
          ),

          // Show sender options if "Filter by Sender" is selected
          if (_selectedFilterType == FilterType.bySender)
            _buildSenderOptions(),

          const SizedBox(height: 16),
          _buildFilterOption(
            title: 'Filter by Date Range',
            description: 'Analyze OTPs from a specific time period',
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
              onPressed: _proceedWithFilter,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Proceed with Analysis',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
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