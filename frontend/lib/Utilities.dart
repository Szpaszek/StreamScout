import 'package:intl/intl.dart';

class Utilities {
  
    static String formatDate(String dateString) {
    if (dateString == 'Unknown' || dateString.isEmpty) return 'Unknown';
    try{
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('dd. MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}