import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class QuoteStore extends ChangeNotifier {
  static const _key = 'cotizador-app-v1';

  final List<Item> items = [];
  final Settings settings = Settings();
  bool isExample = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final d = jsonDecode(raw) as Map<String, dynamic>;
        items.addAll((d['items'] as List).map((e) => Item.fromJson(e as Map<String, dynamic>)));
        settings.load((d['settings'] as Map?)?.cast<String, dynamic>() ?? {});
        isExample = d['isExample'] == true;
        notifyListeners();
        return;
      } catch (_) {}
    }
    items.addAll([
      Item(id: _uid(), name: 'Cemento 25 kg', qty: 10, price: 5490),
      Item(id: _uid(), name: 'Fierro 8 mm x 12 m', qty: 24, price: 4290),
      Item(id: _uid(), name: 'Pino cepillado 2x4', qty: 18, price: 3150),
    ]);
    isExample = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({
      'items': items.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
      'isExample': isExample,
    }));
  }

  /// Cambia algo y persiste.
  void update(void Function() fn) {
    fn();
    notifyListeners();
    _save();
  }

  static String _uid() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36) + math.Random().nextInt(1 << 20).toRadixString(36);

  void addItem(String name, double qty, double price) =>
      update(() => items.add(Item(id: _uid(), name: name, qty: qty, price: price)));

  void removeItem(Item it) => update(() {
        items.remove(it);
        if (items.isEmpty) isExample = false;
      });

  void clearAll() => update(() {
        items.clear();
        isExample = false;
      });

  // ---- formato y cálculos ----
  int get decimals => currencyFormat.decimalDigits ?? 0;

  NumberFormat get currencyFormat => NumberFormat.currency(
      locale: currencies[settings.currency]!.$2, name: settings.currency, symbol: _symbol);

  String get _symbol => NumberFormat.simpleCurrency(
          locale: currencies[settings.currency]!.$2, name: settings.currency)
      .currencySymbol;

  String money(num n) => currencyFormat.format(n);
  String qty(num n) => NumberFormat('#,##0.###', currencies[settings.currency]!.$2).format(n);

  double round(double n) {
    final f = math.pow(10, decimals).toDouble();
    return (n * f).roundToDouble() / f;
  }

  double lineTotal(Item it) => round(it.qty * it.price);

  Totals get totals {
    final sum = round(items.fold(0.0, (a, it) => a + lineTotal(it)));
    final rate = settings.taxRate / 100;
    if (settings.pricesIncludeTax) {
      final net = round(sum / (1 + rate));
      return Totals(net, round(sum - net), sum);
    }
    final tax = round(sum * rate);
    return Totals(sum, tax, round(sum + tax));
  }

  String get taxLabel => settings.taxName.trim().isEmpty ? 'Impuesto' : settings.taxName.trim();
  String get rateText => settings.taxRate.toString().replaceAll(RegExp(r'\.0$'), '').replaceAll('.', ',');

  String summaryText() {
    final s = settings, t = totals, id = countries[s.country]!.idLabel;
    final l = <String>['Cotización'];
    void add(String label, String v) {
      if (v.trim().isNotEmpty) l.add('$label: ${v.trim()}');
    }
    add('Empresa', s.companyName); add(id, s.companyId); add('Dirección', s.companyAddr);
    add('Teléfono', s.companyPhone); add('Correo', s.companyEmail);
    add('Cotizante', s.issuerName); add(id, s.issuerId); add('Dirección', s.issuerAddr);
    l.add('Precios ${s.pricesIncludeTax ? 'con $taxLabel incluido' : 'sin $taxLabel'} (${s.currency})');
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      l.add('${i + 1}. ${it.name}: ${qty(it.qty)} x ${money(it.price)} = ${money(lineTotal(it))}');
    }
    l.add('Neto: ${money(t.net)}');
    l.add('$taxLabel $rateText%: ${money(t.tax)}');
    l.add('${s.taxRate > 0 ? 'Total con $taxLabel' : 'Total'}: ${money(t.total)}');
    return l.join('\n');
  }
}
