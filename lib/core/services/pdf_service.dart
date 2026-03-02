import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../../shared/models/prescription_model.dart';
import '../../shared/models/patient_model.dart';

/// Service for generating and printing prescription PDFs.
class PdfService {
  const PdfService._();

  /// Generate a prescription PDF and return it as bytes.
  static Future<List<int>> generatePrescription({
    required PrescriptionModel prescription,
    required PatientModel patient,
  }) async {
    final doc = pw.Document();

    final tealColor = PdfColor.fromHex('#00D2B4');
    final darkColor = PdfColor.fromHex('#060C18');
    final cardColor = PdfColor.fromHex('#111E35');
    final textColor = PdfColor.fromHex('#E2EAF8');
    final subTextColor = PdfColor.fromHex('#6B7FA3');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.outfitRegular(),
          bold: await PdfGoogleFonts.outfitBold(),
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: darkColor,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        AppConstants.clinicName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: tealColor,
                        ),
                      ),
                      pw.Text(
                        AppConstants.clinicCity,
                        style: pw.TextStyle(color: subTextColor, fontSize: 12),
                      ),
                      pw.Text(
                        AppConstants.clinicPhone,
                        style: pw.TextStyle(color: subTextColor, fontSize: 11),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'PRESCRIPTION',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: tealColor,
                        ),
                      ),
                      pw.Text(
                        AppFormatters.dateShort(prescription.createdAt),
                        style: pw.TextStyle(color: textColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Patient info
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: cardColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Patient',
                            style: pw.TextStyle(
                                color: subTextColor, fontSize: 10)),
                        pw.Text(patient.fullName,
                            style: pw.TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold)),
                        pw.Text(patient.patientCode,
                            style: pw.TextStyle(
                                color: tealColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (patient.dateOfBirth != null)
                        pw.Text(
                          'Age: ${AppFormatters.age(patient.dateOfBirth)}',
                          style: pw.TextStyle(color: textColor, fontSize: 12),
                        ),
                      pw.Text(
                        patient.gender,
                        style: pw.TextStyle(color: textColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Chief complaint & Diagnosis
            if (prescription.chiefComplaint != null) ...[
              _pdfSection(
                  'Chief Complaint', prescription.chiefComplaint!, textColor, subTextColor),
              pw.SizedBox(height: 12),
            ],
            if (prescription.diagnosis != null) ...[
              _pdfSection(
                  'Diagnosis', prescription.diagnosis!, textColor, subTextColor),
              pw.SizedBox(height: 12),
            ],

            // Remedies table
            pw.Text('Prescribed Remedies',
                style: pw.TextStyle(
                    color: tealColor,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#1E2F4A'),
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: darkColor),
                  children: [
                    _tableHeader('Remedy', textColor),
                    _tableHeader('Potency', textColor),
                    _tableHeader('Dose', textColor),
                    _tableHeader('Frequency', textColor),
                    _tableHeader('Duration', textColor),
                  ],
                ),
                // Data rows
                ...prescription.remedies.asMap().entries.map((entry) {
                  final r = entry.value;
                  final isEven = entry.key % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? cardColor : darkColor,
                    ),
                    children: [
                      _tableCell(r.remedyName, textColor),
                      _tableCell(r.potency, textColor),
                      _tableCell(r.dose, textColor),
                      _tableCell(r.frequency, textColor),
                      _tableCell(r.duration, textColor),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),

            // Follow-up
            if (prescription.followUpDate != null)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#33DCC315'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Text('Follow-up: ',
                        style: pw.TextStyle(
                            color: tealColor,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12)),
                    pw.Text(
                      AppFormatters.dateShort(prescription.followUpDate),
                      style: pw.TextStyle(color: textColor, fontSize: 12),
                    ),
                  ],
                ),
              ),

            if (prescription.notes != null) ...[
              pw.SizedBox(height: 12),
              _pdfSection('Doctor\'s Notes', prescription.notes!, textColor, subTextColor),
            ],

            pw.Spacer(),

            // Signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                        width: 120, height: 1,
                        color: subTextColor),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      prescription.doctorName ?? 'Doctor',
                      style: pw.TextStyle(color: textColor, fontSize: 11),
                    ),
                    pw.Text('Homeopathic Physician',
                        style: pw.TextStyle(
                            color: subTextColor, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _pdfSection(
      String label, String value, PdfColor text, PdfColor sub) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(color: sub, fontSize: 10)),
        pw.Text(value,
            style: pw.TextStyle(color: text, fontSize: 13)),
      ],
    );
  }

  static pw.Widget _tableHeader(String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          style: pw.TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _tableCell(String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          style: pw.TextStyle(color: color, fontSize: 10)),
    );
  }

  /// Print / share the prescription PDF.
  static Future<void> printOrShare(List<int> bytes, String title) async {
    await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: title);
  }

  /// Preview the prescription PDF on device.
  static Future<void> previewPdf(List<int> bytes) async {
    await Printing.layoutPdf(onLayout: (_) => Uint8List.fromList(bytes));
  }
}

/// Riverpod provider.
final pdfServiceProvider = Provider<PdfService>((_) => const PdfService._());

