# AI Agent Flutter Development Guidelines

## Document Purpose and Scope

This document establishes comprehensive, mandatory standards and best practices that ALL AI agents must follow when working on ANY Flutter project. Flutter is Google's UI toolkit for building natively compiled applications for mobile, web, desktop, and embedded devices from a single codebase.

This document focuses specifically on **mobile (iOS and Android)** and **desktop (Windows, macOS, Linux)** applications built with Flutter. It applies to both Dart and Flutter development.

This document **complements** the main AI Agent Development Guidelines (ai-agents.md), Backend Development Guidelines (ai-agents-backend.md), and Frontend Development Guidelines (ai-agents-frontend.md), focusing specifically on Flutter mobile and desktop concerns.

**These are NON-NEGOTIABLE rules for Flutter development excellence.**

---

## 1. Flutter Architecture Principles

### 1.1 Project Structure

**Standard Flutter Project Structure**:
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   ├── errors/
│   └── network/
├── features/
│   ├── authentication/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── datasources/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── widgets/
│   │       └── bloc/
│   └── [other features]/
├── shared/
│   ├── widgets/
│   ├── models/
│   └── utils/
└── config/
    ├── routes/
    ├── themes/
    └── dependencies/
```

**Project Organization Rules**:
- Organize by feature, not by type
- Keep related code together
- Separate presentation, domain, and data layers
- Use clear, descriptive folder names
- Maintain consistent structure across features
- Keep shared code in dedicated folders

### 1.2 Clean Architecture for Flutter

**Layer Separation**:
- **Presentation Layer**: UI widgets, pages, state management (BLoC, Provider, Riverpod)
- **Domain Layer**: Business logic, entities, use cases, repository interfaces
- **Data Layer**: Data sources (API, database), repository implementations, models

**Dependency Rule**:
- Dependencies point inward (presentation → domain ← data)
- Domain layer is independent (no Flutter or external dependencies)
- Data layer implements domain interfaces
- Presentation layer depends on domain abstractions

**Benefits**:
- Testable business logic
- Independent of frameworks
- Independent of UI
- Independent of database
- Easy to maintain and extend

### 1.3 Feature-First Organization

**Feature Structure**:
```
feature_name/
├── data/
│   ├── models/          # Data models (JSON serialization)
│   ├── datasources/     # API clients, local storage
│   └── repositories/    # Repository implementations
├── domain/
│   ├── entities/        # Business objects
│   ├── repositories/    # Repository interfaces
│   └── usecases/        # Business logic
└── presentation/
    ├── pages/           # Full screen widgets
    ├── widgets/         # Reusable UI components
    └── state/           # State management (BLoC, Provider, etc.)
```

**Rules**:
- Each feature is self-contained
- Features can be developed independently
- Features should not directly depend on other features
- Use dependency injection for feature communication
- Keep features cohesive and focused

---

## 2. Widget Architecture and Best Practices

### 2.1 Widget Composition

**Widget Design Principles**:
- **Single Responsibility**: Each widget should do ONE thing
- **Composition over Inheritance**: Build complex widgets from simple ones
- **Immutability**: Widgets should be immutable (@immutable annotation)
- **Stateless by Default**: Use StatelessWidget unless state is needed
- **Small Widgets**: Keep widgets focused and small (< 200 lines)

**Widget Types**:
- **StatelessWidget**: For widgets that don't change
- **StatefulWidget**: For widgets with mutable state
- **InheritedWidget**: For passing data down the tree
- **Custom Painters**: For custom graphics
- **Slivers**: For custom scrollable areas

### 2.2 StatelessWidget Best Practices

**When to Use StatelessWidget**:
- Widget doesn't manage any state
- Widget only displays data passed via constructor
- Widget's appearance doesn't change over time
- Widget is purely presentational

**Example**:
```dart
@immutable
class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.user,
    this.onTap,
  });

  final User user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(user.name),
        subtitle: Text(user.email),
        onTap: onTap,
      ),
    );
  }
}
```

### 2.3 StatefulWidget Best Practices

**State Management in StatefulWidget**:
- Keep state as local as possible
- Initialize state in `initState()`
- Clean up resources in `dispose()`
- Use `setState()` only for UI state
- Don't perform heavy operations in `setState()`
- Use lifecycle methods appropriately

**Lifecycle Methods**:
- `initState()`: Initialize state, subscribe to streams
- `didChangeDependencies()`: Called when InheritedWidget changes
- `didUpdateWidget()`: Called when widget configuration changes
- `dispose()`: Clean up controllers, subscriptions, listeners

**Example**:
```dart
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $_counter'),
        ElevatedButton(
          onPressed: _incrementCounter,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

### 2.4 Widget Optimization

**Performance Best Practices**:
- Use `const` constructors whenever possible
- Extract static widgets into separate const widgets
- Use `RepaintBoundary` for expensive widgets
- Avoid rebuilding entire trees (use Builder, Consumer, etc.)
- Use `ListView.builder` for long lists
- Implement `shouldRepaint` for CustomPainter
- Use `AutomaticKeepAliveClientMixin` for expensive-to-build widgets

**Const Widgets**:
```dart
// Good: Uses const constructor
const Text('Hello');
const Icon(Icons.home);
const Padding(padding: EdgeInsets.all(8.0));

// Bad: Non-const when could be const
Text('Hello');
Icon(Icons.home);
```

### 2.5 Widget Keys

**When to Use Keys**:
- Preserving state when widgets move in the list
- Controlling widget identity
- Accessing widget state from parent
- Testing widgets

**Key Types**:
- **ValueKey**: Based on a value (id, name)
- **ObjectKey**: Based on object identity
- **UniqueKey**: Always unique (creates new key each time)
- **GlobalKey**: Access widget state from anywhere (use sparingly)
- **PageStorageKey**: Preserve scroll position

**Example**:
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      key: ValueKey(items[index].id), // Preserve identity
      title: Text(items[index].name),
    );
  },
)
```

---

## 3. State Management

### 3.1 Choosing State Management Solution

**State Management Options**:
- **setState**: Local widget state (simple apps)
- **InheritedWidget/InheritedModel**: Pass data down the tree
- **Provider**: Simple dependency injection and state management
- **Riverpod**: Compile-safe Provider with better syntax
- **BLoC/Cubit**: Business Logic Component pattern
- **GetX**: All-in-one solution (state, routing, dependencies)
- **MobX**: Reactive state management
- **Redux**: Predictable state container

**Selection Criteria**:
- App complexity and scale
- Team familiarity
- Testing requirements
- Performance needs
- Learning curve
- Community support

### 3.2 Provider Pattern

**Provider Best Practices**:
- Use `ChangeNotifier` for mutable state
- Call `notifyListeners()` after state changes
- Dispose providers properly
- Use `Consumer` or `Selector` for rebuilds
- Use `context.read()` for actions
- Use `context.watch()` for reactive data
- Avoid putting everything in one provider

**Example**:
```dart
class CounterProvider extends ChangeNotifier {
  int _count = 0;
  
