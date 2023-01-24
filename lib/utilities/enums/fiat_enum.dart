enum Fiats {
  AED,
  AFN,
  ALL,
  AMD,
  ANG,
  AOA,
  ARS,
  AUD,
  AWG,
  AZN,
  BAM,
  BBD,
  BDT,
  BGN,
  BHD,
  BIF,
  BMD,
  BND,
  BOB,
  BRL,
  BSD,
  BTN,
  BWP,
  BYN,
  BZD,
  CAD,
  CDF,
  CHF,
  CLP,
  CNY,
  COP,
  CRC,
  CUC,
  CUP,
  CVE,
  CZK,
  DJF,
  DKK,
  DOP,
  DZD,
  EGP,
  ERN,
  ETB,
  EUR,
  FJD,
  FKP,
  GBP,
  GEL,
  GGP,
  GHS,
  GIP,
  GMD,
  GNF,
  GTQ,
  GYD,
  HKD,
  HNL,
  HRK,
  HTG,
  HUF,
  IDR,
  ILS,
  IMP,
  INR,
  IQD,
  IRR,
  ISK,
  JEP,
  JMD,
  JOD,
  JPY,
  KES,
  KGS,
  KHR,
  KMF,
  KPW,
  KRW,
  KWD,
  KYD,
  KZT,
  LAK,
  LBP,
  LKR,
  LRD,
  LSL,
  LYD,
  MAD,
  MDL,
  MGA,
  MKD,
  MMK,
  MNT,
  MOP,
  MRU,
  MUR,
  MVR,
  MWK,
  MXN,
  MYR,
  MZN,
  NAD,
  NGN,
  NIO,
  NOK,
  NPR,
  NZD,
  OMR,
  PAB,
  PEN,
  PGK,
  PHP,
  PKR,
  PLN,
  PYG,
  QAR,
  RON,
  RSD,
  RUB,
  RWF,
  SAR,
  SBD,
  SCR,
  SDG,
  SEK,
  SGD,
  SHP,
  SLL,
  SOS,
  SPL,
  SRD,
  STN,
  SVC,
  SYP,
  SZL,
  THB,
  TJS,
  TMT,
  TND,
  TOP,
  TRY,
  TTD,
  TVD,
  TWD,
  TZS,
  UAH,
  UGX,
  USD,
  UYU,
  UZS,
  VEF,
  VND,
  VUV,
  WST,
  XAF,
  XCD,
  XDR,
  XOF,
  XPF,
  YER,
  ZAR,
  ZMW,
  ZWD,
}

