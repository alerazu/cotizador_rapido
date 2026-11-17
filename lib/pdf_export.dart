import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'models.dart';
import 'store.dart';

Future<Uint8List> buildQuotePdf(QuoteStore st, {String number = '', DateTime? date}) async {
  final s = st.settings, t = st.totals;
  final id = countries[s.country]!.idLabel;
  const accent = PdfColor.fromInt(0xFF0E6B58);
  const muted = PdfColor.fromInt(0xFF5C6B65);

  var format = s.paper == 'a4' ? PdfPageFormat.a4 : PdfPageFormat.letter;
  if (s.paper == 'oficio') format = const PdfPageFormat(215.9 * PdfPageFormat.mm, 330.2 * PdfPageFormat.mm);
  if (s.landscape) format = format.landscape;

  final base = await _font(false), bold = await _font(true);
  final doc = pw.Document(theme: pw.ThemeData.withFont(base: base, bold: bold));

  pw.Widget party(String label, String name, List<String> meta) => pw.Expanded(
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label.toUpperCase(), style: const pw.TextStyle(fontSize: 7.5, color: muted)),
          if (name.trim().isNotEmpty) pw.Text(name.trim(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          for (final m in meta) pw.Text(m, style: const pw.TextStyle(fontSize: 9, color: muted)),
        ]),
      );

  final company = [
    if (s.companyId.trim().isNotEmpty) '$id: ${s.companyId.trim()}',
    if (s.companyAddr.trim().isNotEmpty) s.companyAddr.trim(),
    if (s.companyPhone.trim().isNotEmpty) 'Tel: ${s.companyPhone.trim()}',
    if (s.companyEmail.trim().isNotEmpty) s.companyEmail.trim(),
  ];
  final issuer = [
    if (s.issuerId.trim().isNotEmpty) '$id: ${s.issuerId.trim()}',
    if (s.issuerAddr.trim().isNotEmpty) s.issuerAddr.trim(),
  ];
  final hasCompany = s.showCompany && (s.companyName.trim().isNotEmpty || company.isNotEmpty);
  final hasIssuer = s.showIssuer && (s.issuerName.trim().isNotEmpty || issuer.isNotEmpty);

  final headers = ['Producto', 'Cant.', if (s.showUnit) 'Precio unit.', 'Total'];
  final rows = [
    for (final it in st.items)
      [it.name, st.qty(it.qty), if (s.showUnit) st.money(it.price), st.money(st.lineTotal(it))],
  ];
  final right = <int, pw.Alignment>{
    for (var i = 1; i < headers.length; i++) i: pw.Alignment.centerRight,
  };

  doc.addPage(pw.MultiPage(
    pageFormat: format,
    margin: const pw.EdgeInsets.all(42),
    build: (_) => [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(s.pdfTitle.trim().isEmpty ? 'Cotización' : s.pdfTitle.trim(),
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: accent)),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          if (number.trim().isNotEmpty) pw.Text('N° ${number.trim()}'),
          if (date != null)
            pw.Text('Fecha: ${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}'),
        ]),
      ]),
      pw.Divider(color: accent, thickness: 1.5),
      if (hasCompany || hasIssuer) ...[
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (hasCompany) party('Empresa', s.companyName, company),
          if (hasCompany && hasIssuer) pw.SizedBox(width: 20),
          if (hasIssuer) party('Cotizante', s.issuerName, issuer),
        ]),
        pw.SizedBox(height: 12),
      ],
      pw.Text(
          'Precios ${s.pricesIncludeTax ? 'con ${st.taxLabel} incluido' : 'sin ${st.taxLabel}'}  ·  Moneda: ${s.currency}',
          style: const pw.TextStyle(fontSize: 9, color: muted)),
      pw.SizedBox(height: 6),
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: accent),
        cellAlignments: right,
        headerAlignments: right,
        border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.grey300)),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      ),
      pw.SizedBox(height: 10),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.SizedBox(
          width: 220,
          child: pw.Column(children: [
            if (s.showTax) ...[
              _kv('Neto', st.money(t.net)),
              _kv('${st.taxLabel} ${st.rateText}%', st.money(t.tax)),
              pw.Divider(color: PdfColors.grey400),
            ],
            _kv(s.taxRate > 0 ? 'Total con ${st.taxLabel}' : 'Total', st.money(t.total), big: true),
          ]),
        ),
      ),
      if (s.pdfNotes.trim().isNotEmpty) ...[
        pw.SizedBox(height: 18),
        pw.Text('Observaciones', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(s.pdfNotes.trim(), style: const pw.TextStyle(fontSize: 9, color: muted)),
      ],
    ],
  ));
  return doc.save();
}

pw.Widget _kv(String k, String v, {bool big = false}) {
  final style = pw.TextStyle(fontWeight: big ? pw.FontWeight.bold : null, fontSize: big ? 14 : 10);
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(k, style: style), pw.Text(v, style: style)]),
  );
}

// Fuentes estándar de PDF no cubren acentos/€ de forma fiable; Printing trae Open Sans vía Google Fonts.
Future<pw.Font> _font(bool bold) async {
  // Import diferido para no cargar red en tests.
  return bold ? pw.Font.helveticaBold() : pw.Font.helvetica();
}
