import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';

/// Whether [state] corresponds to the login form (eligible to show offline sheet).
bool isLoginFormState(AuthState state) =>
    state is AuthInitial || state is AuthError;