  int get count => _count;
  
  void increment() {
    _count++;
    notifyListeners();
  }
  
  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}

// In main.dart
ChangeNotifierProvider(
  create: (_) => CounterProvider(),
  child: MyApp(),
)

// In widget
Consumer<CounterProvider>(
  builder: (context, counter, child) {
    return Text('${counter.count}');
  },
)
```

### 3.3 BLoC Pattern

**BLoC Principles**:
- Business Logic Component
- Separate UI from business logic
- Use streams for data flow
- Testable business logic
- Reusable across platforms

**BLoC Best Practices**:
- One BLoC per feature (or sub-feature)
- BLoC doesn't know about widgets
- Use events for inputs
- Use states for outputs
- Close streams in `close()` method
- Use `BlocProvider` for dependency injection
- Use `BlocBuilder` or `BlocConsumer` for UI updates

**Example**:
```dart
// Events
abstract class CounterEvent {}
class IncrementEvent extends CounterEvent {}
class DecrementEvent extends CounterEvent {}

// States
abstract class CounterState {
  final int count;
  const CounterState(this.count);
}
class CounterInitial extends CounterState {
  const CounterInitial() : super(0);
}
class CounterUpdated extends CounterState {
  const CounterUpdated(super.count);
}

// BLoC
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterInitial()) {
    on<IncrementEvent>((event, emit) {
      emit(CounterUpdated(state.count + 1));
    });
    on<DecrementEvent>((event, emit) {
      emit(CounterUpdated(state.count - 1));
    });
  }
}

// Usage
BlocBuilder<CounterBloc, CounterState>(
  builder: (context, state) {
    return Text('Count: ${state.count}');
  },
)
```

### 3.4 Riverpod Pattern

**Riverpod Advantages**:
- Compile-time safety
- No BuildContext required
- Better testing support
- No provider nesting issues
- Simpler syntax

**Example**:
```dart
// Provider definition
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  
  void increment() => state++;
  void decrement() => state--;
}

