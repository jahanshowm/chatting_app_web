import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';

/// Figma CMS/PG/NTC 리스트 영역 테두리
class AdminListPanel extends StatelessWidget {
  const AdminListPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class GenderCellText extends StatelessWidget {
  const GenderCellText(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (value.contains('남')) color = AppColors.male;
    if (value.contains('여')) color = AppColors.female;
    return Text(
      value,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.text,
      ),
    );
  }
}

/// Figma 하단 [선택 삭제]
class SelectDeleteButton extends StatelessWidget {
  const SelectDeleteButton({
    super.key,
    required this.selectedCount,
    required this.onDelete,
  });

  final int selectedCount;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: selectedCount > 0 ? onDelete : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      child: const Text('선택 삭제'),
    );
  }
}

/// Figma CMS-02 활동내역 탭 (칩 형태)
class AdminChipTabBar extends StatelessWidget {
  const AdminChipTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<(String, String)> tabs;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final tab in tabs) ...[
          Material(
            color: selected == tab.$1 ? AppColors.periodSelected : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: selected == tab.$1 ? AppColors.periodSelected : AppColors.border,
              ),
            ),
            child: InkWell(
              onTap: () => onSelected(tab.$1),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Text(
                  tab.$2,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected == tab.$1 ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.filter,
    required this.filters,
    required this.keywordController,
    required this.onSearch,
    this.onFilterChanged,
    this.onReset,
    this.hint = '검색어를 입력하세요',
    this.useSearchIcon = false,
  });

  final String filter;
  final List<(String value, String label)> filters;
  final TextEditingController keywordController;
  final VoidCallback onSearch;
  final ValueChanged<String>? onFilterChanged;
  final VoidCallback? onReset;
  final String hint;
  final bool useSearchIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (filters.isNotEmpty) ...[
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              initialValue: filter,
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
              items: filters
                  .map((f) => DropdownMenuItem(value: f.$1, child: Text(f.$2)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  onFilterChanged?.call(v);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: TextField(
            controller: keywordController,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: useSearchIcon
                  ? IconButton(
                      icon: const Icon(Icons.search, color: AppColors.textSecondary),
                      onPressed: onSearch,
                    )
                  : null,
            ),
            onSubmitted: (_) => onSearch(),
          ),
        ),
        if (!useSearchIcon) ...[
          const SizedBox(width: 12),
          ElevatedButton(onPressed: onSearch, child: const Text('검색')),
        ],
        if (onReset != null) ...[
          const SizedBox(width: 8),
          OutlinedButton(onPressed: onReset, child: const Text('초기화')),
        ],
      ],
    );
  }
}

/// 페이지네이션: [이전] 1 2 3 ... [다음] (10페이지 단위)
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

  static const _chunkSize = 10;

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalPages < 1 ? 1 : totalPages;
    final chunkStart = ((page - 1) ~/ _chunkSize) * _chunkSize + 1;
    final chunkEnd = (chunkStart + _chunkSize - 1).clamp(1, safeTotal);
    final pages = [for (var i = chunkStart; i <= chunkEnd; i++) i];

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavButton(
            icon: Icons.chevron_left,
            enabled: page > 1,
            onTap: () => onPageChanged(page - 1),
          ),
          const SizedBox(width: 8),
          for (final p in pages)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _PageNumber(
                number: p,
                selected: p == page,
                onTap: () => onPageChanged(p),
              ),
            ),
          const SizedBox(width: 8),
          _NavButton(
            icon: Icons.chevron_right,
            enabled: page < safeTotal,
            onTap: () => onPageChanged(page + 1),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.enabled, required this.onTap});

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.inputBg,
        disabledBackgroundColor: AppColors.inputBg.withValues(alpha: 0.5),
      ),
    );
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber({required this.number, required this.selected, required this.onTap});

  final int number;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.inputBg,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InquiryStatusFilterBar extends StatelessWidget {
  const InquiryStatusFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  static const options = [
    ('all', '전체'),
    ('waiting', '대기중'),
    ('in_progress', '진행중'),
    ('closed', '완료'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('처리상태', style: TextStyle(fontWeight: FontWeight.w600)),
        for (final opt in options)
          InkWell(
            onTap: () {
              if (opt.$1 == 'all') {
                onChanged({'all'});
                return;
              }
              final next = Set<String>.from(selected)..remove('all');
              if (next.contains(opt.$1)) {
                next.remove(opt.$1);
              } else {
                next.add(opt.$1);
              }
              onChanged(next.isEmpty ? {'all'} : next);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: selected.contains(opt.$1) ||
                      (opt.$1 != 'all' && selected.contains('all')),
                  onChanged: (_) {
                    if (opt.$1 == 'all') {
                      onChanged({'all'});
                    } else {
                      final next = Set<String>.from(selected)..remove('all');
                      if (next.contains(opt.$1)) {
                        next.remove(opt.$1);
                      } else {
                        next.add(opt.$1);
                      }
                      onChanged(next.isEmpty ? {'all'} : next);
                    }
                  },
                ),
                Text(opt.$2),
              ],
            ),
          ),
      ],
    );
  }
}

class AdminEmptyList extends StatelessWidget {
  const AdminEmptyList({super.key, this.message = '검색 결과가 없습니다.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}

class AdminTotalCountBar extends StatelessWidget {
  const AdminTotalCountBar({super.key, required this.count, this.unit = '명'});

  final int count;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Text(
      '총 $count$unit',
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
  }
}

class AdminTabBar extends StatelessWidget {
  const AdminTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<(String, String)> tabs;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            _TabItem(
              label: tab.$2,
              selected: selected == tab.$1,
              onTap: () => onSelected(tab.$1),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
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

/// API product_name에 금액이 포함된 경우 중복 포맷 방지
String formatProductWithAmount(String? productName, dynamic amount, NumberFormat fmt) {
  final product = productName ?? '-';
  if (product.contains('(') && product.contains('원)')) return product;
  if (amount != null) return '$product (${fmt.format(amount)}원)';
  return product;
}

/// 회원 목록 등 — Figma [삭제] (상단)
class DeleteActionButton extends StatelessWidget {
  const DeleteActionButton({
    super.key,
    required this.selectedCount,
    required this.onDelete,
  });

  final int selectedCount;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: selectedCount > 0 ? onDelete : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.periodSelected,
        foregroundColor: Colors.white,
      ),
      child: const Text('삭제'),
    );
  }
}

/// 페이지네이션 하단 + 총 N명/건
class ListPageFooter extends StatelessWidget {
  const ListPageFooter({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    required this.totalCount,
    this.unit = '명',
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final int totalCount;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PaginationBar(page: page, totalPages: totalPages, onPageChanged: onPageChanged),
        const SizedBox(height: 12),
        AdminTotalCountBar(count: totalCount, unit: unit),
      ],
    );
  }
}