extension FiatExt on Fiats {
  String get ticker {
    switch (this) {
      case Fiats.AED:
        return 'AED';
      case Fiats.AFN:
        return 'AFN';
      case Fiats.ALL:
        return 'ALL';
      case Fiats.AMD:
        return 'AMD';
      case Fiats.ANG:
        return 'ANG';
      case Fiats.AOA:
        return 'AOA';
      case Fiats.ARS:
        return 'ARS';
      case Fiats.AUD:
        return 'AUD';
      case Fiats.AWG:
        return 'AWG';
      case Fiats.AZN:
        return 'AZN';
      case Fiats.BAM:
        return 'BAM';
      case Fiats.BBD:
        return 'BBD';
      case Fiats.BDT:
        return 'BDT';
      case Fiats.BGN:
        return 'BGN';
      case Fiats.BHD:
        return 'BHD';
      case Fiats.BIF:
        return 'BIF';
      case Fiats.BMD:
        return 'BMD';
      case Fiats.BND:
        return 'BND';
      case Fiats.BOB:
        return 'BOB';
      case Fiats.BRL:
        return 'BRL';
      case Fiats.BSD:
        return 'BSD';
      case Fiats.BTN:
        return 'BTN';
      case Fiats.BWP:
        return 'BWP';
      case Fiats.BYN:
        return 'BYN';
      case Fiats.BZD:
        return 'BZD';
      case Fiats.CAD:
        return 'CAD';
      case Fiats.CDF:
        return 'CDF';
      case Fiats.CHF:
        return 'CHF';
      case Fiats.CLP:
        return 'CLP';
      case Fiats.CNY:
        return 'CNY';
      case Fiats.COP:
        return 'COP';
      case Fiats.CRC:
        return 'CRC';
      case Fiats.CUC:
        return 'CUC';
      case Fiats.CUP:
        return 'CUP';
      case Fiats.CVE:
        return 'CVE';
      case Fiats.CZK:
        return 'CZK';
      case Fiats.DJF:
        return 'DJF';
      case Fiats.DKK:
        return 'DKK';
      case Fiats.DOP:
        return 'DOP';
      case Fiats.DZD:
        return 'DZD';
      case Fiats.EGP:
        return 'EGP';
      case Fiats.ERN:
        return 'ERN';
      case Fiats.ETB:
        return 'ETB';
      case Fiats.EUR:
        return 'EUR';
      case Fiats.FJD:
        return 'FJD';
      case Fiats.FKP:
        return 'FKP';
      case Fiats.GBP:
        return 'GBP';
      case Fiats.GEL:
        return 'GEL';
      case Fiats.GGP:
        return 'GGP';
      case Fiats.GHS:
        return 'GHS';
      case Fiats.GIP:
        return 'GIP';
      case Fiats.GMD:
        return 'GMD';
      case Fiats.GNF:
        return 'GNF';
      case Fiats.GTQ:
        return 'GTQ';
      case Fiats.GYD:
        return 'GYD';
      case Fiats.HKD:
        return 'HKD';
      case Fiats.HNL:
        return 'HNL';
      case Fiats.HRK:
        return 'HRK';
      case Fiats.HTG:
        return 'HTG';
      case Fiats.HUF:
        return 'HUF';
      case Fiats.IDR:
        return 'IDR';
      case Fiats.ILS:
        return 'ILS';
      case Fiats.IMP:
        return 'IMP';
      case Fiats.INR:
        return 'INR';
      case Fiats.IQD:
        return 'IQD';
      case Fiats.IRR:
        return 'IRR';
      case Fiats.ISK:
        return 'ISK';
      case Fiats.JEP:
        return 'JEP';
      case Fiats.JMD:
        return 'JMD';
      case Fiats.JOD:
        return 'JOD';
      case Fiats.JPY:
        return 'JPY';
      case Fiats.KES:
        return 'KES';
      case Fiats.KGS:
        return 'KGS';
      case Fiats.KHR:
        return 'KHR';
      case Fiats.KMF:
        return 'KMF';
      case Fiats.KPW:
        return 'KPW';
      case Fiats.KRW:
        return 'KRW';
      case Fiats.KWD:
        return 'KWD';
      case Fiats.KYD:
        return 'KYD';
      case Fiats.KZT:
        return 'KZT';
      case Fiats.LAK:
        return 'LAK';
      case Fiats.LBP:
        return 'LBP';
      case Fiats.LKR:
        return 'LKR';
      case Fiats.LRD:
        return 'LRD';
      case Fiats.LSL:
        return 'LSL';
      case Fiats.LYD:
        return 'LYD';
      case Fiats.MAD:
        return 'MAD';
      case Fiats.MDL:
        return 'MDL';
      case Fiats.MGA:
        return 'MGA';
      case Fiats.MKD:
        return 'MKD';
      case Fiats.MMK:
        return 'MMK';
      case Fiats.MNT:
        return 'MNT';
      case Fiats.MOP:
        return 'MOP';
      case Fiats.MRU:
        return 'MRU';
      case Fiats.MUR:
        return 'MUR';
      case Fiats.MVR:
        return 'MVR';
      case Fiats.MWK:
        return 'MWK';
      case Fiats.MXN:
        return 'MXN';
      case Fiats.MYR:
        return 'MYR';
      case Fiats.MZN:
        return 'MZN';
      case Fiats.NAD:
        return 'NAD';
      case Fiats.NGN:
        return 'NGN';
      case Fiats.NIO:
        return 'NIO';
      case Fiats.NOK:
        return 'NOK';
      case Fiats.NPR:
        return 'NPR';
      case Fiats.NZD:
        return 'NZD';
      case Fiats.OMR:
        return 'OMR';
      case Fiats.PAB:
        return 'PAB';
      case Fiats.PEN:
        return 'PEN';
      case Fiats.PGK:
        return 'PGK';
      case Fiats.PHP:
        return 'PHP';
      case Fiats.PKR:
        return 'PKR';
      case Fiats.PLN:
        return 'PLN';
      case Fiats.PYG:
        return 'PYG';
      case Fiats.QAR:
        return 'QAR';
      case Fiats.RON:
        return 'RON';
      case Fiats.RSD:
        return 'RSD';
      case Fiats.RUB:
        return 'RUB';
      case Fiats.RWF:
        return 'RWF';
      case Fiats.SAR:
        return 'SAR';
      case Fiats.SBD:
        return 'SBD';
      case Fiats.SCR:
        return 'SCR';
      case Fiats.SDG:
        return 'SDG';
      case Fiats.SEK:
        return 'SEK';
      case Fiats.SGD:
        return 'SGD';
      case Fiats.SHP:
        return 'SHP';
      case Fiats.SLL:
        return 'SLL';
      case Fiats.SOS:
        return 'SOS';
      case Fiats.SPL:
        return 'SPL';
      case Fiats.SRD:
        return 'SRD';
      case Fiats.STN:
        return 'STN';
      case Fiats.SVC:
        return 'SVC';
      case Fiats.SYP:
        return 'SYP';
      case Fiats.SZL:
        return 'SZL';
      case Fiats.THB:
        return 'THB';
      case Fiats.TJS:
        return 'TJS';
      case Fiats.TMT:
        return 'TMT';
      case Fiats.TND:
        return 'TND';
      case Fiats.TOP:
        return 'TOP';
      case Fiats.TRY:
        return 'TRY';
      case Fiats.TTD:
        return 'TTD';
      case Fiats.TVD:
        return 'TVD';
      case Fiats.TWD:
        return 'TWD';
      case Fiats.TZS:
        return 'TZS';
      case Fiats.UAH:
        return 'UAH';
      case Fiats.UGX:
        return 'UGX';
      case Fiats.USD:
        return 'USD';
      case Fiats.UYU:
        return 'UYU';
      case Fiats.UZS:
        return 'UZS';
      case Fiats.VEF:
        return 'VEF';
      case Fiats.VND:
        return 'VND';
      case Fiats.VUV:
        return 'VUV';
      case Fiats.WST:
        return 'WST';
      case Fiats.XAF:
        return 'XAF';
      case Fiats.XCD:
        return 'XCD';
      case Fiats.XDR:
        return 'XDR';
      case Fiats.XOF:
        return 'XOF';
      case Fiats.XPF:
        return 'XPF';
      case Fiats.YER:
        return 'YER';
      case Fiats.ZAR:
        return 'ZAR';
      case Fiats.ZMW:
        return 'ZMW';
      case Fiats.ZWD:
        return 'ZWD';
    }
  }

