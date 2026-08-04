// Profile page - Academic info & settings
//
// Layout (DESIGN.md §5.4 Profile Screen, HTML template lines 36-105):
// 1. App Bar — title "Profil Saya" + Edit + Refresh actions
// 2. Profile Header Card — avatar, name, study-program badge
// 3. Info Akademik — NPM, Program Studi, Semester
// 4. Tab Section — "Tentang" only (Aktivitas removed) → ProfileBioSection
// 5. "Perbarui Data" full-width action button
//
// Follows the same BLoC pattern as JadwalPage/HomePage:
// BlocProvider wraps _ProfilePageView, which uses BlocBuilder responding to
// ProfileInitial/ProfileLoading/ProfileLoaded/ProfileError states.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:lonceng_unman_fe/features/profile/domain/usecases/get_profile.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_event.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_state.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/academic_info_section.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/profile_action_button.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/profile_bio_section.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/profile_header_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.getProfile});

  /// Optional usecase injection for testing.
  /// When null, a stub implementation is used.
  final GetProfile? getProfile;

  static GetProfile _defaultGetProfile() {
    return GetProfile(
      ProfileRepositoryImpl(remoteDataSource: StubProfileRemoteDataSource()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ProfileBloc(getProfile ?? _defaultGetProfile())
            ..add(const ProfileFetchRequested()),
      child: const _ProfilePageView(),
    );
  }
}

class _ProfilePageView extends StatelessWidget {
  const _ProfilePageView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return _buildLoading(context);
          }

          if (state is ProfileError) {
            return _buildError(context, state.message);
          }

          if (state is ProfileLoaded) {
            return _buildContent(context, state);
          }

          return _buildLoading(context);
        },
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProfileLoaded state) {
    final data = state.data;
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProfileBloc>().add(const ProfileRefreshRequested());
      },
      child: CustomScrollView(
        slivers: [
          // 1. App Bar (DESIGN.md §5.4 — title + edit + refresh)
          SliverAppBar(
            title: const Text('Profil Saya'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {},
                tooltip: 'Edit Profil',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<ProfileBloc>().add(
                    const ProfileRefreshRequested(),
                  );
                },
                tooltip: 'Pembaruan Data',
              ),
            ],
          ),
          // 2-5. Content cards (DESIGN.md §5.4 layout)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ).copyWith(bottom: 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                // Profile Header Card (avatar + name + study program badge)
                ProfileHeaderCard(data: data),
                const SizedBox(height: 16),
                // Info Akademik (NPM, Program Studi, Semester)
                AcademicInfoSection(data: data),
                const SizedBox(height: 16),
                // Tab Section header
                _buildTabSection(cs),
                const SizedBox(height: 12),
                // Tentang tab content (bio + SKS/IPK stat cards)
                ProfileBioSection(data: data),
                const SizedBox(height: 24),
                // Action button — Perbarui Data
                ProfileActionButton(
                  onPressed: () {
                    context.read<ProfileBloc>().add(
                      const ProfileRefreshRequested(),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab section header with "Tentang" only (Aktivitas removed per spec).
  Widget _buildTabSection(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Tentang',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
