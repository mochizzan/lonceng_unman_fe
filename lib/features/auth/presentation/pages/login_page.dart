// Login page - NPM + Password authentication
// Implements the full DESIGN.md §5.1 layout, aligned with HTML reference.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/utils/error_handler.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_text_field.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_button.dart';
import 'package:lonceng_unman_fe/shared/widgets/auth_background.dart';
import 'package:lonceng_unman_fe/shared/widgets/bell_logo.dart';
import 'package:lonceng_unman_fe/core/theme/app_shadows.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authStatusNotifier, this.authBloc});

  final AuthStatusNotifier authStatusNotifier;

  /// Optional pre-built AuthBloc for testing.
  /// When null, a new BLoC is created internally.
  final AuthBloc? authBloc;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _npmController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc =
        widget.authBloc ??
        AuthBloc(Services.get<GetAuth>(), widget.authStatusNotifier);
    _checkCachedLogin();
  }

  /// Check for cached credentials and auto-login if found.
  Future<void> _checkCachedLogin() async {
    final hasCached = await _authBloc.checkCachedCredentials();
    if (hasCached && mounted) {
      // Pre-fill form fields from bloc's cached values (no second disk read).
      _npmController.text = _authBloc.npm;
      _passwordController.text = _authBloc.password;
      _authBloc.add(AuthSubmitted());
    }
  }

  @override
  void dispose() {
    _npmController.dispose();
    _passwordController.dispose();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _authBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            // Show Toast for network-level errors that can't display inline.
            // All other errors display inline via BlocBuilder below.
            if (state.error is NetworkException ||
                state.error is ServerException) {
              ErrorHandler.show(context, state.error!);
            }
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              AuthBackground(
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: sp(context, 24),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo & Greeting
                          _buildGreeting(cs),
                          SizedBox(height: sp(context, 32)),
                          // Login Card
                          _LoginCard(
                            npmController: _npmController,
                            passwordController: _passwordController,
                          ),
                          SizedBox(height: sp(context, 24)),
                          // Footer
                          _buildFooter(cs),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(ColorScheme cs) {
    return Column(
      children: [
        const BellLogo(),
        SizedBox(height: sp(context, 24)),
        Text(
          AppStrings.loginGreeting,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: cs.onSurface,
            fontSize: responsiveFontSize(context, 34),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: sp(context, 12)),
        Text(
          AppStrings.loginSubtitleDetail,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: responsiveFontSize(context, 14),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    return Text.rich(
      TextSpan(
        text: AppStrings.loginHelpdesk,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: AppColors.opacityMax),
          fontSize: responsiveFontSize(context, 12),
        ),
        children: [
          TextSpan(
            text: AppStrings.loginHelpdeskLink,
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.npmController,
    required this.passwordController,
  });

  final TextEditingController npmController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(sp(context, 28)),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(sp(context, 32)),
        boxShadow: AppShadows.cardResponsive(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          Text(
            AppStrings.loginButton,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: responsiveFontSize(context, 20),
            ),
          ),
          SizedBox(height: sp(context, 8)),
          Text(
            AppStrings.loginNpmHelper,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: responsiveFontSize(context, 14),
            ),
          ),
          SizedBox(height: sp(context, 24)),

          // NPM Field
          AppTextField(
            key: const Key('npm_field'),
            controller: npmController,
            label: AppStrings.loginNpmHint,
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            onChanged: (v) => context.read<AuthBloc>().add(AuthNpmChanged(v)),
          ),
          SizedBox(height: sp(context, 16)),

          // Password Field
          AppTextField(
            key: const Key('password_field'),
            controller: passwordController,
            label: AppStrings.loginPasswordHint,
            icon: Icons.lock_outline,
            obscureText: true,
            onChanged: (v) =>
                context.read<AuthBloc>().add(AuthPasswordChanged(v)),
          ),

          // Error message (shown below both fields)
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthError) {
                return Padding(
                  padding: EdgeInsets.only(top: sp(context, 12)),
                  child: Text(
                    state.message,
                    style: TextStyle(
                      color: cs.error,
                      fontSize: responsiveFontSize(context, 12),
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          SizedBox(height: sp(context, 24)),

          // Submit Button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final bloc = context.read<AuthBloc>();
              if (state is AuthLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return AppButton(
                onPressed: () => bloc.add(AuthSubmitted()),
                fullWidth: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.loginButton,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: responsiveFontSize(context, 14),
                      ),
                    ),
                    SizedBox(width: sp(context, 8)),
                    Icon(
                      Icons.arrow_forward,
                      size: sp(context, 20),
                      color: cs.onPrimaryContainer,
                    ),
                  ],
                ),
              );
            },
          ),

          // Helper text
          Text.rich(
            TextSpan(
              text: AppStrings.loginNoAccount,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: responsiveFontSize(context, 12),
              ),
              children: [
                TextSpan(
                  text: AppStrings.loginContactAdmin,
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
