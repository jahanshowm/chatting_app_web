import 'package:flutter/material.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/shared/constants/korea_regions.dart';

/// FCM 타겟발송용 시/도·시군구 다중 선택
class RegionMultiSelectField extends StatelessWidget {
  const RegionMultiSelectField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  static List<MapEntry<String, List<String>>> get _regions {
    return koreaDistrictData
        .map((m) => MapEntry(m.keys.first, List<String>.from(m.values.first)))
        .toList();
  }

  Future<void> _openDialog(BuildContext context) async {
    final draft = Set<String>.from(selected);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('지역 선택 (시/군/구)'),
              content: SizedBox(
                width: 480,
                height: 480,
                child: ListView(
                  children: [
                    for (final entry in _regions)
                      ExpansionTile(
                        title: Text(entry.key),
                        subtitle: Text(
                          _selectedInProvince(entry.key, entry.value, draft).isEmpty
                              ? '미선택'
                              : '${_selectedInProvince(entry.key, entry.value, draft).length}개 선택',
                        ),
                        children: [
                          CheckboxListTile(
                            title: Text('${entry.key} 전체'),
                            value: draft.contains('${entry.key} 전체'),
                            onChanged: (v) {
                              setDialogState(() {
                                if (v == true) {
                                  draft.removeWhere((s) => entry.value.contains(s));
                                  draft.add('${entry.key} 전체');
                                } else {
                                  draft.remove('${entry.key} 전체');
                                }
                              });
                            },
                          ),
                          for (final district in entry.value.where((d) => !d.endsWith(' 전체')))
                            CheckboxListTile(
                              title: Text(district),
                              value: draft.contains(district),
                              onChanged: (v) {
                                setDialogState(() {
                                  draft.remove('${entry.key} 전체');
                                  if (v == true) {
                                    draft.add(district);
                                  } else {
                                    draft.remove(district);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
                TextButton(
                  onPressed: () {
                    onChanged(draft);
                    Navigator.pop(ctx);
                  },
                  child: const Text('적용'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static List<String> _selectedInProvince(
    String province,
    List<String> districts,
    Set<String> selected,
  ) {
    return selected.where((s) => s == '$province 전체' || districts.contains(s)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _openDialog(context),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: Text(selected.isEmpty ? '지역 선택' : '지역 ${selected.length}개 선택됨'),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final region in selected)
                InputChip(
                  label: Text(region),
                  onDeleted: () {
                    final next = Set<String>.from(selected)..remove(region);
                    onChanged(next);
                  },
                ),
            ],
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '선택하지 않으면 전국 대상입니다.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
