// Login page - NPM authentication
// Implements the full DESIGN.md Â§5.1 layout, aligned with HTML reference.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_text_field.dart';
import 'package:lonceng_unman_fe/shared/widgets/auth_background.dart';
import 'package:lonceng_unman_fe/shared/widgets/bell_logo.dart';
import 'package:lonceng_unman_fe/shared/widgets/notification_test_button.dart';
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
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc =
        widget.authBloc ??
        AuthBloc(Services.get<GetAuth>(), widget.authStatusNotifier);
  }

  @override
  void dispose() {
    _npmController.dispose();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _authBloc,
      child: Scaffold(
        body: Stack(
          children: [
            AuthBackground(
              child: BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthAuthenticated) {
                    context.goNamed(RouteNames.home);
                  }
                },
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
                          _LoginCard(npmController: _npmController),
                          SizedBox(height: sp(context, 24)),
                          // Footer
                          _buildFooter(cs),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Fixed-position test notification button
            const NotificationTestButton(),
          ],
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
  const _LoginCard({required this.npmController});

  final TextEditingController npmController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(sp(context, 28)),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(sp(context, 32)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            offset: Offset(0, sp(context, 4)),
            blurRadius: sp(context, 12),
          ),
        ],
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

          // NPM Field (error shown inline on the field)
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final errorText = state is AuthError ? state.message : null;
              return AppTextField(
                key: const Key('npm_field'),
                controller: npmController,
                label: AppStrings.loginNpmHint,
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                errorText: errorText,
                onChanged: (v) =>
                    context.read<AuthBloc>().add(AuthNpmChanged(v)),
              );
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
              return FilledButton(
                onPressed: () => bloc.add(AuthSubmitted()),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.onPrimaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(sp(context, 24)),
                  ),
                  padding: EdgeInsets.symmetric(vertical: sp(context, 16)),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
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
