import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/config/app_env.dart';
import 'package:randomchat_admin/core/router/app_router.dart';
import 'package:randomchat_admin/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.load();
  runApp(const ProviderScope(child: RandomChatAdminApp()));
}

class RandomChatAdminApp extends ConsumerWidget {
  const RandomChatAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '랜덤채팅 관리자',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
