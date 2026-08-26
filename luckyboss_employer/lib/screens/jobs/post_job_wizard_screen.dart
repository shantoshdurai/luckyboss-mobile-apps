import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/employer_provider.dart';

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
    
    Provider.of<EmployerProvider>(context, listen: false).postNewJob(
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
        backgroundColor: AppTheme.emerald,
        content: Text('Vacancy published successfully!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.navy, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Post New Vacancy', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // Job Title
            _buildLabel('Job Title *'),
            TextFormField(
              controller: _titleController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              decoration: _inputDecor('e.g. Senior Flutter Engineer'),
            ),
            const SizedBox(height: 18),

            // Category & Work Mode row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Category'),
                      DropdownButtonFormField<String>(
                        value: _category,
                        items: ['IT & Software', 'Logistics & Warehouse', 'Finance', 'Healthcare', 'Engineering', 'Sales & Marketing']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
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
                        value: _workMode,
                        items: ['On-site', 'Remote', 'Hybrid']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => _workMode = v!),
                        decoration: _inputDecor(null),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Location & Country
            _buildLabel('City & Location *'),
            TextFormField(
              controller: _locationController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              decoration: _inputDecor('e.g. Bengaluru, India'),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Country'),
                      DropdownButtonFormField<String>(
                        value: _country,
                        items: ['Singapore', 'India', 'Malaysia']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
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
                          color: AppTheme.bgPaper,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_currency, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.navy)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Salary Range
            _buildLabel('Salary Range (per month) *'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minSalaryController,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    decoration: _inputDecor('Min'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted)),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _maxSalaryController,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    decoration: _inputDecor('Max'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Experience & Job Type
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Experience Level'),
                      DropdownButtonFormField<String>(
                        value: _experienceLevel,
                        items: ['Entry Level', 'Mid Level', 'Senior', 'Lead', 'Director']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
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
                        value: _jobType,
                        items: ['Full-Time', 'Part-Time', 'Contract', 'Internship']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => _jobType = v!),
                        decoration: _inputDecor(null),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Job Description
            _buildLabel('Job Description *'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              decoration: _inputDecor('Describe the role, day-to-day responsibilities, team structure...'),
            ),
            const SizedBox(height: 18),

            // Required Skills
            _buildLabel('Required Skills'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillController,
                    decoration: _inputDecor('e.g. Flutter, Docker...'),
                    onSubmitted: (_) => _addSkill(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addSkill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: const Text('+ Add'),
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
                    label: Text(s, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _requiredSkills.remove(s)),
                    backgroundColor: AppTheme.bgPaper,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Publish Vacancy', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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
      child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.navy)),
    );
  }

  InputDecoration _inputDecor(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: const Color(0xFF94A3B8), fontSize: 13),
      fillColor: AppTheme.bgPaper,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}