// Usage in widget
class CounterWidget extends ConsumerWidget {
  const CounterWidget({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    
    return Column(
      children: [
        Text('Count: $count'),
        ElevatedButton(
          onPressed: () => ref.read(counterProvider.notifier).increment(),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

### 3.5 State Management Best Practices

**General Rules**:
- Keep state as local as possible
- Lift state only when necessary
- Don't store derived state
- Immutable state updates
- Single source of truth
- Predictable state changes
- Proper cleanup in dispose
- Test state logic separately from UI

---

## 4. Navigation and Routing

### 4.1 Navigator 1.0 vs 2.0

**Navigator 1.0 (Imperative)**:
- Simple push/pop navigation
- Good for simple apps
- Less control over navigation stack
- URL-based routing more complex

**Navigator 2.0 (Declarative)**:
- Full control over navigation stack
- Better deep linking support
- More complex to set up
- Better for web and complex apps

### 4.2 Named Routes

**Route Definition**:
```dart
MaterialApp(
  routes: {
    '/': (context) => HomePage(),
    '/profile': (context) => ProfilePage(),
    '/settings': (context) => SettingsPage(),
  },
  onGenerateRoute: (settings) {
    // Handle dynamic routes
    if (settings.name == '/user') {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => UserPage(userId: args['id']),
      );
    }
    return null;
  },
)
```

**Navigation**:
```dart
// Navigate to named route
Navigator.pushNamed(context, '/profile');

// Navigate with arguments
Navigator.pushNamed(
  context,
  '/user',
  arguments: {'id': '123'},
);

// Replace current route
Navigator.pushReplacementNamed(context, '/home');

// Pop until route
Navigator.popUntil(context, ModalRoute.withName('/home'));
```

### 4.3 GoRouter (Recommended)

**Why GoRouter**:
- Declarative routing
- Type-safe navigation
- Deep linking support
- Web-friendly URLs
- Nested navigation
- Redirect handling
- Route guards

**Example**:
```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: 'user/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return UserPage(userId: id);
          },
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    // Route guards
    final isAuthenticated = /* check auth */;
    if (!isAuthenticated && state.location != '/login') {
      return '/login';
    }
    return null;
  },
);

// Usage
MaterialApp.router(
  routerConfig: router,
)

// Navigate
context.go('/profile');
context.push('/user/123');
```

### 4.4 Navigation Best Practices

**Rules**:
- Use named routes for maintainability
- Implement proper route guards
- Handle deep links properly
- Support Android back button
- Handle navigation errors gracefully
- Test navigation flows
- Document route parameters
- Use type-safe navigation when possible

---

## 5. Platform-Specific Development

### 5.1 Platform Detection

**Detecting Platform**:
```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  // Web-specific code
} else if (Platform.isAndroid) {
  // Android-specific code
} else if (Platform.isIOS) {
  // iOS-specific code
} else if (Platform.isMacOS) {
  // macOS-specific code
} else if (Platform.isWindows) {
  // Windows-specific code
} else if (Platform.isLinux) {
  // Linux-specific code
}
```

**Theme Detection**:
```dart
final theme = Theme.of(context);
final platform = theme.platform;

if (platform == TargetPlatform.iOS) {
  // iOS-specific styling
} else if (platform == TargetPlatform.android) {
  // Android-specific styling
}
```

### 5.2 Mobile-Specific Considerations

**Android**:
- Material Design guidelines
- Handle back button properly
- Request runtime permissions (camera, location, etc.)
- Handle app lifecycle properly
- Support different screen sizes and densities
- Test on multiple Android versions
- Handle keyboard properly
- Support dark mode

**iOS**:
- Human Interface Guidelines
- Cupertino widgets for native look
- Handle safe areas properly (notch, home indicator)
- Request permissions with proper descriptions
- Support Face ID/Touch ID
- Handle app lifecycle properly
- Test on different iOS versions and devices
- Support dark mode

**Permission Handling**:
```dart
// Add to pubspec.yaml: permission_handler

final status = await Permission.camera.request();
if (status.isGranted) {
  // Permission granted
} else if (status.isDenied) {
  // Permission denied
} else if (status.isPermanentlyDenied) {
  // Open app settings
  openAppSettings();
}
```

### 5.3 Desktop-Specific Considerations

**Windows**:
- Native Windows UI patterns
- Window management (minimize, maximize, close)
- System tray integration
- File system access
- Keyboard shortcuts
- High DPI support
- Multi-window support

**macOS**:
- Native macOS UI patterns
- Menu bar integration
- Dock integration
- File system access
- Keyboard shortcuts
- Support dark mode
- Multi-window support

**Linux**:
- Support different distributions
- File system access
- Keyboard shortcuts
- Window management
- Integration with desktop environments

**Desktop Best Practices**:
```dart
// Window management (using window_manager package)
await windowManager.setTitle('My App');
await windowManager.setMinimumSize(const Size(800, 600));
await windowManager.center();

// Desktop-optimized layouts
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 1200) {
      return DesktopLayout();
    } else if (constraints.maxWidth > 600) {
      return TabletLayout();
    } else {
      return MobileLayout();
    }
  },
)
```

### 5.4 Responsive Design for Multiple Platforms

**Adaptive Layouts**:
```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200 && desktop != null) {
          return desktop!;
        } else if (constraints.maxWidth >= 600 && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}
```

**Platform-Adaptive Widgets**:
```dart
// Use platform-appropriate widgets
Widget buildButton() {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return CupertinoButton(
      onPressed: onPressed,
      child: const Text('Button'),
    );
  }
  return ElevatedButton(
    onPressed: onPressed,
    child: const Text('Button'),
  );
}

// Or use adaptive widgets
PlatformMenuBar( // Auto-adapts to platform
  menus: [...],
)
```

---

## 6. UI/UX Design and Theming

### 6.1 Material Design vs Cupertino

**Material Design (Android)**:
- Use Material widgets
- Follow Material Design guidelines
- Implement Material Theme
- Use Material icons
- Support Material animations

**Cupertino Design (iOS)**:
- Use Cupertino widgets
- Follow iOS Human Interface Guidelines
- Implement Cupertino Theme
- Use SF Symbols or Cupertino icons
- Support iOS-style animations

**Adaptive Approach**:
```dart
// Use adaptive widgets that choose based on platform
final button = adaptive.isIOS 
  ? CupertinoButton(child: Text('Click'))
  : ElevatedButton(child: Text('Click'));

// Or use packages like flutter_platform_widgets
PlatformButton(
  onPressed: () {},
  child: Text('Click'),
)
```

### 6.2 Theme Implementation

**ThemeData Configuration**:
```dart
final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(fontSize: 16),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  ),
  // ... dark theme configuration
);

MaterialApp(
  theme: lightTheme,
  darkTheme: darkTheme,
  themeMode: ThemeMode.system, // or .light, .dark
)
```

### 6.3 Color System

**Color Best Practices**:
- Use ColorScheme for consistent colors
- Define semantic colors (primary, secondary, error, etc.)
- Support both light and dark themes
- Ensure sufficient contrast ratios
- Use Material color palette
- Define custom colors as constants

**Example**:
```dart
class AppColors {
  static const primary = Color(0xFF6200EE);
  static const primaryVariant = Color(0xFF3700B3);
  static const secondary = Color(0xFF03DAC6);
  static const secondaryVariant = Color(0xFF018786);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const error = Color(0xFFB00020);
  
  // Dark theme colors
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
}
```

### 6.4 Typography

**Text Theming**:
```dart
const textTheme = TextTheme(
  displayLarge: TextStyle(fontSize: 96, fontWeight: FontWeight.w300),
  displayMedium: TextStyle(fontSize: 60, fontWeight: FontWeight.w400),
  displaySmall: TextStyle(fontSize: 48, fontWeight: FontWeight.w400),
  headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w400),
  headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
  headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
  titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
  titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
  bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
  labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
);

// Usage
Text(
  'Title',
  style: Theme.of(context).textTheme.headlineMedium,
)
```

### 6.5 Spacing and Layout

**Spacing Constants**:
```dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

// Usage
Padding(
  padding: const EdgeInsets.all(AppSpacing.md),
  child: Column(
    spacing: AppSpacing.sm,
    children: [...],
  ),
)
```

---

## 7. Performance Optimization

### 7.1 Build Performance

**Widget Rebuilding Optimization**:
- Use `const` constructors everywhere possible
- Break down large widgets into smaller ones
- Use `RepaintBoundary` for expensive widgets
- Avoid expensive operations in `build()` method
- Cache expensive computations
- Use `ListView.builder` for long lists

**Example**:
```dart
// Bad: Rebuilds entire list on every build
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)

// Good: Only builds visible items
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// Better: Uses const constructor
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => const ItemWidget(key: ValueKey(...)),
)
```

### 7.2 Image Optimization

**Image Best Practices**:
- Use appropriate image formats (WebP, PNG, JPEG)
- Resize images to display size
- Use `CachedNetworkImage` for network images
- Implement lazy loading
- Use `Image.asset` for local images
- Provide placeholder while loading
- Handle image errors gracefully

**Example**:
```dart
// For network images
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  fit: BoxFit.cover,
  width: 200,
  height: 200,
)

// For optimized loading
FadeInImage.assetNetwork(
  placeholder: 'assets/placeholder.png',
  image: networkImageUrl,
)
```

### 7.3 List Performance

**ListView Optimization**:
```dart
// Use builder for long lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemTile(items[index]),
)

// Use separated builder for dividers
ListView.separated(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemTile(items[index]),
  separatorBuilder: (context, index) => const Divider(),
)

// For grid layouts
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
  ),
  itemCount: items.length,
  itemBuilder: (context, index) => ItemCard(items[index]),
)
```

### 7.4 Memory Management

**Memory Best Practices**:
- Dispose controllers and listeners in `dispose()`
- Cancel stream subscriptions
- Remove event listeners
- Clear large data structures
- Use `WeakReference` for caching
- Monitor memory usage with DevTools
- Avoid memory leaks in state management

**Example**:
```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final StreamSubscription _subscription;
  late final TextEditingController _controller;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _animController = AnimationController(vsync: this);
    _subscription = stream.listen((_) {});
  }

  @override
  void dispose() {
    _subscription.cancel();
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container();
}
```

### 7.5 Animation Performance

**Efficient Animations**:
- Use `AnimatedBuilder` for complex animations
- Use built-in animated widgets (AnimatedContainer, AnimatedOpacity)
- Avoid rebuilding entire tree during animations
- Use `RepaintBoundary` for animated widgets
- Target 60fps (16ms per frame)
- Use `AnimatedWidget` for custom animations

**Example**:
```dart
// Good: Only rebuilds animated widget
AnimatedBuilder(
  animation: animation,
  builder: (context, child) {
    return Transform.rotate(
      angle: animation.value,
      child: child,
    );
  },
  child: const ExpensiveWidget(), // Built once
)

// Built-in animated widgets
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  width: _expanded ? 200 : 100,
  height: _expanded ? 200 : 100,
)
```

---

## 8. Data Persistence

### 8.1 Local Storage Options

**Storage Solutions**:
- **SharedPreferences**: Simple key-value storage (user preferences)
- **Hive**: Lightweight, fast NoSQL database
- **Sqflite**: SQLite database for relational data
- **ObjectBox**: High-performance NoSQL database
- **Drift (Moor)**: Reactive SQLite wrapper with type safety
- **Isar**: Fast NoSQL database
- **Secure Storage**: For sensitive data (flutter_secure_storage)

### 8.2 SharedPreferences

**Usage**:
```dart
// Save data
final prefs = await SharedPreferences.getInstance();
await prefs.setString('username', 'john_doe');
await prefs.setInt('counter', 42);
await prefs.setBool('isDarkMode', true);

// Read data
final username = prefs.getString('username');
final counter = prefs.getInt('counter') ?? 0;
final isDarkMode = prefs.getBool('isDarkMode') ?? false;

// Remove data
await prefs.remove('username');
await prefs.clear(); // Remove all
```

**Best Practices**:
- Use for simple key-value data only
- Don't store large amounts of data
- Don't store sensitive information
- Use constants for keys
- Provide default values when reading

### 8.3 Hive Database

**Setup and Usage**:
```dart
// Initialize Hive
await Hive.initFlutter();

// Register adapters for custom types
Hive.registerAdapter(UserAdapter());

// Open box
final box = await Hive.openBox<User>('users');

// Write data
await box.put('user1', user);
await box.add(user); // Auto-generated key

// Read data
final user = box.get('user1');
final allUsers = box.values.toList();

// Delete data
await box.delete('user1');
await box.clear();

// Listen to changes
box.watch().listen((event) {
  print('Key: ${event.key}, Value: ${event.value}');
});

// Close box
await box.close();
```

### 8.4 SQLite with Sqflite

**Setup and Usage**:
```dart
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;
  
  DatabaseHelper._();
  
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'app_database.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE
          )
        ''');
      },
    );
  }
  
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }
  
  Future<List<User>> getUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }
  
  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
  
  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

### 8.5 Secure Storage

**For Sensitive Data**:
```dart
// flutter_secure_storage
final storage = FlutterSecureStorage();

// Write
await storage.write(key: 'auth_token', value: token);
await storage.write(key: 'api_key', value: apiKey);

// Read
final token = await storage.read(key: 'auth_token');

// Delete
await storage.delete(key: 'auth_token');
await storage.deleteAll();
```

**Best Practices**:
- Use for passwords, tokens, API keys
- Don't store large amounts of data
- Handle platform-specific limitations
- Test secure storage on all platforms
- Provide fallback for platforms without secure storage

---

## 9. Networking and API Integration

### 9.1 HTTP Requests

**Using http Package**:
```dart
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'https://api.example.com';
  
  Future<User> getUser(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }
  
  Future<User> createUser(User user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(user.toJson()),
    );
    
    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create user');
    }
  }
}
```

### 9.2 Dio HTTP Client (Recommended)

**Why Dio**:
- Interceptors
- Request cancellation
- File upload/download with progress
- Timeout configuration
- Better error handling
- FormData support
- HTTP/2 support

**Setup**:
```dart
class DioClient {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );
  
  DioClient() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token
          options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response
          print('Response: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          // Handle errors
          print('Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }
  
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<T> post<T>(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout');
      case DioExceptionType.badResponse:
        return ServerException('Server error: ${error.response?.statusCode}');
      case DioExceptionType.cancel:
        return RequestCancelledException();
      default:
        return NetworkException('Network error');
    }
  }
}
```

### 9.3 REST API Integration

**Repository Pattern**:
```dart
abstract class UserRepository {
  Future<User> getUser(String id);
  Future<List<User>> getUsers();
  Future<User> createUser(User user);
  Future<User> updateUser(User user);
  Future<void> deleteUser(String id);
}

class UserRepositoryImpl implements UserRepository {
  final DioClient _client;
  
  UserRepositoryImpl(this._client);
  
  @override
  Future<User> getUser(String id) async {
    final data = await _client.get<Map<String, dynamic>>('/users/$id');
    return User.fromJson(data);
  }
  
  @override
  Future<List<User>> getUsers() async {
    final data = await _client.get<List<dynamic>>('/users');
    return data.map((json) => User.fromJson(json)).toList();
  }
  
  // ... other methods
}
```

### 9.4 GraphQL Integration

**Using graphql_flutter**:
```dart
final HttpLink httpLink = HttpLink('https://api.example.com/graphql');

final AuthLink authLink = AuthLink(
  getToken: () async => 'Bearer $token',
);

final Link link = authLink.concat(httpLink);

final client = GraphQLClient(
  cache: GraphQLCache(),
  link: link,
);

// Query
const String getUserQuery = '''
  query GetUser(\$id: ID!) {
    user(id: \$id) {
      id
      name
      email
    }
  }
''';

final result = await client.query(
  QueryOptions(
    document: gql(getUserQuery),
    variables: {'id': userId},
  ),
);

if (result.hasException) {
  throw result.exception!;
}

final user = User.fromJson(result.data!['user']);

// Mutation
const String createUserMutation = '''
  mutation CreateUser(\$input: UserInput!) {
    createUser(input: \$input) {
      id
      name
      email
    }
  }
''';

final result = await client.mutate(
  MutationOptions(
    document: gql(createUserMutation),
    variables: {
      'input': {
        'name': 'John Doe',
        'email': 'john@example.com',
      }
    },
  ),
);
```

### 9.5 Error Handling

**Custom Exceptions**:
```dart
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  ServerException(this.message, [this.statusCode]);
  
  @override
  String toString() => '$message (Status: $statusCode)';
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}
```

**Error Handling Pattern**:
```dart
class Result<T> {
  final T? data;
  final Exception? error;
  
  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
  
  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}

// Usage
Future<Result<User>> getUser(String id) async {
  try {
    final user = await _apiService.getUser(id);
    return Result.success(user);
  } on NetworkException catch (e) {
    return Result.failure(e);
  } on ServerException catch (e) {
    return Result.failure(e);
  } catch (e) {
    return Result.failure(Exception('Unknown error: $e'));
  }
}
```

---

## 10. Testing

### 10.1 Unit Testing

**Testing Business Logic**:
```dart
// test/domain/usecases/get_user_test.dart
void main() {
  late GetUserUseCase useCase;
  late MockUserRepository mockRepository;
  
  setUp(() {
    mockRepository = MockUserRepository();
    useCase = GetUserUseCase(mockRepository);
  });
  
  test('should get user from repository', () async {
    // Arrange
    const userId = '123';
    final expectedUser = User(id: userId, name: 'John');
    when(() => mockRepository.getUser(userId))
        .thenAnswer((_) async => expectedUser);
    
    // Act
    final result = await useCase(userId);
    
    // Assert
    expect(result, expectedUser);
    verify(() => mockRepository.getUser(userId)).called(1);
  });
  
  test('should throw exception when repository fails', () async {
    // Arrange
    const userId = '123';
    when(() => mockRepository.getUser(userId))
        .thenThrow(ServerException('Server error'));
    
    // Act & Assert
    expect(
      () => useCase(userId),
      throwsA(isA<ServerException>()),
    );
  });
}
```

### 10.2 Widget Testing

**Testing Widgets**:
```dart
void main() {
  testWidgets('Counter increments', (WidgetTester tester) async {
    // Build widget
    await tester.pumpWidget(
      const MaterialApp(
        home: CounterPage(),
      ),
    );
    
    // Verify initial state
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    
    // Tap increment button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    
    // Verify counter incremented
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
  
  testWidgets('Shows error message on failure', (tester) async {
    // Setup mock
    when(() => mockBloc.state).thenReturn(ErrorState('Error'));
    
    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<CounterBloc>.value(
          value: mockBloc,
          child: const CounterPage(),
        ),
      ),
    );
    
    // Verify error message shown
    expect(find.text('Error'), findsOneWidget);
  });
}
```

### 10.3 Integration Testing

**Testing User Flows**:
```dart
// integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Complete user flow', (tester) async {
    // Launch app
    app.main();
    await tester.pumpAndSettle();
    
    // Login
    await tester.enterText(find.byKey(Key('email')), 'user@test.com');
    await tester.enterText(find.byKey(Key('password')), 'password');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    
    // Verify home page
    expect(find.text('Home'), findsOneWidget);
    
    // Navigate to profile
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    
    // Verify profile page
    expect(find.text('Profile'), findsOneWidget);
  });
}
```

### 10.4 Golden Tests (Visual Regression)

**Testing Widget Appearance**:
```dart
void main() {
  testWidgets('UserCard golden test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserCard(
            user: User(name: 'John Doe', email: 'john@test.com'),
          ),
        ),
      ),
    );
    
    await expectLater(
      find.byType(UserCard),
      matchesGoldenFile('goldens/user_card.png'),
    );
  });
  
  testWidgets('UserCard dark mode golden test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: UserCard(
            user: User(name: 'John Doe', email: 'john@test.com'),
          ),
        ),
      ),
    );
    
    await expectLater(
      find.byType(UserCard),
      matchesGoldenFile('goldens/user_card_dark.png'),
    );
  });
}
```

### 10.5 Testing Best Practices

**Rules**:
- Test business logic thoroughly (unit tests)
- Test user interactions (widget tests)
- Test critical user flows (integration tests)
- Use mocks for external dependencies
- Keep tests fast and isolated
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)
- Test edge cases and error conditions
- Maintain test coverage > 80%
- Run tests in CI/CD

---

## 11. Accessibility

### 11.1 Semantic Widgets

**Accessibility Labels**:
```dart
// Add semantic labels
Semantics(
  label: 'Home button',
  button: true,
  child: IconButton(
    icon: const Icon(Icons.home),
    onPressed: () {},
  ),
)

