// Login page - NPM + Password authentication
// Implements the full DESIGN.md §5.1 layout, aligned with HTML reference.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/utils/error_handler.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_status_text.dart';
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
  bool _loginSuccess = false;

  @override
  void initState() {
    super.initState();
    _authBloc =
        widget.authBloc ??
        AuthBloc(
          Services.get<GetAuth>(),
          academicCacheService: Services.get<AcademicCacheService>(),
        );
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return BlocProvider.value(
      value: _authBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            setState(() => _loginSuccess = true);
            // Reset DataInitBloc state before triggering pipeline.
            // This handles re-login after logout (state may be DataInitSuccess
            // from previous session, which would block DataInitStarted).
            context.read<DataInitBloc>().add(const DataInitReset());
            // Trigger data-init pipeline on the login page.
            context.read<DataInitBloc>().add(
              DataInitStarted(
                npm: _npmController.text,
                password: _passwordController.text,
              ),
            );
          } else if (state is AuthError) {
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
                    child: _loginSuccess
                        ? _buildProgressUI(context)
                        : SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              sp(context, AppDimens.space24),
                              sp(context, AppDimens.space16),
                              sp(context, AppDimens.space24),
                              sp(context, AppDimens.space32) + bottomInset,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Logo & Greeting
                                _buildGreeting(cs),
                                SizedBox(
                                  height: sp(context, AppDimens.space32),
                                ),
                                // Login Card
                                _LoginCard(
                                  npmController: _npmController,
                                  passwordController: _passwordController,
                                ),
                                SizedBox(
                                  height: sp(context, AppDimens.space24),
                                ),
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
        SizedBox(height: sp(context, AppDimens.space24)),
        Text(
          AppStrings.loginGreeting,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: cs.onSurface,
            fontSize: responsiveFontSize(context, AppDimens.textDisplay),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: sp(context, AppDimens.space12)),
        Text(
          AppStrings.loginSubtitleDetail,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: responsiveFontSize(context, AppDimens.textMD),
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
          color: cs.onSurfaceVariant.withValues(alpha: ColorValues.opacityMax),
          fontSize: responsiveFontSize(context, AppDimens.textSM),
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

  /// Progress UI shown after successful login while data-init runs.
  Widget _buildProgressUI(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocBuilder<DataInitBloc, DataInitBlocState>(
      builder: (context, state) {
        final statusText = state is DataInitInProgress
            ? dataInitStatusText(state.status)
            : 'Menyiapkan data...';

        final isCompleted = state is DataInitSuccess;

        if (isCompleted && mounted) {
          // Navigate to home after the current frame so the widget tree
          // can settle before GoRouter replaces the route.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            // Mark authenticated so the router guard allows /home.
            widget.authStatusNotifier.setStatus(AuthStatus.authenticated);
          });
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const BellLogo(),
            SizedBox(height: sp(context, AppDimens.space32)),

            // Status text
            Text(
              isCompleted ? 'Data akademik siap' : statusText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurface,
                fontSize: responsiveFontSize(context, AppDimens.textMD),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: sp(context, AppDimens.space24)),

            // Progress indicator
            if (!isCompleted) CircularProgressIndicator(color: cs.primary),

            // Error message with retry button
            if (state is DataInitFailure)
              Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: cs.error),
                  SizedBox(height: sp(context, AppDimens.space16)),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
                  ),
                  SizedBox(height: sp(context, AppDimens.space24)),
                  FilledButton(
                    onPressed: () {
                      context.read<DataInitBloc>().add(const DataInitReset());
                      setState(() => _loginSuccess = false);
                    },
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
          ],
        );
      },
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

  /// Reserved height for the submit action area so swapping
  /// AppButton ↔ CircularProgressIndicator does not shift layout.
  /// Matches AppButton vertical padding + typical label line.
  static const double _submitAreaHeight = AppDimens.space48 + AppDimens.space8;

  /// Reserved height for the inline error slot so showing/hiding
  /// the error text does not expand or collapse the card.
  static const double _errorSlotHeight = AppDimens.space32;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(sp(context, AppDimens.space28)),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(
          sp(context, AppDimens.cardHeroRadius),
        ),
        boxShadow: AppShadows.cardResponsive(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          Text(
            AppStrings.loginButton,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: responsiveFontSize(context, AppDimens.text4XL),
            ),
          ),
          SizedBox(height: sp(context, AppDimens.space8)),
          Text(
            AppStrings.loginNpmHelper,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: responsiveFontSize(context, AppDimens.textMD),
            ),
          ),
          SizedBox(height: sp(context, AppDimens.space24)),

          // NPM Field
          AppTextField(
            key: const Key('npm_field'),
            controller: npmController,
            label: AppStrings.loginNpmHint,
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            onChanged: (v) => context.read<AuthBloc>().add(AuthNpmChanged(v)),
          ),
          SizedBox(height: sp(context, AppDimens.space16)),

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

          // Error message — fixed-height slot prevents layout shift
          SizedBox(
            height: sp(context, _errorSlotHeight),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthError) {
                  return Align(
                    alignment: Alignment.center,
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: cs.error,
                        fontSize: responsiveFontSize(context, AppDimens.textSM),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          SizedBox(height: sp(context, AppDimens.space8)),

          // Submit Button — fixed-height area keeps card stable while loading
          SizedBox(
            height: sp(context, _submitAreaHeight),
            child: BlocBuilder<AuthBloc, AuthState>(
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
                          fontSize: responsiveFontSize(
                            context,
                            AppDimens.textMD,
                          ),
                        ),
                      ),
                      SizedBox(width: sp(context, AppDimens.space8)),
                      Icon(
                        Icons.arrow_forward,
                        size: sp(context, AppDimens.iconMD),
                        color: cs.onPrimaryContainer,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
