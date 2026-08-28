import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/manager/app_manager.dart';
import 'package:fl_clash/models/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

typedef OnSelected = void Function(int index);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _handleToPage(PageLabel pageLabel) {
    globalState.container
        .read(currentPageLabelProvider.notifier)
        .toPage(pageLabel);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasViewSize = ref.watch(
      viewSizeProvider.select((size) => !size.isEmpty),
    );
    if (!hasViewSize) {
      return const SizedBox.shrink();
    }
    return HomeBackScopeContainer(
      child: AppSidebarContainer(
        child: LiquidWallpaper(
          child: Material(
            color: Colors.transparent,
            child: Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(navigationStateProvider);
                final isMobile = state.viewMode == ViewMode.mobile;
                final navigationItems = state.navigationItems;
                final currentIndex = state.currentIndex;
                final bottomNavigationBar = Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: LiquidNavigationBar(
                    selectedIndex: currentIndex,
                    onDestinationSelected: (index) {
                      _handleToPage(navigationItems[index].label);
                    },
                    destinations: navigationItems
                        .map(
                          (e) => Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              e.icon,
                              const SizedBox(height: 2),
                              Text(
                                Intl.message(e.label.name),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                );
                return Column(
                  children: [
                    Flexible(
                      flex: 1,
                      child: FocusTraversalGroup(
                        policy: PageTraversalPolicy(),
                        child: MediaQuery.removePadding(
                          removeTop: false,
                          removeBottom: isMobile,
                          removeLeft: isMobile,
                          removeRight: isMobile,
                          context: context,
                          child: child!,
                        ),
                      ),
                    ),
                    AnimatedVisibility.bottomNavigation(
                      visible: isMobile,
                      child: MediaQuery.removePadding(
                        removeTop: true,
                        removeBottom: false,
                        removeLeft: true,
                        removeRight: true,
                        context: context,
                        child: bottomNavigationBar,
                      ),
                    ),
                  ],
                );
              },
              child: Consumer(
                builder: (_, ref, _) {
                  final navigationItems = ref
                      .watch(currentNavigationItemsStateProvider)
                      .value;
                  final isMobile = ref.watch(isMobileViewProvider);
                  return _HomePageView(
                    navigationItems: navigationItems,
                    pageBuilder: (_, index) {
                      final navigationItem = navigationItems[index];
                      final navigationView = navigationItem.builder(context);
                      final scopedView = PageFocusScope(child: navigationView);
                      final view = KeepScope(
                        key: ValueKey(navigationItem.label),
                        keep: navigationItem.keep,
                        child: isMobile
                            ? scopedView
                            : Navigator(
                                key: ValueKey(
                                  '${navigationItem.label.name}_navigator',
                                ),
                                pages: [MaterialPage(child: scopedView)],
                                onDidRemovePage: (_) {},
                              ),
                      );
                      return Consumer(
                        key: ValueKey(navigationItem.label),
                        builder: (_, ref, child) {
                          final isActive = ref.watch(
                            currentPageLabelProvider.select(
                              (label) => label == navigationItem.label,
                            ),
                          );
                          return PageActivityScope(
                            isActive: isActive,
                            child: ExcludeFocus(
                              excluding: !isActive,
                              child: child!,
                            ),
                          );
                        },
                        child: view,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePageView extends ConsumerStatefulWidget {
  final IndexedWidgetBuilder pageBuilder;
  final List<NavigationItem> navigationItems;

  const _HomePageView({
    required this.pageBuilder,
    required this.navigationItems,
  });

  @override
  ConsumerState createState() => _HomePageViewState();
}

class _HomePageViewState extends ConsumerState<_HomePageView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _pageIndex);
    ref.listenManual(currentPageLabelProvider, (prev, next) {
      if (prev != next) {
        _toPage(next);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _HomePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationItems.length != widget.navigationItems.length) {
      _updatePageController();
    }
  }

  int get _pageIndex {
    final pageLabel = ref.read(currentPageLabelProvider);
    return widget.navigationItems.indexWhere((item) => item.label == pageLabel);
  }

  Future<void> _toPage(
    PageLabel pageLabel, [
    bool ignoreAnimateTo = false,
  ]) async {
    if (!mounted) {
      return;
    }
    final index = widget.navigationItems.indexWhere(
      (item) => item.label == pageLabel,
    );
    if (index == -1) {
      return;
    }
    final isAnimateToPage = ref.read(appSettingProvider).isAnimateToPage;
    final isMobile = ref.read(isMobileViewProvider);
    if (isAnimateToPage && isMobile && !ignoreAnimateTo) {
      await _pageController.animateToPage(
        index,
        duration: kTabScrollDuration,
        curve: Curves.easeOut,
      );
    } else {
      _pageController.jumpToPage(index);
    }
  }

  void _updatePageController() {
    final pageLabel = ref.read(currentPageLabelProvider);
    _toPage(pageLabel, true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = ref.watch(
      currentNavigationItemsStateProvider.select((state) => state.value.length),
    );
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      findChildIndexCallback: (key) {
        if (key is! ValueKey<PageLabel>) {
          return null;
        }
        final index = widget.navigationItems.indexWhere(
          (item) => item.label == key.value,
        );
        return index == -1 ? null : index;
      },
      itemBuilder: (context, index) {
        return widget.pageBuilder(context, index);
      },
    );
  }
}

class HomeBackScopeContainer extends ConsumerWidget {
  final Widget child;

  const HomeBackScopeContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context, ref) {
    return CommonPopScope(
      onPop: (context) async {
        final pageLabel = ref.read(currentPageLabelProvider);
        final realContext =
            GlobalObjectKey(pageLabel).currentContext ?? context;
        final canPop = Navigator.canPop(realContext);
        if (canPop) {
          Navigator.of(realContext).pop();
        } else {
          await globalState.container
              .read(systemActionProvider.notifier)
              .handleClose();
        }
        return false;
      },
      child: child,
    );
  }
}
