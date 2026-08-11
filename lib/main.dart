/// ADMIN — CMS 앱 엔트리·env·MaterialApp.router
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:randomchat_admin/core/config/app_env.dart';
import 'package:randomchat_admin/core/navigation/admin_shell_path_provider.dart';
import 'package:randomchat_admin/core/navigation/admin_url_sync.dart';
import 'package:randomchat_admin/core/router/app_router.dart';
import 'package:randomchat_admin/core/theme/app_theme.dart';
// QA Web: ./deploy/deploy-admin-dev.sh → https://admin-dev.adminchat.kr
// 운영 Web: ./deploy/deploy-adminchat.sh → https://adminchat.kr
// 운영 API: (cwd randomchat_back) ./deploy/deploy-adminchat-api.sh

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.load();
  await _preloadKoreanFonts();
  runApp(const ProviderScope(child: RandomChatAdminApp()));
}

/// Web 첫 프레임 전 Noto Sans KR 로드 — 로딩 중 한글 깨짐(FOUT) 방지
Future<void> _preloadKoreanFonts() async {
  await GoogleFonts.pendingFonts([
    GoogleFonts.notoSansKr(fontWeight: FontWeight.w400),
    GoogleFonts.notoSansKr(fontWeight: FontWeight.w500),
    GoogleFonts.notoSansKr(fontWeight: FontWeight.w600),
    GoogleFonts.notoSansKr(fontWeight: FontWeight.w700),
  ]);
}

class RandomChatAdminApp extends ConsumerStatefulWidget {
  const RandomChatAdminApp({super.key});

  @override
  ConsumerState<RandomChatAdminApp> createState() => _RandomChatAdminAppState();
}

class _RandomChatAdminAppState extends ConsumerState<RandomChatAdminApp> {
  @override
  void initState() {
    super.initState();
    _bindBrowserBack();
  }

  void _bindBrowserBack() {
    // AdminAppPage가 아니라 앱 루트에 고정 — 로그인/로딩 전환으로 dispose되지 않음
    ensureAdminPopStateInstalled(() {
      if (!mounted) return;
      try {
        ref.read(adminShellPathProvider.notifier).handleBrowserBack();
      } catch (_) {
        // unmount race — 이전 "Using ref when unmounted" 방지
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _bindBrowserBack();

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '랜덤채팅 관리자',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
