import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:collection';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SiymonApp());
}

class SiymonApp extends StatelessWidget {
  const SiymonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'siymon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFFFF5722),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF5722)),
      ),
      home: const MainWebView(),
    );
  }
}

class MainWebView extends StatefulWidget {
  const MainWebView({super.key});

  @override
  State<MainWebView> createState() => _MainWebViewState();
}

class _MainWebViewState extends State<MainWebView> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  bool _isLoading = true;

  // إعدادات المتصفح السريعة والمغلقة
  InAppWebViewSettings settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    geolocationEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    cacheEnabled: true,
    allowFileAccess: true,
    allowContentAccess: true,
    transparentBackground: true,
    verticalScrollBarEnabled: false,
    horizontalScrollBarEnabled: false,
    supportZoom: false,
    builtInZoomControls: false,
    displayZoomControls: false,
  );

  Future<bool> _showExitDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'تنبيه الخروج',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'هل تريد الخروج من التطبيق',
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => SystemNavigator.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('خروج'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (webViewController != null && await webViewController!.canGoBack()) {
          await webViewController!.goBack();
        } else {
          await _showExitDialog();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(
                  url: WebUri('https://siymon7.com/driver/'),
                ),
                initialSettings: settings,
                initialUserScripts: UnmodifiableListView<UserScript>([
                  UserScript(
                    source: """
                      // 1. إخفاء الفوتر ومنع التحديد والزوم
                      var style = document.createElement('style');
                      style.innerHTML = `
                        footer { display: none !important; }
                        * {
                          -webkit-touch-callout: none !important;
                          -webkit-user-select: none !important;
                          user-select: none !important;
                        }
                        input, textarea {
                          -webkit-user-select: auto !important;
                          user-select: auto !important;
                        }
                        /* كلاس سحري هنضيفه للـ body */
                        body.hide-header-now .topbar {
                          display: none !important;
                          height: 0 !important;
                          padding: 0 !important;
                          margin: 0 !important;
                          opacity: 0 !important;
                          visibility: hidden !important;
                          pointer-events: none !important;
                        }
                        body.hide-header-now {
                          padding-top: 0 !important;
                          margin-top: 0 !important;
                        }
                      `;
                      document.head.appendChild(style);

                      var meta = document.createElement('meta');
                      meta.name = 'viewport';
                      meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                      document.getElementsByTagName('head')[0].appendChild(meta);

                      // 2. الرادار: دالة بتشتغل باستمرار تصطاد الهيدر وتخفيه
                      function enforceHeaderHidden() {
                        var url = window.location.href.toLowerCase();
                        
                        // بنخفي لو الرابط فيه login أو register أو لو هو الصفحة الرئيسية للسواق /driver/
                        var shouldHide = url.includes('login') || 
                                         url.includes('register') || 
                                         url.endsWith('/driver') || 
                                         url.endsWith('/driver/');
                                         
                        if (shouldHide) {
                          // إضافة الكلاس للـ body
                          document.body.classList.add('hide-header-now');
                          
                          // إخفاء إجباري مباشر للعنصر نفسه لو ظهر
                          var topbars = document.querySelectorAll('.topbar');
                          topbars.forEach(function(bar) {
                            bar.style.setProperty('display', 'none', 'important');
                          });
                        } else {
                          // لو دخل صفحة تانية (الداشبورد)، يرجع يظهر
                          document.body.classList.remove('hide-header-now');
                          var topbars = document.querySelectorAll('.topbar');
                          topbars.forEach(function(bar) {
                            bar.style.display = '';
                          });
                        }
                      }

                      // تشغيل الرادار كل 500 جزء من الثانية (عشان لو الموقع SPA وبيحمل متأخر)
                      setInterval(enforceHeaderHidden, 500);
                    """,
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
                  ),
                ]),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    _isLoading = true;
                  });
                },
                onLoadStop: (controller, url) {
                  setState(() {
                    _isLoading = false;
                  });
                },
                onGeolocationPermissionsShowPrompt: (controller, origin) async {
                  var status = await Permission.locationWhenInUse.request();
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: status.isGranted,
                    retain: true,
                  );
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  var uri = navigationAction.request.url!;
                  if (![
                    "http",
                    "https",
                    "file",
                    "chrome",
                    "data",
                    "javascript",
                    "about",
                  ].contains(uri.scheme)) {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      return NavigationActionPolicy.CANCEL;
                    }
                  }
                  return NavigationActionPolicy.ALLOW;
                },
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF5722)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
