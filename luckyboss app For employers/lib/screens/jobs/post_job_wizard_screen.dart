import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/employer_provider.dart';

class PostJobWizardScreen extends StatefulWidget {
  const PostJobWizardScreen({super.key});

  @override
  State<PostJobWizardScreen> createState() => _PostJobWizardScreenState();
}

class _PostJobWizardScreenState extends State<PostJobWizardScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController(text: 'Bengaluru, India');
  final _minSalaryController = TextEditingController(text: '90000');
  final _maxSalaryController = TextEditingController(text: '150000');
  final String _category = 'IT & Software';
  final String _currency = 'INR';

  void _generateWithAI() {
    _titleController.text = 'Senior Full-Stack Mobile & Cloud Engineer';
    _locationController.text = 'Bengaluru / Singapore Hybrid';
    _minSalaryController.text = '120000';
    _maxSalaryController.text = '180000';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✨ Smart AI auto-filled optimal vacancy parameters!')),
    );
  }

  void _submit() {
    if (_titleController.text.isEmpty) return;
    Provider.of<EmployerProvider>(context, listen: false).postNewJob(
      title: _titleController.text,
      category: _category,
      location: _locationController.text,
      minSalary: _minSalaryController.text,
      maxSalary: _maxSalaryController.text,
      currency: _currency,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Post Vacancy', style: AppTheme.sansBold(fontSize: 17, color: AppTheme.primaryNavy)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.auto_awesome, color: AppTheme.amber),
              label: Text('⚡ Auto-Fill with Lucky AI', style: AppTheme.sansBold(color: AppTheme.primaryNavy)),
              onPressed: _generateWithAI,
            ),
            const SizedBox(height: 20),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Job Title')),
            const SizedBox(height: 16),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'City & Location')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _minSalaryController, decoration: const InputDecoration(labelText: 'Min Salary'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _maxSalaryController, decoration: const InputDecoration(labelText: 'Max Salary'))),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Publish Vacancy →'),
            ),
          ],
        ),
      ),
    );
  }
}