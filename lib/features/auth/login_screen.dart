import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:randomchat_admin/core/navigation/admin_shell_path_provider.dart';
import 'package:randomchat_admin/core/providers/auth_provider.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/shared/widgets/admin_dialog.dart';

/// Figma LOG-01 (1440×1024)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _remember = false;
  bool _submitting = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _username.text.trim();
    final password = _password.text;

    if (username.isEmpty || password.isEmpty) {
      await showAdminAlertDialog(
        context,
        title: '입력 확인',
        message: '아이디와 비밀번호를 입력해주세요.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final ok = await ref.read(authProvider.notifier).login(
            username,
            password,
            rememberMe: _remember,
          );
      if (!mounted) return;

      if (ok) {
        ref.read(adminShellPathProvider.notifier).resetTo('/dashboard');
        context.go('/admin');
        return;
      }

      final error = ref.read(authProvider).error ?? '로그인에 실패했습니다.';
      await showAdminAlertDialog(
        context,
        title: '로그인 실패',
        message: error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '랜덤채팅',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              const Text(
                '중년의 품격',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _username,
                enabled: !_submitting && !auth.loading,
                decoration: const InputDecoration(hintText: '아이디'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                enabled: !_submitting && !auth.loading,
                obscureText: true,
                decoration: const InputDecoration(hintText: '비밀번호'),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _remember,
                    onChanged: _submitting
                        ? null
                        : (v) => setState(() => _remember = v ?? false),
                  ),
                  const Text('로그인 상태 유지'),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting || auth.loading ? null : _submit,
                  child: Text(
                    _submitting || auth.loading ? '로그인 중...' : '로그인',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
