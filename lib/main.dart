// drift InsertMode not used here; rely on default insert behavior
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:lekec/database/drift_database.dart';
import 'ui/screens/developer_settings.dart';
import 'ui/screens/meds.dart';
import 'ui/screens/meds_history.dart';
import 'features/core/providers/database_provider.dart';
import 'features/core/providers/theme_provider.dart';

import 'ui/theme/app_theme.dart';

late final AppDatabase db;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  db = AppDatabase();
  await testInsert(db);

  // Override the provider so the whole app uses the same 'db' instance
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
    ], 
    child: const MyApp(),
  ));
}

Future<void> testInsert(AppDatabase db) async {
  try {
    // Use the generated companion constructor for required fields.
    // For tables with `autoIncrement()` integer id columns, the
    // `insert` call will return the generated id (int).
    final insertedId = await db.into(db.users).insert(
      UsersCompanion.insert(
        name: 'Test User',
      ),
    );

    print('Inserted user id: $insertedId');

    final allUsers = await db.select(db.users).get();
    print('All users: $allUsers');
  } catch (e, st) {
    print('Error inserting user: $e');
    print(st);
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Branch 1: Zdravila (Meds)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/meds',
              builder: (context, state) => const MedsScreen(),
            ),
          ],
        ),
        // Branch 2: Tekoči pregled (Home)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const MyHomePage(title: 'Lekec'),
            ),
          ],
        ),
        // Branch 3: Zgodovina (History)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const MedsHistoryScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/dev',
      builder: (context, state) => const DeveloperSettingsScreen(),
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) => _onTap(context, index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Symbols.pill),
            label: 'Zdravila',
          ),
          NavigationDestination(
            icon: Icon(Symbols.home),
            label: 'Tekoči pregled',
          ),
          NavigationDestination(
            icon: Icon(Symbols.manage_search),
            label: 'Zgodovina',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}


class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Lekec',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode.value ?? ThemeMode.system,
      routerConfig: _router,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
    testInsert(db);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint" 
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