  String get prettyName {
    switch (this) {
      case Fiats.AED:
        return 'United Arab Emirates Dirham';
      case Fiats.AFN:
        return 'Afghanistan Afghani';
      case Fiats.ALL:
        return 'Albania Lek';
      case Fiats.AMD:
        return 'Armenia Dram';
      case Fiats.ANG:
        return 'Netherlands Antilles Guilder';
      case Fiats.AOA:
        return 'Angola Kwanza';
      case Fiats.ARS:
        return 'Argentina Peso';
      case Fiats.AUD:
        return 'Australia Dollar';
      case Fiats.AWG:
        return 'Aruba Guilder';
      case Fiats.AZN:
        return 'Azerbaijan Manat';
      case Fiats.BAM:
        return 'Bosnia and Herzegovina Convertible Mark';
      case Fiats.BBD:
        return 'Barbados Dollar';
      case Fiats.BDT:
        return 'Bangladesh Taka';
      case Fiats.BGN:
        return 'Bulgaria Lev';
      case Fiats.BHD:
        return 'Bahrain Dinar';
      case Fiats.BIF:
        return 'Burundi Franc';
      case Fiats.BMD:
        return 'Bermuda Dollar';
      case Fiats.BND:
        return 'Brunei Darussalam Dollar';
      case Fiats.BOB:
        return 'Bolivia Bolíviano';
      case Fiats.BRL:
        return 'Brazil Real';
      case Fiats.BSD:
        return 'Bahamas Dollar';
      case Fiats.BTN:
        return 'Bhutan Ngultrum';
      case Fiats.BWP:
        return 'Botswana Pula';
      case Fiats.BYN:
        return 'Belarus Ruble';
      case Fiats.BZD:
        return 'Belize Dollar';
      case Fiats.CAD:
        return 'Canada Dollar';
      case Fiats.CDF:
        return 'Congo/Kinshasa Franc';
      case Fiats.CHF:
        return 'Switzerland Franc';
      case Fiats.CLP:
        return 'Chile Peso';
      case Fiats.CNY:
        return 'China Yuan Renminbi';
      case Fiats.COP:
        return 'Colombia Peso';
      case Fiats.CRC:
        return 'Costa Rica Colon';
      case Fiats.CUC:
        return 'Cuba Convertible Peso';
      case Fiats.CUP:
        return 'Cuba Peso';
      case Fiats.CVE:
        return 'Cape Verde Escudo';
      case Fiats.CZK:
        return 'Czech Republic Koruna';
      case Fiats.DJF:
        return 'Djibouti Franc';
      case Fiats.DKK:
        return 'Denmark Krone';
      case Fiats.DOP:
        return 'Dominican Republic Peso';
      case Fiats.DZD:
        return 'Algeria Dinar';
      case Fiats.EGP:
        return 'Egypt Pound';
      case Fiats.ERN:
        return 'Eritrea Nakfa';
      case Fiats.ETB:
        return 'Ethiopia Birr';
      case Fiats.EUR:
        return 'Euro Member Countries';
      case Fiats.FJD:
        return 'Fiji Dollar';
      case Fiats.FKP:
        return 'Falkland Islands (Malvinas) Pound';
      case Fiats.GBP:
        return 'United Kingdom Pound';
      case Fiats.GEL:
        return 'Georgia Lari';
      case Fiats.GGP:
        return 'Guernsey Pound';
      case Fiats.GHS:
        return 'Ghana Cedi';
      case Fiats.GIP:
        return 'Gibraltar Pound';
      case Fiats.GMD:
        return 'Gambia Dalasi';
      case Fiats.GNF:
        return 'Guinea Franc';
      case Fiats.GTQ:
        return 'Guatemala Quetzal';
      case Fiats.GYD:
        return 'Guyana Dollar';
      case Fiats.HKD:
        return 'Hong Kong Dollar';
      case Fiats.HNL:
        return 'Honduras Lempira';
      case Fiats.HRK:
        return 'Croatia Kuna';
      case Fiats.HTG:
        return 'Haiti Gourde';
      case Fiats.HUF:
        return 'Hungary Forint';
      case Fiats.IDR:
        return 'Indonesia Rupiah';
      case Fiats.ILS:
        return 'Israel Shekel';
      case Fiats.IMP:
        return 'Isle of Man Pound';
      case Fiats.INR:
        return 'India Rupee';
      case Fiats.IQD:
        return 'Iraq Dinar';
      case Fiats.IRR:
        return 'Iran Rial';
      case Fiats.ISK:
        return 'Iceland Krona';
      case Fiats.JEP:
        return 'Jersey Pound';
      case Fiats.JMD:
        return 'Jamaica Dollar';
      case Fiats.JOD:
        return 'Jordan Dinar';
      case Fiats.JPY:
        return 'Japan Yen';
      case Fiats.KES:
        return 'Kenya Shilling';
      case Fiats.KGS:
        return 'Kyrgyzstan Som';
      case Fiats.KHR:
        return 'Cambodia Riel';
      case Fiats.KMF:
        return 'Comorian Franc';
      case Fiats.KPW:
        return 'Korea (North) Won';
      case Fiats.KRW:
        return 'Korea (South) Won';
      case Fiats.KWD:
        return 'Kuwait Dinar';
      case Fiats.KYD:
        return 'Cayman Islands Dollar';
      case Fiats.KZT:
        return 'Kazakhstan Tenge';
      case Fiats.LAK:
        return 'Laos Kip';
      case Fiats.LBP:
        return 'Lebanon Pound';
      case Fiats.LKR:
        return 'Sri Lanka Rupee';
      case Fiats.LRD:
        return 'Liberia Dollar';
      case Fiats.LSL:
        return 'Lesotho Loti';
      case Fiats.LYD:
        return 'Libya Dinar';
      case Fiats.MAD:
        return 'Morocco Dirham';
      case Fiats.MDL:
        return 'Moldova Leu';
      case Fiats.MGA:
        return 'Madagascar Ariary';
      case Fiats.MKD:
        return 'Macedonia Denar';
      case Fiats.MMK:
        return 'Myanmar (Burma) Kyat';
      case Fiats.MNT:
        return 'Mongolia Tughrik';
      case Fiats.MOP:
        return 'Macau Pataca';
      case Fiats.MRU:
        return 'Mauritania Ouguiya';
      case Fiats.MUR:
        return 'Mauritius Rupee';
      case Fiats.MVR:
        return 'Maldives (Maldive Islands) Rufiyaa';
      case Fiats.MWK:
        return 'Malawi Kwacha';
      case Fiats.MXN:
        return 'Mexico Peso';
      case Fiats.MYR:
        return 'Malaysia Ringgit';
      case Fiats.MZN:
        return 'Mozambique Metical';
      case Fiats.NAD:
        return 'Namibia Dollar';
      case Fiats.NGN:
        return 'Nigeria Naira';
      case Fiats.NIO:
        return 'Nicaragua Cordoba';
      case Fiats.NOK:
        return 'Norway Krone';
      case Fiats.NPR:
        return 'Nepal Rupee';
      case Fiats.NZD:
        return 'New Zealand Dollar';
      case Fiats.OMR:
        return 'Oman Rial';
      case Fiats.PAB:
        return 'Panama Balboa';
      case Fiats.PEN:
        return 'Peru Sol';
      case Fiats.PGK:
        return 'Papua New Guinea Kina';
      case Fiats.PHP:
        return 'Philippines Peso';
      case Fiats.PKR:
        return 'Pakistan Rupee';
      case Fiats.PLN:
        return 'Poland Zloty';
      case Fiats.PYG:
        return 'Paraguay Guarani';
      case Fiats.QAR:
        return 'Qatar Riyal';
      case Fiats.RON:
        return 'Romania Leu';
      case Fiats.RSD:
        return 'Serbia Dinar';
      case Fiats.RUB:
        return 'Russia Ruble';
      case Fiats.RWF:
        return 'Rwanda Franc';
      case Fiats.SAR:
        return 'Saudi Arabia Riyal';
      case Fiats.SBD:
        return 'Solomon Islands Dollar';
      case Fiats.SCR:
        return 'Seychelles Rupee';
      case Fiats.SDG:
        return 'Sudan Pound';
      case Fiats.SEK:
        return 'Sweden Krona';
      case Fiats.SGD:
        return 'Singapore Dollar';
      case Fiats.SHP:
        return 'Saint Helena Pound';
      case Fiats.SLL:
        return 'Sierra Leone Leone';
      case Fiats.SOS:
        return 'Somalia Shilling';
      case Fiats.SPL:
        return 'Seborga Luigino';
      case Fiats.SRD:
        return 'Suriname Dollar';
      case Fiats.STN:
        return 'São Tomé and Príncipe Dobra';
      case Fiats.SVC:
        return 'El Salvador Colon';
      case Fiats.SYP:
        return 'Syria Pound';
      case Fiats.SZL:
        return 'eSwatini Lilangeni';
      case Fiats.THB:
        return 'Thailand Baht';
      case Fiats.TJS:
        return 'Tajikistan Somoni';
      case Fiats.TMT:
        return 'Turkmenistan Manat';
      case Fiats.TND:
        return 'Tunisia Dinar';
      case Fiats.TOP:
        return "Tonga Pa'anga";
      case Fiats.TRY:
        return 'Turkey Lira';
      case Fiats.TTD:
        return 'Trinidad and Tobago Dollar';
      case Fiats.TVD:
        return 'Tuvalu Dollar';
      case Fiats.TWD:
        return 'Taiwan New Dollar';
      case Fiats.TZS:
        return 'Tanzania Shilling';
      case Fiats.UAH:
        return 'Ukraine Hryvnia';
      case Fiats.UGX:
        return 'Uganda Shilling';
      case Fiats.USD:
        return 'United States Dollar';
      case Fiats.UYU:
        return 'Uruguay Peso';
      case Fiats.UZS:
        return 'Uzbekistan Som';
      case Fiats.VEF:
        return 'Venezuela Bolívar';
      case Fiats.VND:
        return 'Viet Nam Dong';
      case Fiats.VUV:
        return 'Vanuatu Vatu';
      case Fiats.WST:
        return 'Samoa Tala';
      case Fiats.XAF:
        return 'Communauté Financière Africaine (BEAC) CFA Franc BEAC';
      case Fiats.XCD:
        return 'East Caribbean Dollar';
      case Fiats.XDR:
        return 'International Monetary Fund (IMF) Special Drawing Rights';
      case Fiats.XOF:
        return 'Communauté Financière Africaine (BCEAO) Franc';
      case Fiats.XPF:
        return 'Comptoirs Français du Pacifique (CFP) Franc';
      case Fiats.YER:
        return 'Yemen Rial';
      case Fiats.ZAR:
        return 'South Africa Rand';
      case Fiats.ZMW:
        return 'Zambia Kwacha';
      case Fiats.ZWD:
        return 'Zimbabwe Dollar';
    }
  }
}