// Exclude from semantics
ExcludeSemantics(
  child: DecorativeImage(),
)

// Merge semantics
MergeSemantics(
  child: Row(
    children: [
      Icon(Icons.star),
      Text('5.0 rating'),
    ],
  ),
)
```

### 11.2 Screen Reader Support

**Best Practices**:
- Provide meaningful labels for all interactive elements
- Use Semantics widget for custom widgets
- Test with TalkBack (Android) and VoiceOver (iOS)
- Ensure logical reading order
- Provide hints for complex interactions
- Announce dynamic content changes

**Example**:
```dart
Semantics(
  label: 'Favorite button',
  hint: 'Double tap to add to favorites',
  button: true,
  onTap: () {
    // Action
  },
  child: IconButton(
    icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
    onPressed: toggleFavorite,
  ),
)
```

### 11.3 Keyboard Navigation (Desktop)

**Focus Management**:
```dart
class MyForm extends StatefulWidget {
  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  late final FocusNode _emailFocus;
  late final FocusNode _passwordFocus;
  
  @override
  void initState() {
    super.initState();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();
  }
  
  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          focusNode: _emailFocus,
          onSubmitted: (_) {
            _passwordFocus.requestFocus();
          },
        ),
        TextField(
          focusNode: _passwordFocus,
          onSubmitted: (_) {
            _submitForm();
          },
        ),
      ],
    );
  }
}
```

### 11.4 Color Contrast

**Ensuring Accessibility**:
```dart
// Check contrast ratios
// Normal text: 4.5:1 minimum
// Large text (18pt+): 3:1 minimum

