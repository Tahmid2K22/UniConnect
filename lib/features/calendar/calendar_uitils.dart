int calculateDaysBetween(DateTime start, DateTime end) {
  return end.difference(start).inDays;
}

String formatDate(DateTime date) {
  return "${date.day}/${date.month}/${date.year}";
}
