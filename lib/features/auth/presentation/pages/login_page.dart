// Login page - NPM/password authentication
// Implements the full DESIGN.md §5.1 layout.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_button.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_text_field.dart';
import 'package:lonceng_unman_fe/shared/widgets/auth_background.dart';
import 'package:lonceng_unman_fe/shared/widgets/bell_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _npmController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _npmController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: AuthBackground(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.goNamed(RouteNames.home);
            }
          },
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    const BellLogo(),
                    const SizedBox(height: 24),
                    _LoginCard(
                      npmController: _npmController,
                      passwordController: _passwordController,
                    ),
                    const SizedBox(height: 24),
                    _buildFooter(cs),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    return Text(
      'Butuh bantuan? Helpdesk IT',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
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
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Masuk ke Akun', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Gunakan NPM aktif kamu',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            key: const Key('npm_field'),
            controller: widget.npmController,
            label: 'NPM',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            onChanged: (v) => context.read<AuthBloc>().add(AuthNpmChanged(v)),
          ),
          const SizedBox(height: 16),
          AppTextField(
            key: const Key('password_field'),
            controller: widget.passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: !_passwordVisible,
            suffix: IconButton(
              icon: Icon(
                _passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: cs.primary,
              ),
              onPressed: () {
                setState(() => _passwordVisible = !_passwordVisible);
                context.read<AuthBloc>().add(AuthPasswordVisibilityToggled());
              },
            ),
            onChanged: (v) =>
                context.read<AuthBloc>().add(AuthPasswordChanged(v)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: context.read<AuthBloc>().rememberMe,
                    onChanged: (v) => context.read<AuthBloc>().add(
                      AuthRememberMeToggled(v ?? false),
                    ),
                    activeColor: cs.primaryContainer,
                    checkColor: cs.onPrimaryContainer,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text('Ingat saya', style: theme.textTheme.bodyMedium),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Lupa NPM/Password?',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final bloc = context.read<AuthBloc>();
              if (state is AuthLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return AppButton(
                onPressed: () => bloc.add(AuthSubmitted()),
                fullWidth: true,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Masuk'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (previous, current) => current is AuthError,
            builder: (context, state) {
              if (state is AuthError) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    state.message,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Text.rich(
            TextSpan(
              text: 'NPM belum terdaftar? ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              children: [
                TextSpan(
                  text: 'Hubungi Admin',
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