// Use sufficient contrast
const textColor = Colors.black87;
const backgroundColor = Colors.white;

// Avoid color-only indicators
Row(
  children: [
    Icon(Icons.error, color: Colors.red),
    Text('Error occurred'), // Text provides additional context
  ],
)
```

### 11.5 Text Scaling

**Support Dynamic Text Sizing**:
```dart
// Respect system text scaling
Text(
  'Hello',
  style: Theme.of(context).textTheme.bodyLarge,
)

// Limit maximum scale factor if needed
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(1.0, 2.0),
  ),
  child: child,
)

// Test with different text scales
// iOS: Settings > Accessibility > Display & Text Size > Larger Text
// Android: Settings > Display > Font size
```

---

## 12. Localization and Internationalization

### 12.1 Setup

**Add Dependencies**:
```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

**Configuration**:
```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### 12.2 ARB Files

**English (app_en.arb)**:
```json
{
  "@@locale": "en",
  "appTitle": "My App",
  "welcomeMessage": "Welcome {userName}!",
  "@welcomeMessage": {
    "description": "Welcome message with user name",
    "placeholders": {
      "userName": {
        "type": "String",
        "example": "John"
      }
    }
  },
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "description": "Number of items",
    "placeholders": {
      "count": {
        "type": "int",
        "format": "compact"
      }
    }
  }
}
```

**French (app_fr.arb)**:
```json
{
  "@@locale": "fr",
  "appTitle": "Mon Application",
  "welcomeMessage": "Bienvenue {userName}!",
  "itemCount": "{count, plural, =0{Aucun élément} =1{1 élément} other{{count} éléments}}"
}
```

### 12.3 Usage

**In App**:
```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('fr'),
    Locale('es'),
  ],
  home: MyHomePage(),
)

