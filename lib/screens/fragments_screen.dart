import "dart:async";

import "package:flutter/material.dart";
import "package:semo/gen/assets.gen.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/screens/favorites_screen.dart";
import "package:semo/models/fragment_screen.dart";
import "package:semo/screens/movies_screen.dart";
import "package:semo/screens/search_screen.dart";
import "package:semo/screens/settings_screen.dart";
import "package:semo/screens/tv_shows_screen.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/utils/navigation_helper.dart";

class FragmentsScreen extends BaseScreen {
  const FragmentsScreen({
    super.key,
    this.initialPageIndex = 0,
    this.initialFavoritesTabIndex = 0,
  }) : super(shouldLogScreenView: false);

  final int initialPageIndex;
  final int initialFavoritesTabIndex;

  @override
  BaseScreenState<FragmentsScreen> createState() => _FragmentsScreenState();
}

class _FragmentsScreenState extends BaseScreenState<FragmentsScreen> with TickerProviderStateMixin {
  static const double _drawerBreakpoint = 900;
  int _selectedPageIndex = 0;
  List<FragmentScreen> _fragmentScreens = <FragmentScreen>[];
  late TabController _tabController;

  void _initFragments() {
    setState(() {
      _fragmentScreens = <FragmentScreen>[
        const FragmentScreen(
          icon: Icons.movie,
          title: "Movies",
          widget: MoviesScreen(),
          mediaType: MediaType.movies,
        ),
        const FragmentScreen(
          icon: Icons.video_library,
          title: "TV Shows",
          widget: TvShowsScreen(),
          mediaType: MediaType.tvShows,
        ),
        FragmentScreen(
          icon: Icons.favorite,
          title: "Favorites",
          widget: TabBarView(
            controller: _tabController,
            children: const <Widget>[
              FavoritesScreen(mediaType: MediaType.movies),
              FavoritesScreen(mediaType: MediaType.tvShows),
            ],
          ),
        ),
        const FragmentScreen(
          icon: Icons.settings,
          title: "Settings",
          widget: SettingsScreen(),
        ),
      ];
    });
  }

  Widget _buildNavigationTile(int index) => Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 18,
        ),
        child: ListTile(
          iconColor: Colors.white,
          selectedColor: Theme.of(context).primaryColor,
          selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          titleTextStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: _selectedPageIndex == index ? FontWeight.w900 : FontWeight.normal,
              ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          selected: _selectedPageIndex == index,
          leading: Icon(_fragmentScreens[index].icon),
          title: Container(
            padding: _selectedPageIndex == index ? const EdgeInsets.symmetric(vertical: 16) : EdgeInsets.zero,
            child: Text(_fragmentScreens[index].title),
          ),
          onTap: () {
            setState(() => _selectedPageIndex = index);
            Navigator.pop(context);
          },
        ),
      );

  Widget _buildBottomAppBarItem(int index) {
    final FragmentScreen fragment = _fragmentScreens[index];
    final bool isSelected = _selectedPageIndex == index;
    final Color activeColor = Theme.of(context).primaryColor;
    final Color inactiveColor = Colors.white54.withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: IconButton(
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          child: Icon(
            fragment.icon,
            size: isSelected ? 30 : 24,
            color: isSelected ? activeColor : inactiveColor,
          ),
        ),
        onPressed: () {
          setState(() => _selectedPageIndex = index);
        },
      ),
    );
  }

  Widget _buildBottomAppBar() => BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: kBottomNavigationBarHeight,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    for (int i = 0; i < _fragmentScreens.length; i++) _buildBottomAppBarItem(i),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDrawer() => SafeArea(
        top: true,
        left: true,
        right: true,
        bottom: false,
        child: Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              SizedBox(
                height: 200,
                child: Center(
                  child: Assets.images.appIcon.image(
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Divider(color: Theme.of(context).cardColor),
              ),
              SafeArea(
                child: Column(
                  children: <Widget>[
                    for (final (int index, _) in _fragmentScreens.indexed) _buildNavigationTile(index),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  @override
  String get screenName => "Fragments";

  @override
  Future<void> initializeScreen() async {
    _selectedPageIndex = widget.initialPageIndex;
    _tabController = TabController(
      length: 2,
      initialIndex: widget.initialFavoritesTabIndex,
      vsync: this,
    );
    _initFragments();
  }

  @override
  Widget buildContent(BuildContext context) {
    if (_fragmentScreens.isEmpty) {
      return const Scaffold();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useDrawer = constraints.maxWidth >= _drawerBreakpoint;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: useDrawer,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text(_fragmentScreens[_selectedPageIndex].title),
            leading: useDrawer
                ? Builder(
                    builder: (BuildContext context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  )
                : null,
            bottom: _selectedPageIndex == 2
                ? TabBar(
                    controller: _tabController,
                    tabs: const <Tab>[
                      Tab(
                        icon: Icon(Icons.movie),
                        text: "Movies",
                      ),
                      Tab(
                        icon: Icon(Icons.video_library),
                        text: "TV Shows",
                      ),
                    ],
                  )
                : null,
            actions: <Widget>[
              if (useDrawer && isConnectedToInternet && _selectedPageIndex <= 1)
                IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    NavigationHelper.navigate(
                      context,
                      SearchScreen(mediaType: _fragmentScreens[_selectedPageIndex].mediaType),
                    );
                  },
                ),
            ],
          ),
          body: _fragmentScreens[_selectedPageIndex].widget,
          drawer: useDrawer ? _buildDrawer() : null,
          bottomNavigationBar: useDrawer ? null : _buildBottomAppBar(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: (!useDrawer && isConnectedToInternet && _selectedPageIndex <= 1)
              ? FloatingActionButton(
                  onPressed: () {
                    NavigationHelper.navigate(
                      context,
                      SearchScreen(mediaType: _fragmentScreens[_selectedPageIndex].mediaType),
                    );
                  },
                  shape: const CircleBorder(),
                  child: const Icon(Icons.search),
                )
              : null,
        );
      },
    );
  }
}
