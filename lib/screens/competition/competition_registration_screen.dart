import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/competition.dart';
import '../../services/api_service.dart';

class CompetitionRegistrationScreen extends StatefulWidget {
  final Competition competition;
  final String studentId;

  const CompetitionRegistrationScreen({
    super.key,
    required this.competition,
    required this.studentId,
  });

  @override
  State<CompetitionRegistrationScreen> createState() =>
      _CompetitionRegistrationScreenState();
}

class _CompetitionRegistrationScreenState
    extends State<CompetitionRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final Map<String, dynamic> _formData = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pendaftaran Kompetisi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSubmitting
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreenBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.competition.title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppColors.primaryGreen,
                                  fontSize: 22,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lengkapi formulir di bawah ini dengan data yang benar.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...widget.competition.formFields.map(
                      (field) => _buildField(field),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Kirim Pendaftaran'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField(CompetitionFormField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (field.isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInputField(field),
        ],
      ),
    );
  }

  Widget _buildInputField(CompetitionFormField field) {
    switch (field.fieldType) {
      case 'TEXT':
      case 'TEXTAREA':
        return TextFormField(
          maxLines: field.fieldType == 'TEXTAREA' ? 4 : 1,
          decoration: _inputDecoration(field),
          style: const TextStyle(fontSize: 15),
          validator: (value) => _validate(value, field),
          onSaved: (value) => _formData[field.id] = value,
        );
      case 'NUMBER':
        return TextFormField(
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(field),
          style: const TextStyle(fontSize: 15),
          validator: (value) => _validate(value, field),
          onSaved: (value) => _formData[field.id] = value,
        );
      case 'DATE':
        return TextFormField(
          readOnly: true,
          decoration: _inputDecoration(field).copyWith(
            suffixIcon: const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: AppColors.primaryGreen,
            ),
          ),
          style: const TextStyle(fontSize: 15),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1990),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primaryGreen,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              final formattedDate =
                  "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
              setState(() {
                _formData[field.id] = formattedDate;
              });
            }
          },
          // Display the selected date if it exists
          controller: TextEditingController(text: _formData[field.id] ?? ''),
          validator: (value) => _validate(_formData[field.id], field),
        );
      case 'SELECT':
        List<String> options = _getOptions(field);
        return DropdownButtonFormField<String>(
          items: options
              .map(
                (o) => DropdownMenuItem(
                  value: o,
                  child: Text(o, style: const TextStyle(fontSize: 15)),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _formData[field.id] = value),
          decoration: _inputDecoration(field),
          dropdownColor: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          validator: (value) => _validate(value, field),
        );
      case 'RADIO':
        List<String> options = _getOptions(field);
        return Column(
          children: options
              .map(
                (o) => RadioListTile<String>(
                  title: Text(o, style: const TextStyle(fontSize: 15)),
                  value: o,
                  groupValue: _formData[field.id],
                  activeColor: AppColors.primaryGreen,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (value) {
                    setState(() => _formData[field.id] = value);
                  },
                ),
              )
              .toList(),
        );
      case 'CHECKBOX':
        List<String> options = _getOptions(field);
        _formData[field.id] ??= <String>[];
        return Column(
          children: options.map((o) {
            final List<String> currentValues = List<String>.from(
              _formData[field.id],
            );
            return CheckboxListTile(
              title: Text(o, style: const TextStyle(fontSize: 15)),
              value: currentValues.contains(o),
              activeColor: AppColors.primaryGreen,
              contentPadding: EdgeInsets.zero,
              dense: true,
              onChanged: (bool? checked) {
                setState(() {
                  if (checked == true) {
                    currentValues.add(o);
                  } else {
                    currentValues.remove(o);
                  }
                  _formData[field.id] = currentValues;
                });
              },
            );
          }).toList(),
        );
      case 'FILE':
        bool isUploading = _formData['${field.id}_uploading'] ?? false;
        String? fileUrl = _formData[field.id];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUploading
                  ? AppColors.accentGreen
                  : (fileUrl != null
                        ? AppColors.primaryGreen
                        : AppColors.grey200),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fileUrl != null
                      ? AppColors.lightGreenBg
                      : AppColors.grey100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUploading
                      ? Icons.cloud_upload_rounded
                      : (fileUrl != null
                            ? Icons.check_circle_rounded
                            : Icons.file_present_rounded),
                  color: fileUrl != null
                      ? AppColors.primaryGreen
                      : AppColors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUploading
                          ? 'Sedang mengunggah...'
                          : (fileUrl != null
                                ? 'File terlampir'
                                : 'Lampirkan file'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: fileUrl != null
                            ? AppColors.primaryGreen
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (fileUrl != null && !isUploading)
                      Text(
                        fileUrl.split('/').last,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (!isUploading)
                      const Text(
                        'Format: PDF, JPG, PNG (Maks. 5MB)',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isUploading)
                TextButton(
                  onPressed: () => _handleFileUpload(field.id),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(fileUrl != null ? 'Ganti' : 'Pilih'),
                ),
              if (isUploading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGreen,
                  ),
                ),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Tipe field ${field.fieldType} belum didukung',
            style: const TextStyle(color: Colors.red),
          ),
        );
    }
  }

  Future<void> _handleFileUpload(String fieldId) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        setState(() {
          _formData['${fieldId}_uploading'] = true;
        });

        final publicUrl = await _apiService.uploadFile(
          result.files.single.path!,
        );

        setState(() {
          _formData[fieldId] = publicUrl;
          _formData['${fieldId}_uploading'] = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File berhasil diunggah!'),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _formData['${fieldId}_uploading'] = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal unggah: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  List<String> _getOptions(CompetitionFormField field) {
    if (field.options == null) return [];
    if (field.options is List) {
      return (field.options as List).map((o) => o.toString()).toList();
    }
    if (field.options is String) {
      try {
        final decoded = json.decode(field.options);
        if (decoded is List) return decoded.map((o) => o.toString()).toList();
      } catch (_) {
        return (field.options as String)
            .split(',')
            .map((e) => e.trim())
            .toList();
      }
    }
    return [];
  }

  InputDecoration _inputDecoration(CompetitionFormField field) {
    return InputDecoration(
      hintText: 'Misal: John Doe',
      hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
    );
  }

  String? _validate(dynamic value, CompetitionFormField field) {
    if (field.isRequired && (value == null || value.toString().isEmpty)) {
      return '${field.label} wajib diisi';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    try {
      final answers = widget.competition.formFields
          .where(
            (field) =>
                _formData.containsKey(field.id) && _formData[field.id] != null,
          )
          .map(
            (field) => RegistrationAnswer(
              fieldId: field.id,
              value: _formData[field.id],
            ),
          )
          .toList();

      final registration = Registration(
        studentId: widget.studentId,
        answers: answers,
      );

      final success = await _apiService.registerCompetition(
        widget.competition.id,
        registration,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pendaftaran berhasil terkirim!'),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Gagal mengirim pendaftaran');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
