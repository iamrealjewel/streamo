import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/download_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

class DoubleDotHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _DoubleDotHttpClient(super.createHttpClient(context));
  }
}

class _DoubleDotHttpClient implements HttpClient {
  final HttpClient _inner;

  _DoubleDotHttpClient(this._inner);

  Uri _fixUrl(Uri url) {
    final urlStr = url.toString();
    if (urlStr.contains('googlevideo..com')) {
      return Uri.parse(urlStr.replaceFirst('googlevideo..com', 'googlevideo.com'));
    }
    return url;
  }

  String _fixHost(String host) {
    if (host.contains('googlevideo..com')) {
      return host.replaceFirst('googlevideo..com', 'googlevideo.com');
    }
    return host;
  }

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) {
    return _inner.open(method, _fixHost(host), port, path);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return _inner.openUrl(method, _fixUrl(url));
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    return _inner.get(_fixHost(host), port, path);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return _inner.getUrl(_fixUrl(url));
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) {
    return _inner.post(_fixHost(host), port, path);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    return _inner.postUrl(_fixUrl(url));
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) {
    return _inner.put(_fixHost(host), port, path);
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) {
    return _inner.putUrl(_fixUrl(url));
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) {
    return _inner.delete(_fixHost(host), port, path);
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) {
    return _inner.deleteUrl(_fixUrl(url));
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) {
    return _inner.head(_fixHost(host), port, path);
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) {
    return _inner.headUrl(_fixUrl(url));
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    return _inner.patch(_fixHost(host), port, path);
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    return _inner.patchUrl(_fixUrl(url));
  }

  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;
  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;

  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;
  @override
  Duration get idleTimeout => _inner.idleTimeout;

  @override
  set maxConnectionsPerHost(int? value) => _inner.maxConnectionsPerHost = value;
  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;

  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;
  @override
  bool get autoUncompress => _inner.autoUncompress;

  @override
  set userAgent(String? value) => _inner.userAgent = value;
  @override
  String? get userAgent => _inner.userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {
    _inner.addCredentials(_fixUrl(url), realm, credentials);
  }

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {
    _inner.addProxyCredentials(_fixHost(host), port, realm, credentials);
  }

  @override
  set findProxy(String Function(Uri url)? f) {
    _inner.findProxy = f != null ? (uri) => f(_fixUrl(uri)) : null;
  }

  @override
  set authenticate(Future<bool> Function(Uri url, String realm, String? scheme)? f) {
    _inner.authenticate = f != null ? (uri, realm, scheme) => f(_fixUrl(uri), realm, scheme) : null;
  }

  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String realm, String? scheme)? f) {
    _inner.authenticateProxy = f;
  }

  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) =>
      _inner.badCertificateCallback = callback;

  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) =>
      _inner.connectionFactory = f;

  @override
  set keyLog(Function(String line)? callback) => _inner.keyLog = callback;

  @override
  void close({bool force = false}) => _inner.close(force: force);
}

void main() async {
  HttpOverrides.global = DoubleDotHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
      ],
      child: const StreamoApp(),
    ),
  );
}

class StreamoApp extends StatelessWidget {
  const StreamoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, _) {
        return MaterialApp(
          title: 'Streamo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF0050),
          brightness: Brightness.dark,
          primary: const Color(0xFFFF0050),
          secondary: const Color(0xFF00D4FF),
          surface: const Color(0xFF0F0F1A),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A14),
        cardColor: const Color(0xFF16162A),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2A2A45)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2A2A45)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: Color(0xFFFF0050), width: 2),
          ),
          hintStyle:
              const TextStyle(color: Color(0xFF6B6B8A), fontSize: 15),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 18),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF0050),
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            elevation: 0,
          ),
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF0050),
          brightness: Brightness.light,
          primary: const Color(0xFFFF0050),
          secondary: const Color(0xFF0099CC),
          surface: const Color(0xFFF5F5FF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F0FF),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.light().textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0E0F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0E0F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: Color(0xFFFF0050), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF0050),
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      );
}
