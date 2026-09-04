/// State for [ConnectivityCubit]. Plain value object — only the bool
/// flag matters, so equality compares just that field.
class ConnectivityState {
  const ConnectivityState({required this.isOnline});

  /// `true` when the device has any active network interface
  /// (wifi/cellular/ethernet/vpn/other), `false` when `none`.
  final bool isOnline;

  factory ConnectivityState.online() => const ConnectivityState(isOnline: true);
  factory ConnectivityState.offline() =>
      const ConnectivityState(isOnline: false);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectivityState && isOnline == other.isOnline;

  @override
  int get hashCode => isOnline.hashCode;
}
