import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

void main() {
  // Flutter 엔진 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();
  // runApp을 먼저 호출하고, 앱 내부에서 비동기 초기화를 처리합니다.
  // 이렇게 하면 핫 리스타트 시 개발 도구와의 연결이 안정적으로 이루어집니다.
  // It's good practice to have a single instance of the analytics service.
  // You could use a service locator like get_it for more complex apps.
  AnalyticsService.instance.logAppOpen();
  runApp(const MyApp());
}

/// A simple service wrapper for Firebase Analytics.
class AnalyticsService {
  AnalyticsService._(); // Private constructor
  static final instance = AnalyticsService._();

  final _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent({required String name, Map<String, Object>? parameters}) =>
      _analytics.logEvent(name: name, parameters: parameters);

  Future<void> logAppOpen() => _analytics.logAppOpen();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Firebase 초기화를 위한 Future를 정의합니다.
  late final Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeFirebase();
  }

  Future<FirebaseApp> _initializeFirebase() async {
    await dotenv.load(fileName: ".env");
    return Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['WEB_API_KEY']!,
        appId: dotenv.env['WEB_APP_ID']!,
        messagingSenderId: dotenv.env['WEB_MESSAGING_SENDER_ID']!,
        projectId: dotenv.env['WEB_PROJECT_ID']!,
        measurementId: dotenv.env['WEB_MEASUREMENT_ID'],
      ),
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        // 에러가 발생하면 에러 화면을 보여줍니다.
        if (snapshot.hasError) {
          return const Center(child: Text("Firebase 초기화 실패"));
        }

        // 초기화가 완료되면 앱의 메인 화면을 보여줍니다.
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
            home: const MyHomePage(title: 'Flutter Demo Home Page'),
          );
        }

        // 초기화 중에는 로딩 인디케이터를 보여줍니다.
        return const Center(child: CircularProgressIndicator());
      },
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
    // 1. 버튼 클릭 시점의 카운터 값을 사용하여 GA 이벤트를 먼저 전송합니다.
    // 이렇게 하면 데이터 분석 시 "사용자가 어떤 값에서 클릭했는지"를 정확히 알 수 있습니다.
    AnalyticsService.instance.logEvent(
      name: 'click_floating',
      parameters: {
        'color': 'blue',
        'count_before_increment': _counter, // 파라미터 이름을 명확하게 변경
      },
    );

    // 2. 이벤트 전송 후, 화면의 상태를 업데이트합니다.
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
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
