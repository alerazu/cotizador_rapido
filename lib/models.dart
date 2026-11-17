class Country {
  final String name, currency, taxName, idLabel;
  final double rate;
  const Country(this.name, this.currency, this.taxName, this.rate, this.idLabel);
}

/// Valores de referencia por país (el usuario puede editarlos).
const countries = <String, Country>{
  'CL': Country('Chile', 'CLP', 'IVA', 19, 'RUT'),
  'AR': Country('Argentina', 'ARS', 'IVA', 21, 'CUIT'),
  'BO': Country('Bolivia', 'BOB', 'IVA', 13, 'NIT'),
  'CO': Country('Colombia', 'COP', 'IVA', 19, 'NIT'),
  'ES': Country('España', 'EUR', 'IVA', 21, 'NIF'),
  'US': Country('Estados Unidos', 'USD', 'Sales tax', 0, 'Tax ID'),
  'MX': Country('México', 'MXN', 'IVA', 16, 'RFC'),
  'PY': Country('Paraguay', 'PYG', 'IVA', 10, 'RUC'),
  'PE': Country('Perú', 'PEN', 'IGV', 18, 'RUC'),
  'UY': Country('Uruguay', 'UYU', 'IVA', 22, 'RUT'),
};

/// código -> (nombre, locale)
const currencies = <String, (String, String)>{
  'ARS': ('Peso argentino', 'es_AR'),
  'BOB': ('Boliviano', 'es_BO'),
  'BRL': ('Real brasileño', 'pt_BR'),
  'CLP': ('Peso chileno', 'es_CL'),
  'COP': ('Peso colombiano', 'es_CO'),
  'EUR': ('Euro', 'es_ES'),
  'GBP': ('Libra esterlina', 'en_GB'),
  'MXN': ('Peso mexicano', 'es_MX'),
  'PEN': ('Sol peruano', 'es_PE'),
  'PYG': ('Guaraní', 'es_PY'),
  'USD': ('Dólar estadounidense', 'en_US'),
  'UYU': ('Peso uruguayo', 'es_UY'),
};

class Item {
  final String id;
  String name;
  double qty, price;
  Item({required this.id, required this.name, required this.qty, required this.price});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'qty': qty, 'price': price};
  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] as String,
        name: j['name'] as String,
        qty: (j['qty'] as num).toDouble(),
        price: (j['price'] as num).toDouble(),
      );
}

class Settings {
  String country = 'CL', currency = 'CLP', taxName = 'IVA';
  double taxRate = 19;
  bool pricesIncludeTax = true;
  String companyName = '', companyId = '', companyAddr = '', companyPhone = '', companyEmail = '';
  String issuerName = '', issuerId = '', issuerAddr = '';
  // PDF
  String pdfTitle = 'Cotización', pdfNotes = '', paper = 'letter';
  bool landscape = false, showCompany = true, showIssuer = true, showUnit = true, showTax = true;

  Map<String, dynamic> toJson() => {
        'country': country, 'currency': currency, 'taxName': taxName, 'taxRate': taxRate,
        'pricesIncludeTax': pricesIncludeTax,
        'companyName': companyName, 'companyId': companyId, 'companyAddr': companyAddr,
        'companyPhone': companyPhone, 'companyEmail': companyEmail,
        'issuerName': issuerName, 'issuerId': issuerId, 'issuerAddr': issuerAddr,
        'pdfTitle': pdfTitle, 'pdfNotes': pdfNotes, 'paper': paper, 'landscape': landscape,
        'showCompany': showCompany, 'showIssuer': showIssuer, 'showUnit': showUnit, 'showTax': showTax,
      };

  void load(Map<String, dynamic> j) {
    T g<T>(String k, T d) => j[k] is T ? j[k] as T : d;
    country = countries.containsKey(j['country']) ? j['country'] as String : country;
    currency = currencies.containsKey(j['currency']) ? j['currency'] as String : currency;
    taxName = g('taxName', taxName);
    taxRate = (j['taxRate'] as num?)?.toDouble() ?? taxRate;
    pricesIncludeTax = g('pricesIncludeTax', pricesIncludeTax);
    companyName = g('companyName', ''); companyId = g('companyId', '');
    companyAddr = g('companyAddr', ''); companyPhone = g('companyPhone', '');
    companyEmail = g('companyEmail', '');
    issuerName = g('issuerName', ''); issuerId = g('issuerId', ''); issuerAddr = g('issuerAddr', '');
    pdfTitle = g('pdfTitle', pdfTitle); pdfNotes = g('pdfNotes', ''); paper = g('paper', paper);
    landscape = g('landscape', false);
    showCompany = g('showCompany', true); showIssuer = g('showIssuer', true);
    showUnit = g('showUnit', true); showTax = g('showTax', true);
  }
}

class Totals {
  final double net, tax, total;
  const Totals(this.net, this.tax, this.total);
}