// In widgets
final l10n = AppLocalizations.of(context)!;
Text(l10n.appTitle)
Text(l10n.welcomeMessage('John'))
Text(l10n.itemCount(5))
```

### 12.4 Date and Number Formatting

**Formatting**:
```dart
import 'package:intl/intl.dart';

// Date formatting
final formatter = DateFormat.yMMMd(Localizations.localeOf(context).languageCode);
final formattedDate = formatter.format(DateTime.now());

// Number formatting
final numberFormatter = NumberFormat.currency(
  locale: Localizations.localeOf(context).languageCode,
  symbol: '\$',
);
final formattedPrice = numberFormatter.format(19.99);

// Compact numbers
final compactFormatter = NumberFormat.compact(
  locale: Localizations.localeOf(context).languageCode,
);
final compactNumber = compactFormatter.format(1500); // "1.5K"
```

### 12.5 RTL Support

**Right-to-Left Languages**:
```dart
// Flutter automatically handles RTL for Arabic, Hebrew, etc.
MaterialApp(
  supportedLocales: const [
    Locale('en'),
    Locale('ar'), // Arabic (RTL)
    Locale('he'), // Hebrew (RTL)
  ],
)

// Directional widgets
Directionality(
  textDirection: TextDirection.rtl,
  child: child,
)

// Directional padding
EdgeInsetsDirectional.only(
  start: 16.0, // Left in LTR, right in RTL
  end: 8.0,    // Right in LTR, left in RTL
)
```

---

## 13. Security Best Practices

### 13.1 Secure Storage

**Storing Sensitive Data**:
```dart
// Use flutter_secure_storage
final storage = FlutterSecureStorage();

// Store credentials
await storage.write(key: 'access_token', value: token);
await storage.write(key: 'refresh_token', value: refreshToken);

// Read credentials
final token = await storage.read(key: 'access_token');

// Delete credentials
await storage.delete(key: 'access_token');
```

**Best Practices**:
- Never store passwords in plain text
- Use secure storage for tokens and API keys
- Don't store sensitive data in SharedPreferences
- Implement token refresh mechanism
- Clear sensitive data on logout

### 13.2 SSL/TLS Certificate Pinning

**Certificate Pinning**:
```dart
// Using dio with certificate pinning
final dio = Dio();

dio.httpClientAdapter = IOHttpClientAdapter(
  createHttpClient: () {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) {
      // Verify certificate
      return cert.sha1.toString() == expectedSha1;
    };
    return client;
  },
);
```

### 13.3 Input Validation

**Sanitize User Input**:
```dart
class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain number';
    }
    return null;
  }
  
  static String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input
        .replaceAll(RegExp(r'[<>]'), '')
        .trim();
  }
}
```

### 13.4 Code Obfuscation

**Build with Obfuscation**:
```bash
# Build release with obfuscation
flutter build apk --obfuscate --split-debug-info=build/debug-info
flutter build ios --obfuscate --split-debug-info=build/debug-info
flutter build windows --obfuscate --split-debug-info=build/debug-info
```

**Rules**:
- Always obfuscate release builds
- Keep debug symbols for crash reporting
- Don't obfuscate in debug mode
- Store symbols securely
- Use ProGuard rules for Android

### 13.5 API Key Protection

**Environment Variables**:
```dart
// Use --dart-define for API keys
// flutter run --dart-define=API_KEY=your_key_here

