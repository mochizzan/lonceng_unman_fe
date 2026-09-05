int deliveredIdFor(int scheduledId, DateTime trigger) {
  final millis = trigger.toUtc().millisecondsSinceEpoch;
  return ((scheduledId * 1000003) ^ millis) & 0x7FFFFFFF;
}
