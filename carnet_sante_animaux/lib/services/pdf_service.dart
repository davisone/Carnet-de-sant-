import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/animal.dart';

class PdfService {
  Future<void> generateCarnetSante(Animal animal, List<Animal> tousLesAnimaux) async {
    final pdf = pw.Document();

    // Trouver les parents
    final pere = animal.pereId != null
        ? tousLesAnimaux.where((a) => a.id == animal.pereId).firstOrNull
        : null;
    final mere = animal.mereId != null
        ? tousLesAnimaux.where((a) => a.id == animal.mereId).firstOrNull
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // En-tête
            _buildHeader(animal),
            pw.SizedBox(height: 20),

            // Informations générales
            _buildSection('Informations générales', [
              _buildInfoRow('Nom', animal.nom),
              _buildInfoRow('Espèce', animal.espece),
              _buildInfoRow('Race', animal.race),
              _buildInfoRow(
                'Date de naissance',
                DateFormat('dd/MM/yyyy').format(animal.dateNaissance),
              ),
              _buildInfoRow('Âge', animal.ageComplet),
              if (animal.sexe != null) _buildInfoRow('Sexe', animal.sexe!),
              if (animal.couleur != null)
                _buildInfoRow('Couleur', animal.couleur!),
              if (animal.numeroIdentification != null)
                _buildInfoRow('N° Identification', animal.numeroIdentification!),
              if (pere != null) _buildInfoRow('Père', pere.nom),
              if (mere != null) _buildInfoRow('Mère', mere.nom),
            ]),
            pw.SizedBox(height: 20),

            // Poids (pour les bébés)
            if (animal.historiquePoids.isNotEmpty) ...[
              _buildSection('Suivi du poids', [
                _buildPoidsTable(animal.historiquePoids),
              ]),
              pw.SizedBox(height: 20),
            ],

            // Traitements
            if (animal.traitements.isNotEmpty) ...[
              _buildSection('Traitements', [
                _buildTraitementsTable(animal.traitements),
              ]),
              pw.SizedBox(height: 20),
            ],

            // Vaccins
            if (animal.vaccins.isNotEmpty) ...[
              _buildSection('Vaccins', [
                _buildVaccinsTable(animal.vaccins),
              ]),
              pw.SizedBox(height: 20),
            ],

            // Consultations
            if (animal.consultations.isNotEmpty) ...[
              _buildSection('Consultations vétérinaires', [
                _buildConsultationsTable(animal.consultations),
              ]),
              pw.SizedBox(height: 20),
            ],

            // Maladies
            if (animal.maladies.isNotEmpty) ...[
              _buildSection('Maladies', [
                _buildMaladiesTable(animal.maladies),
              ]),
              pw.SizedBox(height: 20),
            ],

            // Notes
            if (animal.notes != null && animal.notes!.isNotEmpty) ...[
              _buildSection('Notes', [
                pw.Text(animal.notes!),
              ]),
            ],

            // Pied de page
            pw.Spacer(),
            _buildFooter(),
          ];
        },
      ),
    );

    // Afficher le PDF ou le sauvegarder
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'carnet_sante_${animal.nom}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  pw.Widget _buildHeader(Animal animal) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Carnet de Santé',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.teal,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          animal.nom,
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          '${animal.espece} - ${animal.race}',
          style: const pw.TextStyle(
            fontSize: 14,
            color: PdfColors.grey700,
          ),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: PdfColors.teal50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal900,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        ...children,
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label :',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPoidsTable(List<MesurePoids> mesures) {
    final mesuresTriees = mesures.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
      },
      children: [
        // En-tête
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Poids (kg)', isHeader: true),
            _buildTableCell('Notes', isHeader: true),
          ],
        ),
        // Données
        ...mesuresTriees.map((mesure) => pw.TableRow(
              children: [
                _buildTableCell(DateFormat('dd/MM/yyyy').format(mesure.date)),
                _buildTableCell(mesure.poids.toString()),
                _buildTableCell(mesure.notes ?? '-'),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildTraitementsTable(List<Traitement> traitements) {
    final traitementsTriees = traitements.toList()
      ..sort((a, b) => b.dateDebut.compareTo(a.dateDebut));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Traitement', isHeader: true),
            _buildTableCell('Début', isHeader: true),
            _buildTableCell('Fin', isHeader: true),
            _buildTableCell('Posologie', isHeader: true),
          ],
        ),
        ...traitementsTriees.map((t) => pw.TableRow(
              children: [
                _buildTableCell(t.nom),
                _buildTableCell(DateFormat('dd/MM/yy').format(t.dateDebut)),
                _buildTableCell(t.dateFin != null
                    ? DateFormat('dd/MM/yy').format(t.dateFin!)
                    : 'En cours'),
                _buildTableCell(t.posologie),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildVaccinsTable(List<Vaccin> vaccins) {
    final vaccinsTriees = vaccins.toList()
      ..sort((a, b) => b.dateAdministration.compareTo(a.dateAdministration));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Vaccin', isHeader: true),
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Rappel', isHeader: true),
            _buildTableCell('Vétérinaire', isHeader: true),
          ],
        ),
        ...vaccinsTriees.map((v) => pw.TableRow(
              children: [
                _buildTableCell(v.nom),
                _buildTableCell(
                    DateFormat('dd/MM/yy').format(v.dateAdministration)),
                _buildTableCell(v.dateRappel != null
                    ? DateFormat('dd/MM/yy').format(v.dateRappel!)
                    : '-'),
                _buildTableCell(v.veterinaire ?? '-'),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildConsultationsTable(List<ConsultationVeterinaire> consultations) {
    final consultationsTriees = consultations.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Motif', isHeader: true),
            _buildTableCell('Diagnostic', isHeader: true),
            _buildTableCell('Vétérinaire', isHeader: true),
          ],
        ),
        ...consultationsTriees.map((c) => pw.TableRow(
              children: [
                _buildTableCell(DateFormat('dd/MM/yy').format(c.date)),
                _buildTableCell(c.motif),
                _buildTableCell(c.diagnostic),
                _buildTableCell(c.veterinaire),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildMaladiesTable(List<Maladie> maladies) {
    final maladiesTriees = maladies.toList()
      ..sort((a, b) => b.dateDiagnostic.compareTo(a.dateDiagnostic));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Maladie', isHeader: true),
            _buildTableCell('Diagnostic', isHeader: true),
            _buildTableCell('Statut', isHeader: true),
            _buildTableCell('Guérison', isHeader: true),
          ],
        ),
        ...maladiesTriees.map((m) => pw.TableRow(
              children: [
                _buildTableCell(m.nom),
                _buildTableCell(DateFormat('dd/MM/yy').format(m.dateDiagnostic)),
                _buildTableCell(m.estGuerite
                    ? 'Guérie'
                    : (m.estChronique ? 'Chronique' : 'Active')),
                _buildTableCell(m.dateGuerison != null
                    ? DateFormat('dd/MM/yy').format(m.dateGuerison!)
                    : '-'),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Document généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'Carnet de Santé Animaux',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }
}