class Config {
  static const apiKey = String.fromEnvironment('API_KEY');
  static const baseUrl = String.fromEnvironment('BASE_URL');
}

// Use in code
final headers = {
  'Authorization': 'Bearer ${Config.apiKey}',
};
```

**Best Practices**:
- Never commit API keys to version control
- Use environment variables or build configurations
- Use different keys for dev/staging/production
- Rotate keys regularly
- Monitor API key usage

---

## 14. Error Handling and Logging

### 14.1 Global Error Handling

**Catch All Errors**:
```dart
void main() {
  // Catch Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // Log to crash reporting service
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  
  // Catch async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    // Log to crash reporting service
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(MyApp());
}
```

### 14.2 Error Boundaries

**Custom Error Widget**:
```dart
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });
  
  @override
  Widget build(BuildContext context) {
    return ErrorWidget.builder = (details) {
      if (errorBuilder != null) {
        return errorBuilder!(details);
      }
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Something went wrong'),
              TextButton(
                onPressed: () {
                  // Restart app or navigate to home
                },
                child: const Text('Restart'),
              ),
            ],
          ),
        ),
      );
    };
  }
}
```

### 14.3 Logging

**Structured Logging**:
```dart
import 'package:logger/logger.dart';

class AppLogger {
  static final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );
  
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.d(message, error: error, stackTrace: stackTrace);
  }
  
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.i(message, error: error, stackTrace: stackTrace);
  }
  
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.w(message, error: error, stackTrace: stackTrace);
  }
  
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.e(message, error: error, stackTrace: stackTrace);
  }
}

// Usage
AppLogger.d('Debug message');
AppLogger.i('Info message');
AppLogger.w('Warning message');
AppLogger.e('Error message', error, stackTrace);
```

### 14.4 Crash Reporting

**Firebase Crashlytics**:
```dart
// Initialize
await Firebase.initializeApp();
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

// Log custom errors
try {
  await riskyOperation();
} catch (e, stack) {
  await FirebaseCrashlytics.instance.recordError(e, stack);
}

// Log custom events
await FirebaseCrashlytics.instance.log('User performed action X');

// Set user identifier
await FirebaseCrashlytics.instance.setUserIdentifier(userId);

// Set custom keys
await FirebaseCrashlytics.instance.setCustomKey('user_type', 'premium');
```

---

## 15. Build and Deployment

### 15.1 Build Flavors

**Setup Flavors**:
```dart
// Define flavors in build.gradle (Android)
android {
    flavorDimensions "environment"
    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            versionNameSuffix "-staging"
        }
        production {
            dimension "environment"
        }
    }
}

// Define schemes in Xcode (iOS)
// Create Dev, Staging, Production schemes

// Run with flavor
flutter run --flavor dev -t lib/main_dev.dart
flutter build apk --flavor production -t lib/main_production.dart
```

**Flavor-Specific Configuration**:
```dart
// lib/config/app_config.dart
class AppConfig {
  final String apiBaseUrl;
  final String appName;
  final bool enableLogging;
  
  AppConfig({
    required this.apiBaseUrl,
    required this.appName,
    required this.enableLogging,
  });
  
  static late AppConfig instance;
}

// lib/main_dev.dart
void main() {
  AppConfig.instance = AppConfig(
    apiBaseUrl: 'https://dev-api.example.com',
    appName: 'MyApp Dev',
    enableLogging: true,
  );
  runApp(MyApp());
}

// lib/main_production.dart
void main() {
  AppConfig.instance = AppConfig(
    apiBaseUrl: 'https://api.example.com',
    appName: 'MyApp',
    enableLogging: false,
  );
  runApp(MyApp());
}
```

### 15.2 Version Management

**Versioning**:
```yaml
# pubspec.yaml
version: 1.2.3+42
# 1.2.3 = version name (major.minor.patch)
# 42 = version code/build number
```

**Best Practices**:
- Increment build number for every release
- Use semantic versioning
- Update version before release
- Tag releases in Git
- Maintain changelog

### 15.3 App Signing

**Android Signing**:
```properties
# android/key.properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=path/to/keystore.jks
```

```gradle
// android/app/build.gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

**iOS Signing**:
- Use Xcode to manage signing
- Use Automatic Signing for development
- Use Manual Signing for distribution
- Keep certificates and provisioning profiles updated

### 15.4 Release Builds

**Build Commands**:
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
flutter build ipa --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

### 15.5 CI/CD

**GitHub Actions Example**:
```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        channel: 'stable'
    
    - name: Get dependencies
      run: flutter pub get
    
    - name: Run tests
      run: flutter test
    
    - name: Analyze code
      run: flutter analyze
    
    - name: Build APK
      run: flutter build apk --release
    
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: app-release
        path: build/app/outputs/flutter-apk/app-release.apk
```

---

## 16. Common Flutter Anti-Patterns to AVOID

### 16.1 Widget Anti-Patterns

**Avoid**:
- ❌ Massive build methods (> 200 lines)
- ❌ Deep widget nesting (> 6 levels)
- ❌ Not using const constructors
- ❌ Rebuilding entire widget tree
- ❌ Storing state in widgets that should be stateless
- ❌ Not disposing controllers and listeners
- ❌ Using GlobalKey excessively

### 16.2 State Management Anti-Patterns

**Avoid**:
- ❌ Using setState for global state
- ❌ Prop drilling through many levels
- ❌ Not separating UI from business logic
- ❌ Mixing state management solutions
- ❌ Storing derived state
- ❌ Not cleaning up streams and subscriptions

### 16.3 Performance Anti-Patterns

**Avoid**:
- ❌ Not using ListView.builder for long lists
- ❌ Heavy computations in build method
- ❌ Not caching expensive calculations
- ❌ Unnecessary widget rebuilds
- ❌ Not using RepaintBoundary
- ❌ Loading all images at once
- ❌ Not implementing lazy loading

### 16.4 Architecture Anti-Patterns

