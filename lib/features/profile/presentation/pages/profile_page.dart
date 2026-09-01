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
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_refresh_overlay.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_event.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_state.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/academic_info_section.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/profile_action_button.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/edit_bio_bottom_sheet.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/profile_bio_section.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:lonceng_unman_fe/shared/widgets/bloc_scaffold.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfilePageView();
  }
}

class _ProfilePageView extends StatefulWidget {
  const _ProfilePageView();

  @override
  State<_ProfilePageView> createState() => _ProfilePageViewState();
}

class _ProfilePageViewState extends State<_ProfilePageView> {
  @override
  void initState() {
    super.initState();
    // If ProfileBloc is still in ProfileInitial when this page mounts,
    // dispatch fetch immediately. The BlocListener<DataInitBloc> in the
    // router only fires on STATE TRANSITIONS — if DataInitSuccess was
    // already emitted before we mounted, the listener won't re-fire and
    // the skeleton stays forever.
    final bloc = context.read<ProfileBloc>();
    if (bloc.state is ProfileInitial) {
      bloc.add(const ProfileFetchRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mengikat AvatarCubit global ke NPM yang sedang login. Memakai
      // BlocListener (bukan build) supaya bindNpm hanya dipanggil saat data
      // profil benar-benar berubah, bukan setiap rebuild.
      body: MultiBlocListener(
        listeners: [
          BlocListener<ProfileBloc, ProfileState>(
            listenWhen: (previous, current) => current is ProfileLoaded,
            listener: (context, state) {
              if (state is ProfileLoaded) {
                context.read<AvatarCubit>().bindNpm(state.data.npm);
              }
            },
          ),
          BlocListener<ProfileBloc, ProfileState>(
            listenWhen: (previous, current) =>
                current is ProfileError && previous is ProfileLoaded,
            listener: (context, state) {
              if (state is ProfileError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<ProfileBloc, ProfileState>(
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
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return _buildSkeleton(context);
  }

  Widget _buildSkeleton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = cs.surfaceContainerHighest.withValues(alpha: 0.7);
    final shapeColor = cs.surfaceContainerHighest;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(title: Text(AppStrings.profileTitleFull)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.screenPaddingHorizontal,
            ).copyWith(bottom: AppDimens.space80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppDimens.space16),
                // ── Profile Header Card skeleton ──
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(sp(context, 32)),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(sp(context, 32)),
                  ),
                  child: Column(
                    children: [
                      // Avatar circle
                      Container(
                        width: sp(context, 112),
                        height: sp(context, 112),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: shapeColor,
                        ),
                      ),
                      SizedBox(height: sp(context, 16)),
                      // Name line
                      Container(
                        height: 20,
                        width: sp(context, 160),
                        decoration: BoxDecoration(
                          color: shapeColor,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusSM,
                          ),
                        ),
                      ),
                      SizedBox(height: sp(context, 8)),
                      // Badge line
                      Container(
                        height: 28,
                        width: sp(context, 120),
                        decoration: BoxDecoration(
                          color: shapeColor,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusXL,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.space16),
                // ── Academic Info Section skeleton (3 rows) ──
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(sp(context, 20)),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(sp(context, 20)),
                  ),
                  child: Column(
                    children: List.generate(3, (i) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i < 2 ? sp(context, 16) : 0,
                        ),
                        child: Row(
                          children: [
                            // Icon badge circle
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: shapeColor,
                              ),
                            ),
                            SizedBox(width: sp(context, 12)),
                            // Label + value lines
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 12,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      color: shapeColor,
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusXS,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: sp(context, 6)),
                                  Container(
                                    height: 14,
                                    width: 140,
                                    decoration: BoxDecoration(
                                      color: shapeColor,
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusXS,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: AppDimens.space16),
                // ── Tab section header skeleton ──
                Container(
                  height: 24,
                  width: sp(context, 100),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(AppDimens.radiusXS),
                  ),
                ),
                const SizedBox(height: AppDimens.space12),
                // ── Bio section skeleton ──
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(sp(context, 20)),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(sp(context, 16)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(4, (i) {
                      final widths = [1.0, 0.9, 0.95, 0.7];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i < 3 ? sp(context, 10) : 0,
                        ),
                        child: FractionallySizedBox(
                          widthFactor: widths[i],
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: shapeColor,
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusXS,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: AppDimens.space24),
                // ── Action button skeleton ──
                Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return AppErrorDisplay(
      message: message,
      onRetry: () {
        context.read<ProfileBloc>().add(const ProfileRefreshRequested());
      },
    );
  }

  Widget _buildContent(BuildContext context, ProfileLoaded state) {
    final data = state.data;
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('[PROFILE] Pull-to-refresh triggered');
        await DataRefreshOverlay.triggerRefresh(context);
        context.read<ProfileBloc>().add(const ProfileRefreshRequested());
        // Refresh foto dari backend bersamaan dengan data akademik
        final academicCache = Services.get<AcademicCacheService>();
        final creds = await academicCache.loadCredentials();
        if (creds != null && context.mounted) {
          final npm = creds['npm'] ?? '';
          final password = creds['password'] ?? '';
          if (npm.isNotEmpty && password.isNotEmpty) {
            context.read<AvatarCubit>().fetchFromBackend(
              npm: npm,
              password: password,
            );
          }
        }
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
                  showEditBioBottomSheet(context, currentBio: data.bio);
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
                // Profile Header Card (avatar + name + study program badge).
                // AvatarCubit dibaca dari provider root (singleton global) dan
                // diikat ke NPM lewat BlocListener di build().
                ProfileHeaderCard(data: data),
                const SizedBox(height: AppDimens.space16),
                // Info Akademik (NPM, Program Studi, Semester) + Selengkapnya
                AcademicInfoSection(
                  data: data,
                  onSelengkapnyaPressed: () {
                    context.pushNamed(RouteNames.profilLengkap);
                  },
                ),
                const SizedBox(height: AppDimens.space16),
                // Tab Section header
                _buildTabSection(cs),
                const SizedBox(height: AppDimens.space12),
                // Tentang tab content (bio)
                ProfileBioSection(data: data),
                const SizedBox(height: AppDimens.space16),
                // Divider + label before action buttons
                _buildSectionDivider(cs, 'Lainnya'),
                const SizedBox(height: AppDimens.space16),
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
            color: cs.outlineVariant.withValues(alpha: ColorValues.opacityHigh),
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
            color: cs.outlineVariant.withValues(alpha: ColorValues.opacityHigh),
          ),
        ),
      ],
    );
  }

  /// Section divider with centered label (e.g., "Lainnya").
  Widget _buildSectionDivider(ColorScheme cs, String label) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: ColorValues.opacityHigh),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppDimens.textSM,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: ColorValues.opacityHigh),
          ),
        ),
      ],
    );
  }
}
