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
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/profile/domain/usecases/get_profile.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_event.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_state.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/academic_info_section.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/profile_action_button.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/profile_bio_section.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:lonceng_unman_fe/shared/widgets/bloc_scaffold.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.getProfile});

  /// Optional usecase injection for testing.
  /// When null, a stub implementation is used.
  final GetProfile? getProfile;

  static GetProfile _defaultGetProfile() => Services.get<GetProfile>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: true,
      create: (_) => ProfileBloc(getProfile ?? _defaultGetProfile()),
      child: const _ProfilePageView(),
    );
  }
}

class _ProfilePageView extends StatelessWidget {
  const _ProfilePageView();

  @override
  Widget build(BuildContext context) {
    // Dispatch initial fetch when this widget first builds.
    // The BLoC is lazy — it was not created in BlocProvider.create.
    context.read<ProfileBloc>().add(const ProfileFetchRequested());

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
    return const AppLoadingIndicator();
  }

  Widget _buildError(BuildContext context, String message) {
    return AppErrorDisplay(message: message);
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
          // 1. App Bar (DESIGN.md §5.4 — title + edit)
          SliverAppBar(
            title: const Text(AppStrings.profileTitleFull),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: cs.onSurface),
                onPressed: () {
                  // TODO: Navigate to edit profile page
                },
                tooltip: AppStrings.profileEditTooltip,
              ),
            ],
          ),
          // 2-5. Content cards (DESIGN.md §5.4 layout)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.screenPaddingHorizontal,
            ).copyWith(bottom: AppDimens.space80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppDimens.space16),
                // Profile Header Card (avatar + name + study program badge)
                ProfileHeaderCard(data: data),
                const SizedBox(height: AppDimens.space16),
                // Info Akademik (NPM, Program Studi, Semester)
                AcademicInfoSection(data: data),
                const SizedBox(height: AppDimens.space16),
                // Tab Section header
                _buildTabSection(cs),
                const SizedBox(height: AppDimens.space12),
                // Tentang tab content (bio + SKS/IPK stat cards)
                ProfileBioSection(data: data),
                const SizedBox(height: AppDimens.space24),
                // Action button — Pengaturan
                const ProfileActionButton(),
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
            color: cs.outlineVariant.withValues(alpha: AppColors.opacityHigh),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
          child: Text(
            AppStrings.profileTabAbout,
            style: TextStyle(
              fontSize: AppDimens.textMD,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: AppColors.opacityHigh),
          ),
        ),
      ],
    );
  }
}
