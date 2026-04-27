import 'package:adhdnotes/data/db/app_database.dart';
import 'package:adhdnotes/data/repositories/notes_repository.dart';
import 'package:adhdnotes/presentation/home/home_screen.dart';
import 'package:adhdnotes/presentation/providers/notes_provider.dart';
import 'package:adhdnotes/presentation/providers/permissions_provider.dart';
import 'package:adhdnotes/presentation/providers/recording_provider.dart';
import 'package:adhdnotes/services/api/deepseek_client.dart';
import 'package:adhdnotes/services/calendar/calendar_service.dart';
import 'package:adhdnotes/services/notifications/notification_service.dart';
import 'package:adhdnotes/services/permissions/permissions_service.dart';
import 'package:adhdnotes/services/speech/speech_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? '';
  final deepSeekClient = DeepSeekClient(apiKey: apiKey);
  final notificationService = NotificationService();

  runApp(
    AppProviders(
      deepSeekClient: deepSeekClient,
      notificationService: notificationService,
    ),
  );
}

class AppProviders extends StatelessWidget {
  const AppProviders({
    super.key,
    required this.deepSeekClient,
    required this.notificationService,
  });

  final DeepSeekClient deepSeekClient;
  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    final database = AppDatabase.instance;
    final notesRepository = NotesRepository(database: database);
    final speechService = SpeechService();
    final calendarService = CalendarService();
    final permissionsService = PermissionsService(notificationService: notificationService);

    return MultiProvider(
      providers: [
        Provider.value(value: database),
        Provider.value(value: notesRepository),
        Provider.value(value: speechService),
        Provider.value(value: calendarService),
        Provider.value(value: notificationService),
        Provider.value(value: permissionsService),
        Provider.value(value: deepSeekClient),
        ChangeNotifierProvider(
          create: (_) => PermissionsProvider(
            permissionsService: permissionsService,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotesProvider(notesRepository: notesRepository)..load(),
        ),
        ChangeNotifierProxyProvider<NotesProvider, RecordingProvider>(
          create: (context) => RecordingProvider(
            speechService: context.read<SpeechService>(),
            deepSeekClient: context.read<DeepSeekClient>(),
            notesRepository: context.read<NotesRepository>(),
            calendarService: context.read<CalendarService>(),
            notificationService: context.read<NotificationService>(),
            permissionsProvider: context.read<PermissionsProvider>(),
          ),
          update: (_, notesProvider, recordingProvider) {
            recordingProvider!.notesProvider = notesProvider;
            return recordingProvider;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ADHD Notes',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