Fiats fiatFromTickerCaseInsensitive(String ticker) {
  switch (ticker.toLowerCase()) {
    case "aed":
      return Fiats.AED;
    case "afn":
      return Fiats.AFN;
    case "all":
      return Fiats.ALL;
    case "amd":
      return Fiats.AMD;
    case "ang":
      return Fiats.ANG;
    case "aoa":
      return Fiats.AOA;
    case "ars":
      return Fiats.ARS;
    case "aud":
      return Fiats.AUD;
    case "awg":
      return Fiats.AWG;
    case "azn":
      return Fiats.AZN;
    case "bam":
      return Fiats.BAM;
    case "bbd":
      return Fiats.BBD;
    case "bdt":
      return Fiats.BDT;
    case "bgn":
      return Fiats.BGN;
    case "bhd":
      return Fiats.BHD;
    case "bif":
      return Fiats.BIF;
    case "bmd":
      return Fiats.BMD;
    case "bnd":
      return Fiats.BND;
    case "bob":
      return Fiats.BOB;
    case "brl":
      return Fiats.BRL;
    case "bsd":
      return Fiats.BSD;
    case "btn":
      return Fiats.BTN;
    case "bwp":
      return Fiats.BWP;
    case "byn":
      return Fiats.BYN;
    case "bzd":
      return Fiats.BZD;
    case "cad":
      return Fiats.CAD;
    case "cdf":
      return Fiats.CDF;
    case "chf":
      return Fiats.CHF;
    case "clp":
      return Fiats.CLP;
    case "cny":
      return Fiats.CNY;
    case "cop":
      return Fiats.COP;
    case "crc":
      return Fiats.CRC;
    case "cuc":
      return Fiats.CUC;
    case "cup":
      return Fiats.CUP;
    case "cve":
      return Fiats.CVE;
    case "czk":
      return Fiats.CZK;
    case "djf":
      return Fiats.DJF;
    case "dkk":
      return Fiats.DKK;
    case "dop":
      return Fiats.DOP;
    case "dzd":
      return Fiats.DZD;
    case "egp":
      return Fiats.EGP;
    case "ern":
      return Fiats.ERN;
    case "etb":
      return Fiats.ETB;
    case "eur":
      return Fiats.EUR;
    case "fjd":
      return Fiats.FJD;
    case "fkp":
      return Fiats.FKP;
    case "gbp":
      return Fiats.GBP;
    case "gel":
      return Fiats.GEL;
    case "ggp":
      return Fiats.GGP;
    case "ghs":
      return Fiats.GHS;
    case "gip":
      return Fiats.GIP;
    case "gmd":
      return Fiats.GMD;
    case "gnf":
      return Fiats.GNF;
    case "gtq":
      return Fiats.GTQ;
    case "gyd":
      return Fiats.GYD;
    case "hkd":
      return Fiats.HKD;
    case "hnl":
      return Fiats.HNL;
    case "hrk":
      return Fiats.HRK;
    case "htg":
      return Fiats.HTG;
    case "huf":
      return Fiats.HUF;
    case "idr":
      return Fiats.IDR;
    case "ils":
      return Fiats.ILS;
    case "imp":
      return Fiats.IMP;
    case "inr":
      return Fiats.INR;
    case "iqd":
      return Fiats.IQD;
    case "irr":
      return Fiats.IRR;
    case "isk":
      return Fiats.ISK;
    case "jep":
      return Fiats.JEP;
    case "jmd":
      return Fiats.JMD;
    case "jod":
      return Fiats.JOD;
    case "jpy":
      return Fiats.JPY;
    case "kes":
      return Fiats.KES;
    case "kgs":
      return Fiats.KGS;
    case "khr":
      return Fiats.KHR;
    case "kmf":
      return Fiats.KMF;
    case "kpw":
      return Fiats.KPW;
    case "krw":
      return Fiats.KRW;
    case "kwd":
      return Fiats.KWD;
    case "kyd":
      return Fiats.KYD;
    case "kzt":
      return Fiats.KZT;
    case "lak":
      return Fiats.LAK;
    case "lbp":
      return Fiats.LBP;
    case "lkr":
      return Fiats.LKR;
    case "lrd":
      return Fiats.LRD;
    case "lsl":
      return Fiats.LSL;
    case "lyd":
      return Fiats.LYD;
    case "mad":
      return Fiats.MAD;
    case "mdl":
      return Fiats.MDL;
    case "mga":
      return Fiats.MGA;
    case "mkd":
      return Fiats.MKD;
    case "mmk":
      return Fiats.MMK;
    case "mnt":
      return Fiats.MNT;
    case "mop":
      return Fiats.MOP;
    case "mru":
      return Fiats.MRU;
    case "mur":
      return Fiats.MUR;
    case "mvr":
      return Fiats.MVR;
    case "mwk":
      return Fiats.MWK;
    case "mxn":
      return Fiats.MXN;
    case "myr":
      return Fiats.MYR;
    case "mzn":
      return Fiats.MZN;
    case "nad":
      return Fiats.NAD;
    case "ngn":
      return Fiats.NGN;
    case "nio":
      return Fiats.NIO;
    case "nok":
      return Fiats.NOK;
    case "npr":
      return Fiats.NPR;
    case "nzd":
      return Fiats.NZD;
    case "omr":
      return Fiats.OMR;
    case "pab":
      return Fiats.PAB;
    case "pen":
      return Fiats.PEN;
    case "pgk":
      return Fiats.PGK;
    case "php":
      return Fiats.PHP;
    case "pkr":
      return Fiats.PKR;
    case "pln":
      return Fiats.PLN;
    case "pyg":
      return Fiats.PYG;
    case "qar":
      return Fiats.QAR;
    case "ron":
      return Fiats.RON;
    case "rsd":
      return Fiats.RSD;
    case "rub":
      return Fiats.RUB;
    case "rwf":
      return Fiats.RWF;
    case "sar":
      return Fiats.SAR;
    case "sbd":
      return Fiats.SBD;
    case "scr":
      return Fiats.SCR;
    case "sdg":
      return Fiats.SDG;
    case "sek":
      return Fiats.SEK;
    case "sgd":
      return Fiats.SGD;
    case "shp":
      return Fiats.SHP;
    case "sll":
      return Fiats.SLL;
    case "sos":
      return Fiats.SOS;
    case "spl":
      return Fiats.SPL;
    case "srd":
      return Fiats.SRD;
    case "stn":
      return Fiats.STN;
    case "svc":
      return Fiats.SVC;
    case "syp":
      return Fiats.SYP;
    case "szl":
      return Fiats.SZL;
    case "thb":
      return Fiats.THB;
    case "tjs":
      return Fiats.TJS;
    case "tmt":
      return Fiats.TMT;
    case "tnd":
      return Fiats.TND;
    case "top":
      return Fiats.TOP;
    case "try":
      return Fiats.TRY;
    case "ttd":
      return Fiats.TTD;
    case "tvd":
      return Fiats.TVD;
    case "twd":
      return Fiats.TWD;
    case "tzs":
      return Fiats.TZS;
    case "uah":
      return Fiats.UAH;
    case "ugx":
      return Fiats.UGX;
    case "usd":
      return Fiats.USD;
    case "uyu":
      return Fiats.UYU;
    case "uzs":
      return Fiats.UZS;
    case "vef":
      return Fiats.VEF;
    case "vnd":
      return Fiats.VND;
    case "vuv":
      return Fiats.VUV;
    case "wst":
      return Fiats.WST;
    case "xaf":
      return Fiats.XAF;
    case "xcd":
      return Fiats.XCD;
    case "xdr":
      return Fiats.XDR;
    case "xof":
      return Fiats.XOF;
    case "xpf":
      return Fiats.XPF;
    case "yer":
      return Fiats.YER;
    case "zar":
      return Fiats.ZAR;
    case "zmw":
      return Fiats.ZMW;
    case "zwd":
      return Fiats.ZWD;
    default:
      throw ArgumentError.value(
          ticker, "name", "No Fiat enum value with that ticker");
  }
}
