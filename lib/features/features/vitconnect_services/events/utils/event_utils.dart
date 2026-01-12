class EventValidators {
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.length < 5) {
      return 'Title must be at least 5 characters';
    }
    if (value.length > 100) {
      return 'Title must be less than 100 characters';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  static String? validateVenue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Venue is required';
    }
    return null;
  }

  static String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category is required';
    }
    return null;
  }

  static String? validateEntryFee(String? value) {
    if (value == null || value.isEmpty) return null;

    final fee = int.tryParse(value);
    if (fee == null) {
      return 'Please enter a valid number';
    }
    if (fee < 0) {
      return 'Entry fee cannot be negative';
    }
    if (fee > 10000) {
      return 'Entry fee seems too high';
    }
    return null;
  }

  static String? validateTeamSize(String? value) {
    if (value == null || value.isEmpty) return null;

    final size = int.tryParse(value);
    if (size == null) {
      return 'Please enter a valid number';
    }
    if (size < 1) {
      return 'Team size must be at least 1';
    }
    if (size > 100) {
      return 'Team size seems too large';
    }
    return null;
  }

  static String? validateContact(String? value) {
    if (value == null || value.isEmpty) return null;

    if (value.length < 10) {
      return 'Contact info must be at least 10 characters';
    }
    return null;
  }
}

class EventFormatters {
  static String formatDateTime(DateTime dateTime) {
    final day = dateTime.day;
    final month = _monthNames[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$day $month $year, $displayHour:$minute $period';
  }

  static String formatDate(DateTime dateTime) {
    final day = dateTime.day;
    final month = _monthNames[dateTime.month - 1];
    final year = dateTime.year;
    return '$day $month $year';
  }

  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  static String formatEntryFee(int fee) {
    if (fee == 0) return 'FREE';
    return '₹$fee';
  }

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class EventCategories {
  static const List<String> all = [
    'Technical',
    'Cultural',
    'Sports',
    'Workshop',
    'Seminar',
    'Competition',
    'Conference',
    'Fest',
    'Social',
    'Other',
  ];

  static String getEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'technical':
        return '💻';
      case 'cultural':
        return '🎭';
      case 'sports':
        return '⚽';
      case 'workshop':
        return '🛠️';
      case 'seminar':
        return '📚';
      case 'competition':
        return '🏆';
      case 'conference':
        return '🎤';
      case 'fest':
        return '🎉';
      case 'social':
        return '🤝';
      default:
        return '📌';
    }
  }
}
