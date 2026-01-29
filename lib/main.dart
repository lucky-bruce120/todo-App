import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init(); // Initialize notification service
  runApp(const MyApp());
}

/* ======================
   NOTIFICATION SERVICE
====================== */
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const InitializationSettings settings =
    InitializationSettings(android: androidSettings, iOS: iosSettings);

    await flutterLocalNotificationsPlugin.initialize(
      settings,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Task Notifications',
          channelDescription: 'Task reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

/* ======================
   MAIN APP
====================== */
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TODO App',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        primaryColor: const Color(0xFF0F74C6),
        cardColor: Colors.white,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF0F74C6),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF80B1FF),
        cardColor: const Color(0xFF1E1E1E),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF80B1FF),
        ),
      ),
      home: WelcomePage(
        onThemeToggle: toggleTheme,
        themeMode: _themeMode,
      ),
    );
  }
}

/* ======================
   WELCOME PAGE
====================== */
class WelcomePage extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;

  const WelcomePage({
    super.key,
    required this.onThemeToggle,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.light
                  ? Icons.wb_sunny
                  : Icons.nights_stay,
            ),
            onPressed: onThemeToggle,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Welcome to TODO App',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Organize your tasks smartly',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomePage(
                      onThemeToggle: onThemeToggle,
                      themeMode: themeMode,
                    ),
                  ),
                );
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}

/* ======================
   HOME PAGE
====================== */
class HomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;

  const HomePage({
    super.key,
    required this.onThemeToggle,
    required this.themeMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _controller = TextEditingController();
  DateTime? _selectedDateTime;

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _addTask() {
    if (_controller.text.isNotEmpty && _selectedDateTime != null) {
      final taskTitle = _controller.text;
      final taskTime = _selectedDateTime!;
      setState(() {
        _tasks.add({
          'title': taskTitle,
          'dateTime': taskTime,
        });
        _controller.clear();
        _selectedDateTime = null;
      });

      // Schedule notification
      NotificationService().scheduleNotification(
        id: _tasks.length,
        title: 'Task Reminder',
        body: taskTitle,
        dateTime: taskTime,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.light
                  ? Icons.wb_sunny
                  : Icons.nights_stay,
            ),
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /* ADD TASK CARD */
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
                color: Theme.of(context).cardColor,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Add new task...',
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDateTime == null
                              ? 'No date & time selected'
                              : '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} '
                              '${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: _pickDateTime,
                      ),
                      FloatingActionButton(
                        mini: true,
                        onPressed: _addTask,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            /* TASK LIST */
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(
                child: Text(
                  'No tasks yet',
                  style: TextStyle(fontSize: 18),
                ),
              )
                  : ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  final DateTime dt = task['dateTime'];

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).cardColor,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(task['title']),
                      subtitle: Text(
                          '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'),
                      trailing: IconButton(
                        icon:
                        const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _tasks.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
