import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/material/material_dto.dart';
import '../../../repositories/material_repository.dart';
import '../../../widgets/digikul_app_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/skeleton_loader.dart';
import '../widgets/material_card.dart';

class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  String _searchQuery = '';
  String? _selectedType;

  static const _filterTypes = ['All', 'PDF', 'DOC', 'PPT', 'Video', 'Other'];

  List<MaterialDto> _filterMaterials(List<MaterialDto> materials) {
    var filtered = materials;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((m) =>
              m.title.toLowerCase().contains(query) ||
              m.uploadedBy.toLowerCase().contains(query))
          .toList();
    }

    if (_selectedType != null && _selectedType != 'All') {
      filtered = filtered.where((m) {
        return switch (_selectedType!) {
          'PDF' => m.fileType.toLowerCase() == 'pdf',
          'DOC' => m.fileType.toLowerCase() == 'doc' ||
              m.fileType.toLowerCase() == 'docx',
          'PPT' => m.fileType.toLowerCase() == 'ppt' ||
              m.fileType.toLowerCase() == 'pptx',
          'Video' => ['mp4', 'avi', 'mov'].contains(m.fileType.toLowerCase()),
          'Other' => !['pdf', 'doc', 'docx', 'ppt', 'pptx', 'mp4', 'avi', 'mov']
              .contains(m.fileType.toLowerCase()),
          _ => true,
        };
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const DigikulAppBar(title: 'Materials'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(materialsProvider),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search materials...',
                    hintStyle: AppTextStyles.bodyMedium(
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _filterTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final type = _filterTypes[index];
                    final isSelected =
                        _selectedType == type || (type == 'All' && _selectedType == null);
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = selected ? type : null;
                        });
                      },
                      labelStyle: AppTextStyles.labelMedium(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      selectedColor: AppColors.primaryLight,
                      backgroundColor:
                          isDark ? AppColors.darkCard : AppColors.surface,
                    );
                  },
                ),
              ),
            ),
            materialsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SkeletonGrid(),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: AppErrorWidget(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(materialsProvider),
                ),
              ),
              data: (materials) {
                final filtered = _filterMaterials(materials);
                if (filtered.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyState(
                      title: 'No materials found',
                      subtitle: 'Try adjusting your search or filter',
                      icon: Icons.search_off_rounded,
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, index) => MaterialCard(material: filtered[index]),
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
