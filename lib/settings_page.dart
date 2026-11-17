import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store});
  final QuoteStore store;

  Settings get s => store.settings;

  Widget _text(String label, String value, void Function(String) set,
      {TextInputType? type, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        keyboardType: type,
        maxLines: lines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        onChanged: (v) => store.update(() => set(v)),
      ),
    );
  }

  Widget _h(BuildContext c, String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 10),
        child: Text(t.toUpperCase(), style: Theme.of(c).textTheme.labelLarge),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración y datos')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final id = countries[s.country]!.idLabel;
              return ListView(padding: const EdgeInsets.all(16), children: [
                DropdownButtonFormField<String>(
                  initialValue: s.country,
                  decoration: const InputDecoration(labelText: 'País', border: OutlineInputBorder()),
                  items: [
                    for (final e in countries.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value.name)),
                  ],
                  onChanged: (v) => store.update(() {
                    final c = countries[v]!;
                    s.country = v!;
                    s.currency = c.currency;
                    s.taxName = c.taxName;
                    s.taxRate = c.rate;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('cur-${s.currency}'),
                  initialValue: s.currency,
                  decoration: const InputDecoration(labelText: 'Moneda', border: OutlineInputBorder()),
                  items: [
                    for (final e in currencies.entries)
                      DropdownMenuItem(value: e.key, child: Text('${e.key} · ${e.value.$1}')),
                  ],
                  onChanged: (v) => store.update(() => s.currency = v!),
                ),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      key: ValueKey('tn-${s.country}'),
                      initialValue: s.taxName,
                      decoration: const InputDecoration(
                          labelText: 'Nombre del impuesto', border: OutlineInputBorder()),
                      onChanged: (v) => store.update(() => s.taxName = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      key: ValueKey('tr-${s.country}'),
                      initialValue: store.rateText,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Tasa %', border: OutlineInputBorder()),
                      onChanged: (v) {
                        final n = double.tryParse(v.trim().replaceAll(',', '.')) ?? 0;
                        if (n >= 0 && n <= 100) store.update(() => s.taxRate = n);
                      },
                    ),
                  ),
                ]),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Al elegir un país se cargan moneda e impuesto de referencia. '
                      'Confirma la tasa vigente y edítala si hace falta.'),
                ),
                _h(context, 'Mi empresa'),
                _text('Nombre o razón social', s.companyName, (v) => s.companyName = v),
                _text(id, s.companyId, (v) => s.companyId = v),
                _text('Dirección', s.companyAddr, (v) => s.companyAddr = v),
                _text('Teléfono', s.companyPhone, (v) => s.companyPhone = v, type: TextInputType.phone),
                _text('Correo', s.companyEmail, (v) => s.companyEmail = v, type: TextInputType.emailAddress),
                _h(context, 'Cotizante'),
                _text('Nombre o razón social', s.issuerName, (v) => s.issuerName = v),
                _text(id, s.issuerId, (v) => s.issuerId = v),
                _text('Dirección', s.issuerAddr, (v) => s.issuerAddr = v),
                _h(context, 'Formato del PDF'),
                _text('Título del documento', s.pdfTitle, (v) => s.pdfTitle = v),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: s.paper,
                      decoration: const InputDecoration(labelText: 'Papel', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'letter', child: Text('Carta')),
                        DropdownMenuItem(value: 'a4', child: Text('A4')),
                        DropdownMenuItem(value: 'oficio', child: Text('Oficio')),
                      ],
                      onChanged: (v) => store.update(() => s.paper = v!),
                    ),
                  ),
                ]),
                SwitchListTile(
                    title: const Text('Horizontal'),
                    value: s.landscape,
                    onChanged: (v) => store.update(() => s.landscape = v)),
                SwitchListTile(
                    title: const Text('Datos de mi empresa'),
                    value: s.showCompany,
                    onChanged: (v) => store.update(() => s.showCompany = v)),
                SwitchListTile(
                    title: const Text('Datos del cotizante'),
                    value: s.showIssuer,
                    onChanged: (v) => store.update(() => s.showIssuer = v)),
                SwitchListTile(
                    title: const Text('Precio unitario'),
                    value: s.showUnit,
                    onChanged: (v) => store.update(() => s.showUnit = v)),
                SwitchListTile(
                    title: const Text('Desglose de neto e impuesto'),
                    value: s.showTax,
                    onChanged: (v) => store.update(() => s.showTax = v)),
                const SizedBox(height: 8),
                _text('Observaciones o pie de página', s.pdfNotes, (v) => s.pdfNotes = v, lines: 3),
              ]);
            },
          ),
        ),
      ),
    );
  }
}
