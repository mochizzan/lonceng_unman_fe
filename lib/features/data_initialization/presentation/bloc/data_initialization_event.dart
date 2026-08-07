/// DataInitEvent hierarchy for the data initialization BLoC.
abstract class DataInitEvent {
  const DataInitEvent();
}

class DataInitStarted extends DataInitEvent {
  final String npm;
  final String password;

  const DataInitStarted({required this.npm, required this.password});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataInitStarted &&
          runtimeType == other.runtimeType &&
          npm == other.npm &&
          password == other.password;

  @override
  int get hashCode => Object.hash(npm, password);
}

class DataInitReset extends DataInitEvent {
  const DataInitReset();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataInitReset && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
