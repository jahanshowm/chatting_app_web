import 'package:flutter/material.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.filter,
    required this.filters,
    required this.keywordController,
    required this.onSearch,
    this.onFilterChanged,
    this.hint = '검색어를 입력하세요',
  });

  final String filter;
  final List<(String value, String label)> filters;
  final TextEditingController keywordController;
  final VoidCallback onSearch;
  final ValueChanged<String>? onFilterChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            value: filter,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
            items: filters
                .map((f) => DropdownMenuItem(value: f.$1, child: Text(f.$2)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                onFilterChanged?.call(v);
                onSearch();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: keywordController,
            decoration: InputDecoration(hintText: hint),
            onSubmitted: (_) => onSearch(),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(onPressed: onSearch, child: const Text('검색')),
      ],
    );
  }
}

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$page / $totalPages', style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(
          onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('확인')),
      ],
    ),
  );
}

Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    );

Widget bulkDeleteBar({
  required int selectedCount,
  required VoidCallback onDelete,
}) {
  if (selectedCount == 0) return const SizedBox.shrink();
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Text('$selectedCount개 선택'),
        const Spacer(),
        OutlinedButton(onPressed: onDelete, child: const Text('선택 삭제')),
      ],
    ),
  );
}
