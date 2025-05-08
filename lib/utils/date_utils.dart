// lib/utils/date_utils.dart

class ConferenceDateUtils {
  static DateTime parseConferenceDate(String dayStr, String time) {
    try {
      // Parse the day string (assumed format: DD/MM/YY)
      final List<String> dateParts = dayStr.split('/');
      if (dateParts.length != 3) {
        return DateTime.now(); // Default to now if format is wrong
      }
      
      int day = int.tryParse(dateParts[0]) ?? 1;
      int month = int.tryParse(dateParts[1]) ?? 1;
      int year = int.tryParse(dateParts[2]) ?? DateTime.now().year;
      
      // Add 2000 to convert YY to YYYY if needed
      if (year < 100) {
        year += 2000;
      }
      
      // Parse the time string (assumed format: H:MM AM/PM)
      String formattedTime = time.trim();
      bool isPM = formattedTime.toLowerCase().endsWith('pm');
      
      // Remove AM/PM indicator
      formattedTime = formattedTime
          .toLowerCase()
          .replaceAll('am', '')
          .replaceAll('pm', '')
          .trim();
      
      final List<String> timeParts = formattedTime.split(':');
      int hour = int.tryParse(timeParts[0]) ?? 0;
      int minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
      
      // Convert to 24-hour format if PM
      if (isPM && hour < 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0; // 12 AM = 0 in 24-hour format
      }
      
      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      // Using a logger would be better in production code
      // For now, just comment out the print statement
      // print('Error parsing date: $e');
      return DateTime.now(); // Default to now
    }
  }
  
  static bool isEventInPast(String day, String time) {
    final eventDate = parseConferenceDate(day, time);
    return eventDate.isBefore(DateTime.now());
  }
  
  static String formatDateForDisplay(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}