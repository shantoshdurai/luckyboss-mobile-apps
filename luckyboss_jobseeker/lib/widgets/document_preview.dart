import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/uploaded_document.dart';
import '../services/document_service.dart';

/// Shows an uploaded file back to the candidate.
///
/// Worth having rather than a filename alone: the commonest upload mistake is a
/// photo of the wrong card, or one so blurred the number cannot be read, and
/// nobody discovers that until the agency rejects it days later. Being able to
/// look at what was sent turns a rejection into something the candidate could
/// have caught themselves.
///
/// PDFs are named and sized rather than rendered — a viewer is a dependency
/// this app does not need, and the file has already been accepted by then.
class DocumentPreview extends StatelessWidget {
  final UploadedDocument document;

  const DocumentPreview({super.key, required this.document});

  static Future<void> open(BuildContext context, UploadedDocument document) =>
      showDialog<void>(
        context: context,
        builder: (_) => DocumentPreview(document: document),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(document.label.isEmpty ? document.fileName : document.label,
                style: AppTheme.sansBold(
                    fontSize: 16, color: AppTheme.inkOf(context))),
            const SizedBox(height: 4),
            Text('${document.status.label} · ${document.sizeDisplay}',
                style: AppTheme.sansRegular(
                    fontSize: 12.5, color: AppTheme.inkMutedOf(context))),
            if (document.reviewNote != null) ...[
              const SizedBox(height: 8),
              Text(document.reviewNote!,
                  style: AppTheme.sansMedium(
                      fontSize: 12.5, color: AppTheme.signalClosed)),
            ],
            const SizedBox(height: 14),
            Flexible(child: _body(context)),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close',
                    style: AppTheme.sansBold(
                        fontSize: 14, color: AppTheme.signalSource)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (!document.isImage) return _fileCard(context);

    return FutureBuilder<String?>(
      future: DocumentService.bytesFor(document.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final bytes = DocumentService.bytesFromDataUri(snapshot.data);
        if (bytes == null) return _fileCard(context);

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, fit: BoxFit.contain),
        );
      },
    );
  }

  Widget _fileCard(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgPaper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Icon(
              document.isPdf
                  ? Icons.picture_as_pdf_rounded
                  : Icons.insert_drive_file_outlined,
              size: 30,
              color: AppTheme.signalClosed,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(document.fileName,
                  style: AppTheme.sansSemiBold(
                      fontSize: 13, color: AppTheme.inkOf(context))),
            ),
          ],
        ),
      );
}
