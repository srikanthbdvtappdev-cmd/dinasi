import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/grocery_provider.dart';
import 'providers/language_provider.dart';
import 'providers/notepad_provider.dart';
import 'providers/predefined_items_provider.dart';
import 'providers/saved_lists_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Transparent system bars with dark icons to match the light app background.
  // Works in tandem with enableEdgeToEdge() in MainActivity for Android 15+.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => GroceryListProvider()),
        ChangeNotifierProvider(create: (_) => PredefinedItemsProvider()),
        ChangeNotifierProvider(create: (_) => SavedListsProvider()),
        ChangeNotifierProvider(create: (_) => NotepadProvider()),
      ],
      child: const DinasiApp(),
    ),
  );
}

class DinasiApp extends StatelessWidget {
  const DinasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ದಿನಸಿ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2D6A4F),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F5EE),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5EE),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
