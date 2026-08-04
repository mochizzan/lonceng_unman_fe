// Login page - NPM authentication
// Implements the full DESIGN.md Â§5.1 layout, aligned with HTML reference.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_state.dart';
import 'package:lonceng_unman_fe/shared/widgets/app_text_field.dart';
import 'package:lonceng_unman_fe/shared/widgets/auth_background.dart';
import 'package:lonceng_unman_fe/shared/widgets/bell_logo.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _npmController = TextEditingController();

  @override
  void dispose() {
    _npmController.dispose();
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
                    // Logo & Greeting (outside card, matches HTML)
                    _buildGreeting(cs),
                    SizedBox(height: sp(context, 24)),
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
    );
  }

  Widget _buildGreeting(ColorScheme cs) {
    return Column(
      children: [
        const BellLogo(),
        SizedBox(height: sp(context, 24)),
        Text(
          'Halo Mahasiswa!',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: cs.onSurface,
            fontSize: responsiveFontSize(context, 34),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: sp(context, 12)),
        Text(
          'Masuk dengan NPM kamu untuk melihat jadwal & info perkuliahan.',
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
    return Text(
      'Butuh bantuan? Helpdesk IT',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        fontSize: responsiveFontSize(context, 12),
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
      margin: EdgeInsets.symmetric(horizontal: sp(context, 24)),
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
            'Masuk Akun',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: responsiveFontSize(context, 20),
            ),
          ),
          SizedBox(height: sp(context, 8)),
          Text(
            'Gunakan NPM aktif kamu',
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
            label: 'NPM',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            onChanged: (v) => context.read<AuthBloc>().add(AuthNpmChanged(v)),
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
                  backgroundColor: cs.secondaryContainer,
                  foregroundColor: cs.onSecondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(sp(context, 20)),
                  ),
                  padding: EdgeInsets.symmetric(vertical: sp(context, 16)),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Masuk',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: responsiveFontSize(context, 14),
                      ),
                    ),
                    SizedBox(width: sp(context, 8)),
                    Icon(
                      Icons.arrow_forward,
                      size: sp(context, 20),
                      color: cs.onSecondaryContainer,
                    ),
                  ],
                ),
              );
            },
          ),

          // Error message
          BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (previous, current) => current is AuthError,
            builder: (context, state) {
              if (state is AuthError) {
                return Padding(
                  padding: EdgeInsets.only(top: sp(context, 8)),
                  child: Text(
                    state.message,
                    style: theme.textTheme.bodySmall?.copyWith(
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

          // Helper text
          Text.rich(
            TextSpan(
              text: 'NPM belum terdaftar? ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: responsiveFontSize(context, 12),
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