**Avoid**:
- ❌ Mixing layers (UI code in domain layer)
- ❌ Direct dependencies on concrete implementations
- ❌ God objects doing too much
- ❌ Tight coupling between features
- ❌ Not using dependency injection
- ❌ Hard-coded values instead of constants

---

## 17. Code Quality and Best Practices

### 17.1 Code Style

**Dart Style Guide**:
```dart
// Good naming
class UserRepository {}
void getUserById(String id) {}
const maxRetries = 3;

// Bad naming
class user_repository {}
void get_user_by_id(String id) {}
const MAX_RETRIES = 3;

// Use type inference when obvious
var name = 'John'; // Type is clear
final count = 42;  // Type is clear

// Specify types when not obvious
List<User> users = []; // Specify generic type
Map<String, dynamic> json = {}; // Specify map types

// Prefer expression function bodies
String greet(String name) => 'Hello, $name!';

// Use trailing commas for better diffs
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Line 1'),
      Text('Line 2'),
      Text('Line 3'), // Trailing comma
    ],
  );
}
```

### 17.2 Linting

**analysis_options.yaml**:
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - always_require_non_null_named_parameters
    - annotate_overrides
    - avoid_empty_else
    - avoid_init_to_null
    - avoid_null_checks_in_equality_operators
    - avoid_relative_lib_imports
    - avoid_return_types_on_setters
    - avoid_shadowing_type_parameters
    - avoid_types_as_parameter_names
    - await_only_futures
    - camel_case_extensions
    - camel_case_types
    - constant_identifier_names
    - curly_braces_in_flow_control_structures
    - empty_catches
    - empty_constructor_bodies
    - library_names
    - library_prefixes
    - no_duplicate_case_values
    - null_closures
    - prefer_adjacent_string_concatenation
    - prefer_collection_literals
    - prefer_conditional_assignment
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - prefer_is_empty
    - prefer_is_not_empty
    - prefer_single_quotes
    - recursive_getters
    - slash_for_doc_comments
    - type_init_formals
    - unawaited_futures
    - unnecessary_const
    - unnecessary_new
    - unnecessary_null_in_if_null_operators
    - unnecessary_this
    - unrelated_type_equality_checks
    - use_function_type_syntax_for_parameters
    - use_rethrow_when_possible
    - valid_regexps

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore
```

### 17.3 Documentation

**Code Documentation**:
```dart
/// Fetches a user by their unique identifier.
///
/// Returns a [User] object if found, throws [UserNotFoundException]
/// if the user doesn't exist, or [NetworkException] on network errors.
///
/// Example:
/// ```dart
/// final user = await repository.getUserById('123');
/// print(user.name);
/// ```
Future<User> getUserById(String id) async {
  // Implementation
}

/// Represents a user in the system.
///
/// Contains user information including name, email, and profile data.
class User {
  /// The unique identifier for this user.
  final String id;
  
  /// The user's full name.
  final String name;
  
  /// The user's email address.
  final String email;
  
  /// Creates a new user instance.
  const User({
    required this.id,
    required this.name,
    required this.email,
  });
}
```

---

## 18. Enforcement and Quality Assurance

### 18.1 Pre-Commit Checks

**Git Hooks**:
```bash
# .git/hooks/pre-commit
#!/bin/sh

# Run formatter
flutter format .

# Run analyzer
flutter analyze
if [ $? -ne 0 ]; then
  echo "Flutter analyze failed"
  exit 1
fi

# Run tests
flutter test
if [ $? -ne 0 ]; then
  echo "Tests failed"
  exit 1
fi

exit 0
```

### 18.2 Code Review Checklist

**Flutter Code Review**:
- [ ] Code follows Dart style guide
- [ ] All widgets use const constructors where possible
- [ ] No unnecessary rebuilds
- [ ] Proper state management implemented
- [ ] Resources disposed properly (controllers, subscriptions)
- [ ] Error handling implemented
- [ ] Loading states implemented
- [ ] Accessibility labels provided
- [ ] Tests cover critical functionality
- [ ] No hardcoded strings (use localization)
- [ ] No hardcoded values (use constants)
- [ ] Platform-specific code handled properly
- [ ] Performance optimizations applied
- [ ] Security best practices followed

### 18.3 Quality Metrics

**Track These Metrics**:
- Code coverage (target: 80%+)
- Widget rebuild count
- Frame rendering time (target: < 16ms)
- App startup time
- Memory usage
- App size (APK/IPA size)
- Number of dependencies
- Technical debt ratio
- Crash-free rate (target: 99.9%+)

---

## 19. Conclusion

This Flutter development guide provides comprehensive, mandatory standards for building professional, performant, accessible, and maintainable mobile and desktop applications with Flutter.

**Core Flutter Principles**:

1. **Widget Composition**: Build UIs from small, focused, reusable widgets
2. **Clean Architecture**: Separate presentation, domain, and data layers
3. **State Management**: Choose appropriate solution for app complexity
4. **Performance First**: Optimize for 60fps, minimize rebuilds
5. **Platform Awareness**: Respect platform conventions (Material/Cupertino)
6. **Accessibility**: Build for all users with proper semantics
7. **Testing**: Test widgets, business logic, and user flows
8. **Security**: Protect sensitive data and user privacy
9. **Code Quality**: Follow Dart style guide, use linters
10. **Continuous Improvement**: Monitor, measure, optimize

**Remember**: Flutter enables building beautiful, fast applications for multiple platforms from a single codebase. These guidelines ensure every Flutter application is production-ready, maintainable, performant, and provides excellent user experience across all platforms and devices.

Flutter's hot reload enables rapid development, but production quality requires discipline, attention to detail, and adherence to best practices. Build apps that users love and that your team can maintain with pride.

---

**Document Version**: 1.0  
**Last Updated**: February 2026  
**Applies To**: All Flutter projects (mobile and desktop), all Flutter team members, all AI agents  
**Companion Documents**: 
- ai-agents.md (General AI Agent Development Guidelines)
- ai-agents-backend.md (Backend Development Guidelines)
- ai-agents-frontend.md (Frontend Development Guidelines)  
**Status**: Active and Enforced  
**Review Cycle**: Quarterly