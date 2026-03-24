import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CatalogErrorDialog extends StatelessWidget {
  const CatalogErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.operation = '',
    this.onCopy,
    this.onReport,
  });

  final String title;
  final String message;
  final String operation;
  final VoidCallback? onCopy;
  final VoidCallback? onReport;

  static const String _githubRepoUrl = 'https://github.com/anasoid/anas_localization/issues/new';

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String operation = '',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => CatalogErrorDialog(
        title: title,
        message: message,
        operation: operation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final encodedMessage = Uri.encodeComponent('[$operation] $message');
    final issueUrl = '$_githubRepoUrl?body=$encodedMessage';

    return AlertDialog(
      icon: Icon(
        Icons.error_outline,
        color: theme.colorScheme.error,
        size: 48,
      ),
      title: Text(title),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: SelectableText(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: '[$operation] $message'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
            onCopy?.call();
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy'),
        ),
        TextButton.icon(
          onPressed: () {
            // Open browser to report issue
            // In a real app, you'd use url_launcher
            // For now, we'll copy the URL to clipboard
            Clipboard.setData(ClipboardData(text: issueUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Issue URL copied to clipboard'),
                action: SnackBarAction(
                  label: 'OK',
                  onPressed: () {},
                ),
              ),
            );
            onReport?.call();
          },
          icon: const Icon(Icons.bug_report),
          label: const Text('Report Issue'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class CatalogSavingToast {
  static void show(BuildContext context, {String message = 'Saving...'}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, {String message = 'Saved!'}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showError(BuildContext context, {required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Details',
          textColor: Colors.white,
          onPressed: () {
            CatalogErrorDialog.show(context, title: 'Error', message: message);
          },
        ),
      ),
    );
  }
}
