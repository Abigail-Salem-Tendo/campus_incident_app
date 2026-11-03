import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/category_selector.dart';

class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  ReportCategory? _category;
  String? _location;
  bool _isAnonymous = false;
  String? _categoryError;

  String? _validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter a title';
    if (text.length < 5) return 'Title must be at least 5 characters';
    return null;
  }

  String? _validateLocation(String? value) {
    if (value == null) return 'Please choose a location';
    return null;
  }

  String? _validateDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please describe the issue';
    if (text.length < 10) return 'Description must be at least 10 characters';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final formOk = _formKey.currentState!.validate();
    final categoryOk = _category != null;

    setState(() {
      _categoryError = categoryOk ? null : 'Please choose a category';
    });

    if (!formOk || !categoryOk) return;

    final profile = context.read<AuthProvider>().profile;
    final user = FirebaseAuth.instance.currentUser;
    final reports = context.read<ReportProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (profile == null || user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
      return;
    }

    final success = await reports.submitReport(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category!,
      location: _location!,
      isAnonymous: _isAnonymous,
      reporterId: user.uid,
      reporterName: profile.name,
    );

    if (!mounted) return;

    if (success) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Report submitted')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            reports.errorMessage ?? 'Could not submit the report.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBusy = context.watch<ReportProvider>().isBusy;

    return Scaffold(
      appBar: AppBar(title: const Text('Report an issue')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Category', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                CategorySelector(
                  selected: _category,
                  errorText: _categoryError,
                  onChanged: (value) => setState(() {
                    _category = value;
                    _categoryError = null;
                  }),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  validator: _validateTitle,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Broken light in corridor',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _location,
                  validator: _validateLocation,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Location'),
                  items: AppConstants.campusLocations
                      .map(
                        (place) =>
                            DropdownMenuItem(value: place, child: Text(place)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _location = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  validator: _validateDescription,
                  maxLength: 500,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What happened? Add any detail that helps.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Report anonymously'),
                  subtitle: const Text("Staff won't see your name."),
                  value: _isAnonymous,
                  onChanged: (value) => setState(() => _isAnonymous = value),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isBusy ? null : _submit,
                  child: isBusy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit report'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}