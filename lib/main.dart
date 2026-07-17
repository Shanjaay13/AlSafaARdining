import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/cart_provider.dart';
import 'screens/qr_scanner_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const AlSafaApp(),
    ),
  );
}

class AlSafaApp extends StatelessWidget {
  const AlSafaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al Safa AR Dining',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0F2A1D), // Midnight Green
        scaffoldBackgroundColor: const Color(0xFF121412), // Obsidian Black
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0F2A1D),
          secondary: Color(0xFFD4A24C), // Refined Gold
          surface: Color(0xFF142A22), // Card Surface
          background: Color(0xFF121412),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          // Ensure clear reading contrast in AR layouts
          bodyLarge: const TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
      home: const QrScannerPage(),
    );
  }
}
