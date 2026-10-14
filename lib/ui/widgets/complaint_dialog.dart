import 'package:flutter/material.dart';

/// Result returned by [ComplaintDialog].
class ComplaintResult {
  final String subject;
  final String description;
  const ComplaintResult(this.subject, this.description);
}

/// Reusable dialog to capture a complaint's subject and description.
class ComplaintDialog extends StatefulWidget {
  const ComplaintDialog({super.key, this.title = 'Raise Complaint'});

  final String title;

  @override
  State<ComplaintDialog> createState() => _ComplaintDialogState();
}

class _ComplaintDialogState extends State<ComplaintDialog> {
  final _subject = TextEditingController();
  final _description = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _subject,
            decoration: InputDecoration(
              labelText: 'Subject',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_subject.text.trim().isEmpty) {
              setState(() => _error = 'Subject is required');
              return;
            }
            Navigator.pop(
              context,
              ComplaintResult(
                  _subject.text.trim(), _description.text.trim()),
            );
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
