// Login page - NPM + Password authentication
// Implements the full DESIGN.md §5.1 layout, aligned with HTML reference.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/errors/app_errors.dart';
import 'package:lonceng_unman_fe/core/utils/error_handler.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_progress_view.dart';
import 'package:lonceng_unman_fe/features/connectivity/cubit/connectivity_cubit.dart';
import 'package:lonceng_unman_fe/features/connectivity/cubit/connectivity_state.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_text_field.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_button.dart';
import 'package:lonceng_unman_fe/shared/widgets/auth_background.dart';
import 'package:lonceng_unman_fe/shared/widgets/bell_logo.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/widgets/review_screen.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/theme/app_shadows.dart';
import 'package:lonceng_unman_fe/core/utils/offline_sheet_controller.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authStatusNotifier});

  final AuthStatusNotifier authStatusNotifier;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _npmController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkCachedLogin();
  }

  /// Check for cached credentials and auto-login if found.
  Future<void> _checkCachedLogin() async {
    final bloc = context.read<AuthBloc>();
    final hasCached = await bloc.checkCachedCredentials();
    if (hasCached && mounted) {
      // Pre-fill form fields from bloc's cached values (no second disk read).
      _npmController.text = bloc.npm;
      _passwordController.text = bloc.password;
      bloc.add(AuthSubmitted());
    }
  }

  @override
  void deactivate() {
    try {
      final ctrl = Services.get<OfflineSheetController>();
      if (ctrl.isShowing) ctrl.dismissIfShowing(context);
    } catch (_) {}
    super.deactivate();
  }

  @override
  void dispose() {
    _npmController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listenWhen: (prev, curr) => prev.isOnline != curr.isOnline,
      listener: (context, state) {
        try {
          final authState = context.read<AuthBloc>().state;
          final isLoginForm =
              authState is AuthInitial || authState is AuthError;
          Services.get<OfflineSheetController>().sync(
            state.isOnline,
            context,
            isLoginForm: isLoginForm,
          );
        } catch (_) {}
      },
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Reset DataInitBloc state before triggering pipeline.
            // This handles re-login after logout (state may be DataInitSuccess
            // from previous session, which would block DataInitStarted).
            context.read<DataInitBloc>().add(const DataInitReset());
            // Trigger data-init pipeline on the login page.
            context.read<DataInitBloc>().add(
              DataInitStarted(
                npm: _npmController.text,
                password: _passwordController.text,
                forceRefresh: true,
              ),
            );
          } else if (state is AuthInitial) {
            // Clear form controllers when returning to login form
            // (e.g. after "bukan akun saya" rejection or logout).
            // BLoC's internal _npm/_password are already cleared;
            // controllers must match to avoid stale text + validation mismatch.
            _npmController.clear();
            _passwordController.clear();
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
          body: AuthBackground(
            child: SafeArea(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  // Shared content switches smoothly via AnimatedSwitcher.
                  // AuthBackground stays mounted — no background flash.
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: authState is AuthProfileReview
                        ? ReviewScreen(
                            key: const ValueKey('review'),
                            data: authState.profile,
                            onConfirm: () => context.read<AuthBloc>().add(
                              const AuthProfileConfirmed(),
                            ),
                            onReject: () => context.read<AuthBloc>().add(
                              const AuthProfileRejected(),
                            ),
                          )
                        : authState is AuthAuthenticated
                        ? DataInitProgressView(
                            key: const ValueKey('progress'),
                            isFreshLogin: true,
                            onComplete: () {
                              if (!mounted) return;
                              widget.authStatusNotifier.setStatus(
                                AuthStatus.authenticated,
                              );
                            },
                            onRetry: () {
                              context.read<DataInitBloc>().add(
                                const DataInitReset(),
                              );
                              context.read<AuthBloc>().add(
                                const AuthLogoutRequested(),
                              );
                            },
                            onCancel: () {
                              context.read<DataInitBloc>().add(
                                const DataInitReset(),
                              );
                              context.read<AuthBloc>().add(
                                const AuthLogoutRequested(),
                              );
                            },
                          )
                        : LayoutBuilder(
                            key: const ValueKey('login'),
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  sp(context, AppDimens.space24),
                                  sp(context, AppDimens.space16),
                                  sp(context, AppDimens.space24),
                                  sp(context, AppDimens.space32) + bottomInset,
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildGreeting(cs),
                                      SizedBox(
                                        height: sp(context, AppDimens.space32),
                                      ),
                                      _LoginCard(
                                        npmController: _npmController,
                                        passwordController: _passwordController,
                                      ),
                                      SizedBox(
                                        height: sp(context, AppDimens.space24),
                                      ),
                                      _buildFooter(cs),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
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
}

class _LoginCard extends StatefulWidget {
  const _LoginCard({
    required this.npmController,
    required this.passwordController,
  });

  final TextEditingController npmController;
  final TextEditingController passwordController;

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  bool _obscurePassword = true;

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
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: responsiveFontSize(context, AppDimens.text4XL),
            ),
          ),
          SizedBox(height: sp(context, AppDimens.space8)),
          Text(
            AppStrings.loginNpmHelper,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: responsiveFontSize(context, AppDimens.textMD),
            ),
          ),
          SizedBox(height: sp(context, AppDimens.space24)),

          // NPM Field
          AppTextField(
            key: const Key('npm_field'),
            controller: widget.npmController,
            label: AppStrings.loginNpmHint,
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            onChanged: (v) => context.read<AuthBloc>().add(AuthNpmChanged(v)),
          ),
          SizedBox(height: sp(context, AppDimens.space16)),

          // Password Field
          AppTextField(
            key: const Key('password_field'),
            controller: widget.passwordController,
            label: AppStrings.loginPasswordHint,
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: cs.onSurfaceVariant,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
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
