import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:printing/printing.dart';

import 'models.dart';
import 'pdf_export.dart';
import 'settings_page.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final store = QuoteStore();
  await store.load();
  runApp(CotizadorApp(store: store));
}

class CotizadorApp extends StatelessWidget {
  const CotizadorApp({super.key, required this.store});
  final QuoteStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cotizador',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0E6B58), useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: const Color(0xFF4FC2A5), brightness: Brightness.dark, useMaterial3: true),
      home: HomePage(store: store),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store});
  final QuoteStore store;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _name = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _price = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Item? _editing;

  QuoteStore get st => widget.store;

  @override
  void dispose() {
    _name.dispose(); _qty.dispose(); _price.dispose();
    super.dispose();
  }

  double? _num(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  void _resetForm() {
    _name.clear(); _qty.text = '1'; _price.clear();
    _editing = null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final q = _num(_qty.text)!, p = _num(_price.text)!;
    if (_editing != null) {
      final it = _editing!;
      st.update(() { it.name = _name.text.trim(); it.qty = q; it.price = p; });
    } else {
      st.addItem(_name.text.trim(), q, p);
    }
    setState(_resetForm);
  }

  void _startEdit(Item it) {
    setState(() {
      _editing = it;
      _name.text = it.name;
      _qty.text = it.qty.toString().replaceAll(RegExp(r'\.0$'), '');
      _price.text = it.price.toString().replaceAll(RegExp(r'\.0$'), '');
    });
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 2)));

  Future<void> _exportPdf() async {
    final bytes = await buildQuotePdf(st, date: DateTime.now());
    await Printing.sharePdf(bytes: bytes, filename: 'cotizacion.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: st,
      builder: (context, _) {
        final s = st.settings, t = st.totals, cs = Theme.of(context).colorScheme;
        final id = countries[s.country]!.idLabel;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cotizador'),
            actions: [
              IconButton(
                tooltip: 'Configuración y datos',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => SettingsPage(store: st))),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (s.companyName.trim().isNotEmpty)
                    _Party('Mi empresa', s.companyName, [
                      if (s.companyId.trim().isNotEmpty) '$id ${s.companyId.trim()}',
                      if (s.companyAddr.trim().isNotEmpty) s.companyAddr.trim(),
                    ]),
                  if (s.issuerName.trim().isNotEmpty)
                    _Party('Cotizante', s.issuerName, [
                      if (s.issuerId.trim().isNotEmpty) '$id ${s.issuerId.trim()}',
                      if (s.issuerAddr.trim().isNotEmpty) s.issuerAddr.trim(),
                    ]),
                  const Text('Los precios que anotas'),
                  const SizedBox(height: 6),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: true, label: Text('Incluyen ${st.taxLabel}')),
                      ButtonSegment(value: false, label: Text('No incluyen ${st.taxLabel}')),
                    ],
                    selected: {s.pricesIncludeTax},
                    onSelectionChanged: (v) => st.update(() => s.pricesIncludeTax = v.first),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Form(
                        key: _formKey,
                        child: Column(children: [
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(labelText: 'Producto', hintText: 'Ej: Cemento 25 kg'),
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe el nombre del producto.' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _qty,
                                decoration: const InputDecoration(labelText: 'Cantidad'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                validator: (v) {
                                  final n = _num(v ?? '');
                                  return n == null || n <= 0 ? 'Cantidad > 0' : null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _price,
                                decoration: const InputDecoration(labelText: 'Precio unitario'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                onFieldSubmitted: (_) => _submit(),
                                validator: (v) => _num(v ?? '') == null ? 'Ingresa el precio' : null,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _submit,
                              child: Text(_editing == null ? 'Agregar' : 'Guardar cambios'),
                            ),
                          ),
                          if (_editing != null)
                            TextButton(
                                onPressed: () => setState(_resetForm), child: const Text('Cancelar edición')),
                        ]),
                      ),
                    ),
                  ),
                  if (st.isExample && st.items.isNotEmpty)
                    Card(
                      color: cs.secondaryContainer,
                      child: ListTile(
                        title: const Text('Estos productos son de ejemplo. Vacía la lista para empezar.'),
                        trailing: TextButton(onPressed: st.clearAll, child: const Text('Vaciar')),
                      ),
                    ),
                  Row(children: [
                    Expanded(
                        child: Text(st.items.isEmpty ? 'PRODUCTOS' : 'PRODUCTOS (${st.items.length})',
                            style: Theme.of(context).textTheme.labelLarge)),
                    TextButton(
                      onPressed: st.items.isEmpty
                          ? null
                          : () async {
                              await Clipboard.setData(ClipboardData(text: st.summaryText()));
                              _snack('Resumen copiado');
                            },
                      child: const Text('Copiar resumen'),
                    ),
                    TextButton(
                      onPressed: st.items.isEmpty ? null : st.clearAll,
                      child: Text('Vaciar', style: TextStyle(color: cs.error)),
                    ),
                  ]),
                  if (st.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: Text('Aún no hay productos. Agrega el primero arriba.')),
                    )
                  else
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(children: [
                        for (final it in st.items)
                          ListTile(
                            selected: it == _editing,
                            title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${st.qty(it.qty)} × ${st.money(it.price)}'),
                            onTap: () => _startEdit(it),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(st.money(st.lineTotal(it)),
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              IconButton(
                                tooltip: 'Quitar ${it.name}',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  if (_editing == it) setState(_resetForm);
                                  st.removeItem(it);
                                },
                              ),
                            ]),
                          ),
                      ]),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: st.items.isEmpty ? null : _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Exportar PDF'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Material(
            elevation: 8,
            child: SafeArea(
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _row('Neto', st.money(t.net), small: true),
                      _row('${st.taxLabel} ${st.rateText}%', st.money(t.tax), small: true),
                      const Divider(height: 14),
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.taxRate > 0 ? 'TOTAL CON ${st.taxLabel.toUpperCase()}' : 'TOTAL',
                                style: Theme.of(context).textTheme.labelMedium),
                            Text(st.items.length == 1 ? '1 producto' : '${st.items.length} productos'),
                          ]),
                        ),
                        Text(st.money(t.total),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _row(String k, String v, {bool small = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(k), Text(v, style: const TextStyle(fontWeight: FontWeight.w600))],
      );
}

class _Party extends StatelessWidget {
  const _Party(this.label, this.name, this.meta);
  final String label, name;
  final List<String> meta;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          dense: true,
          title: Text('${label.toUpperCase()}  ·  ${name.trim()}'),
          subtitle: meta.isEmpty ? null : Text(meta.join(' · ')),
        ),
      );
}
