import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------
// Firebase.initializeApp() will be added in Milestone 4 once the
// google-services.json / GoogleService-Info.plist files are in place.
// ---------------------------------------------------------------------------
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Immersive dark status bar so the pitch background bleeds to the top edge
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: CrickifyColors.pitchDeep,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const CrickifyApp());
}

// ---------------------------------------------------------------------------
// Root widget
// ---------------------------------------------------------------------------
class CrickifyApp extends StatelessWidget {
  const CrickifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crickify',
      debugShowCheckedModeBanner: false,

      // Apply the full Crickify design system
      theme: CrickifyTheme.dark,

      // Named routes — screens will be added in Milestone 3
      initialRoute: '/',
      routes: {
        '/': (_) => const _PlaceholderJoinScreen(),
        // '/trivia' and '/hand' will be registered in Milestone 3
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Temporary placeholder — replaced in Milestone 3 with the real JoinScreen.
// Shows the branded shell so we can verify theme + fonts are working.
// ---------------------------------------------------------------------------
class _PlaceholderJoinScreen extends StatelessWidget {
  const _PlaceholderJoinScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Pitch gradient background (matches the CSS body gradient)
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B2317),
              CrickifyColors.pitchDeep,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Eyebrow label ──────────────────────────────────────────
                Text(
                  'STADIUM CONTROL ROOM',
                  style: CrickifyTextStyles.eyebrow,
                ),
                const SizedBox(height: 8),

                // ── Hero title ─────────────────────────────────────────────
                Text(
                  'Cricket\nArcade',
                  style: CrickifyTextStyles.hero.copyWith(fontSize: 52),
                ),
                const SizedBox(height: 12),

                // ── Kicker ─────────────────────────────────────────────────
                Text(
                  'Floodlights on. Dugout loud. Every tap counts.',
                  style: CrickifyTextStyles.bodyMuted,
                ),

                const Spacer(),

                // ── Milestone marker ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: CrickifyDecorations.card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MILESTONE 1 COMPLETE',
                        style: CrickifyTextStyles.eyebrow,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Design system is live.',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Colours ✓  •  Fonts ✓  •  Theme ✓\n'
                        'Join screen coming in Milestone 3.',
                        style: CrickifyTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Golden CTA ─────────────────────────────────────────────
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Walk Out to Bat'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
