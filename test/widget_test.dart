import 'package:cotizador_app/models.dart';
import 'package:cotizador_app/store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IVA incluido separa el neto', () {
    final st = QuoteStore();
    st.items.add(Item(id: '1', name: 'x', qty: 2, price: 5950));
    final t = st.totals;
    expect(t.total, 11900);
    expect(t.net, 10000);
    expect(t.tax, 1900);
  });

  test('IVA no incluido suma la tasa', () {
    final st = QuoteStore();
    st.settings.pricesIncludeTax = false;
    st.items.add(Item(id: '1', name: 'x', qty: 1, price: 10000));
    expect(st.totals.total, 11900);
  });
}
