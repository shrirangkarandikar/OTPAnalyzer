class FilterOptions {
  final FilterType type;
  final String? sender;
  final DateTime? startDate;
  final DateTime? endDate;

  FilterOptions({
    this.type = FilterType.all,
    this.sender,
    this.startDate,
    this.endDate,
  });

  factory FilterOptions.all() {
    return FilterOptions(type: FilterType.all);
  }

  factory FilterOptions.bySender(String sender) {
    return FilterOptions(type: FilterType.bySender, sender: sender);
  }

  factory FilterOptions.byDateRange(DateTime startDate, DateTime endDate) {
    return FilterOptions(
      type: FilterType.byDateRange,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

enum FilterType {
  all,
  bySender,
  byDateRange,
}