import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/core_providers.dart';

class InstitutionSelector extends ConsumerStatefulWidget {
  const InstitutionSelector({super.key, required this.onSelected});

  final ValueChanged<String?> onSelected;

  @override
  ConsumerState<InstitutionSelector> createState() => _InstitutionSelectorState();
}

class _InstitutionSelectorState extends ConsumerState<InstitutionSelector> {
  List<Map<String, dynamic>> _institutions = [];
  String? _selectedId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
  }

  Future<void> _loadInstitutions() async {
    final institutions = await ref.read(authRepositoryProvider).fetchInstitutions();
    if (mounted) {
      setState(() {
        _institutions = institutions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Institution',
          prefixIcon: Icon(Icons.school_outlined),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading institutions...'),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedId,
      decoration: const InputDecoration(
        labelText: 'Institution',
        prefixIcon: Icon(Icons.school_outlined),
      ),
      hint: Text(
        'Select your institution',
        style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
      ),
      items: _institutions.map((inst) {
        return DropdownMenuItem<String>(
          value: inst['id'] as String,
          child: Text(
            inst['name'] as String? ?? 'Unknown',
            style: AppTextStyles.bodyMedium(),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedId = value);
        widget.onSelected(value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please select an institution';
        return null;
      },
    );
  }
}
