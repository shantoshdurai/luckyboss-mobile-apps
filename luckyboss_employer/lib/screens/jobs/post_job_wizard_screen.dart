import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/employer_provider.dart';
import '../../widgets/ledger_components.dart';

class PostJobWizardScreen extends StatefulWidget {
  const PostJobWizardScreen({super.key});

  @override
  State<PostJobWizardScreen> createState() => _PostJobWizardScreenState();
}

class _PostJobWizardScreenState extends State<PostJobWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillController = TextEditingController();
  
  String _category = 'IT & Software';
  String _workMode = 'On-site';
  String _country = 'Singapore';
  String _experienceLevel = 'Mid Level';
  String _jobType = 'Full-Time';
  final List<String> _requiredSkills = [];

  String get _currency {
    switch (_country) {
      case 'Singapore': return 'SGD';
      case 'India': return 'INR';
      case 'Malaysia': return 'MYR';
      default: return 'SGD';
    }
  }

  String get _countryCode {
    switch (_country) {
      case 'Singapore': return 'SG';
      case 'India': return 'IN';
      case 'Malaysia': return 'MY';
      default: return 'SG';
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_requiredSkills.contains(skill)) {
      setState(() {
        _requiredSkills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_titleController.text.trim().isEmpty) return;
    
    context.read<EmployerProvider>().postNewJob(
      title: _titleController.text.trim(),
      category: _category,
      location: _locationController.text.trim(),
      minSalary: _minSalaryController.text.trim(),
      maxSalary: _maxSalaryController.text.trim(),
      currency: _currency,
      countryCode: _countryCode,
      workMode: _workMode,
      description: _descriptionController.text.trim(),
      requiredSkills: _requiredSkills,
      experienceLevel: _experienceLevel,
      jobType: _jobType,
    );
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.signalPositive,
        content: Text('Vacancy published successfully!', style: AppTheme.button(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.ink, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Post New Vacancy', style: AppTheme.screenTitle(size: 17)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: BrandRule(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // Job Title
            _buildLabel('Job Title *'),
            TextFormField(
              controller: _titleController,
              style: AppTheme.body(),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              decoration: _inputDecor('e.g. Senior Flutter Engineer'),
            ),
            const SizedBox(height: 16),

            // Category & Work Mode row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Category'),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        items: ['IT & Software', 'Logistics & Warehouse', 'Finance', 'Healthcare', 'Engineering', 'Sales & Marketing']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTheme.body(size: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v!),
                        decoration: _inputDecor(null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Work Mode'),
                      DropdownButtonFormField<String>(
                        initialValue: _workMode,
                        items: ['On-site', 'Remote', 'Hybrid']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTheme.body(size: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => _workMode = v!),
                        decoration: _inputDecor(null),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location & Country
            _buildLabel('City & Location *'),
            TextFormField(
              controller: _locationController,
              style: AppTheme.body(),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              decoration: _inputDecor('e.g. Singapore, One-North'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Country'),
                      DropdownButtonFormField<String>(
                        initialValue: _country,
                        items: ['Singapore', 'India', 'Malaysia']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTheme.body(size: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => _country = v!),
                        decoration: _inputDecor(null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Currency'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                          border: Border.all(color: AppTheme.rule, width: AppTheme.hairline),
                        ),
                        child: Text(_currency, style: AppTheme.score(size: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Salary Range
            _buildLabel('Salary Range (per month) *'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minSalaryController,
                    keyboardType: TextInputType.number,
                    style: AppTheme.body(),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    decoration: _inputDecor('Min'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to', style: AppTheme.body(size: 12)),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _maxSalaryController,
                    keyboardType: TextInputType.number,
                    style: AppTheme.body(),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    decoration: _inputDecor('Max'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Experience & Job Type
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Experience Level'),
                      DropdownButtonFormField<String>(
                        initialValue: _experienceLevel,
                        items: ['Entry Level', 'Mid Level', 'Senior', 'Lead', 'Director']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTheme.body(size: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => _experienceLevel = v!),
                        decoration: _inputDecor(null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Job Type'),
                      DropdownButtonFormField<String>(
                        initialValue: _jobType,
                        items: ['Full-Time', 'Part-Time', 'Contract', 'Internship']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTheme.body(size: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => _jobType = v!),
                        decoration: _inputDecor(null),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Job Description
            _buildLabel('Job Description *'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              style: AppTheme.body(),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              decoration: _inputDecor('Describe the role, day-to-day responsibilities, team structure...'),
            ),
            const SizedBox(height: 16),

            // Required Skills
            _buildLabel('Required Skills'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillController,
                    style: AppTheme.body(),
                    decoration: _inputDecor('e.g. Flutter, Docker...'),
                    onSubmitted: (_) => _addSkill(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addSkill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.ink,
                    foregroundColor: AppTheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusControl)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: Text('+ Add', style: AppTheme.button(color: AppTheme.surface)),
                ),
              ],
            ),
            if (_requiredSkills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _requiredSkills.map((s) {
                  return Chip(
                    label: Text(s, style: AppTheme.body(size: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14, color: AppTheme.inkMuted),
                    onDeleted: () => setState(() => _requiredSkills.remove(s)),
                    backgroundColor: AppTheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                      side: const BorderSide(color: AppTheme.rule, width: AppTheme.hairline),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.ink,
                  foregroundColor: AppTheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusControl)),
                ),
                child: Text('Publish Vacancy', style: AppTheme.button(color: AppTheme.surface)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MetaText(text, color: AppTheme.ink, size: 10),
    );
  }

  InputDecoration _inputDecor(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTheme.body(color: AppTheme.inkFaint, size: 13),
      fillColor: AppTheme.surface,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        borderSide: const BorderSide(color: AppTheme.rule, width: AppTheme.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        borderSide: const BorderSide(color: AppTheme.rule, width: AppTheme.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        borderSide: const BorderSide(color: AppTheme.ink, width: 1.4),
      ),
    );
  }
}