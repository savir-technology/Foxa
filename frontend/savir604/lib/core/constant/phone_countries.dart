class PhoneCountry {
  const PhoneCountry({
    required this.isoCode,
    required this.name,
    required this.dialCode,
    this.searchTerms = const [],
  });

  final String isoCode;
  final String name;
  final String dialCode;
  final List<String> searchTerms;

  PhoneCountry copyWith({
    String? isoCode,
    String? name,
    String? dialCode,
    List<String>? searchTerms,
  }) {
    return PhoneCountry(
      isoCode: isoCode ?? this.isoCode,
      name: name ?? this.name,
      dialCode: dialCode ?? this.dialCode,
      searchTerms: searchTerms ?? this.searchTerms,
    );
  }

  String get displayLabel => '$name ($dialCode)';
}

const List<PhoneCountry> phoneCountries = [
  PhoneCountry(isoCode: 'US', name: 'United States', dialCode: '+1'),
  PhoneCountry(isoCode: 'CA', name: 'Canada', dialCode: '+1'),
  PhoneCountry(isoCode: 'MX', name: 'Mexico', dialCode: '+52'),
  PhoneCountry(isoCode: 'BR', name: 'Brazil', dialCode: '+55'),
  PhoneCountry(isoCode: 'AR', name: 'Argentina', dialCode: '+54'),
  PhoneCountry(isoCode: 'CL', name: 'Chile', dialCode: '+56'),
  PhoneCountry(isoCode: 'CO', name: 'Colombia', dialCode: '+57'),
  PhoneCountry(isoCode: 'PE', name: 'Peru', dialCode: '+51'),
  PhoneCountry(isoCode: 'EC', name: 'Ecuador', dialCode: '+593'),
  PhoneCountry(isoCode: 'VE', name: 'Venezuela', dialCode: '+58'),
  PhoneCountry(isoCode: 'UY', name: 'Uruguay', dialCode: '+598'),
  PhoneCountry(isoCode: 'PY', name: 'Paraguay', dialCode: '+595'),
  PhoneCountry(isoCode: 'BO', name: 'Bolivia', dialCode: '+591'),
  PhoneCountry(isoCode: 'CR', name: 'Costa Rica', dialCode: '+506'),
  PhoneCountry(isoCode: 'PA', name: 'Panama', dialCode: '+507'),
  PhoneCountry(isoCode: 'DO', name: 'Dominican Republic', dialCode: '+1'),
  PhoneCountry(isoCode: 'CU', name: 'Cuba', dialCode: '+53'),
  PhoneCountry(isoCode: 'JM', name: 'Jamaica', dialCode: '+1'),
  PhoneCountry(isoCode: 'TT', name: 'Trinidad and Tobago', dialCode: '+1'),
  PhoneCountry(isoCode: 'GB', name: 'United Kingdom', dialCode: '+44'),
  PhoneCountry(isoCode: 'IE', name: 'Ireland', dialCode: '+353'),
  PhoneCountry(isoCode: 'FR', name: 'France', dialCode: '+33'),
  PhoneCountry(isoCode: 'DE', name: 'Germany', dialCode: '+49'),
  PhoneCountry(isoCode: 'NL', name: 'Netherlands', dialCode: '+31'),
  PhoneCountry(isoCode: 'BE', name: 'Belgium', dialCode: '+32'),
  PhoneCountry(isoCode: 'LU', name: 'Luxembourg', dialCode: '+352'),
  PhoneCountry(isoCode: 'CH', name: 'Switzerland', dialCode: '+41'),
  PhoneCountry(isoCode: 'AT', name: 'Austria', dialCode: '+43'),
  PhoneCountry(isoCode: 'IT', name: 'Italy', dialCode: '+39'),
  PhoneCountry(isoCode: 'ES', name: 'Spain', dialCode: '+34'),
  PhoneCountry(isoCode: 'PT', name: 'Portugal', dialCode: '+351'),
  PhoneCountry(isoCode: 'SE', name: 'Sweden', dialCode: '+46'),
  PhoneCountry(isoCode: 'NO', name: 'Norway', dialCode: '+47'),
  PhoneCountry(isoCode: 'DK', name: 'Denmark', dialCode: '+45'),
  PhoneCountry(isoCode: 'FI', name: 'Finland', dialCode: '+358'),
  PhoneCountry(isoCode: 'IS', name: 'Iceland', dialCode: '+354'),
  PhoneCountry(isoCode: 'PL', name: 'Poland', dialCode: '+48'),
  PhoneCountry(isoCode: 'CZ', name: 'Czech Republic', dialCode: '+420'),
  PhoneCountry(isoCode: 'SK', name: 'Slovakia', dialCode: '+421'),
  PhoneCountry(isoCode: 'HU', name: 'Hungary', dialCode: '+36'),
  PhoneCountry(isoCode: 'RO', name: 'Romania', dialCode: '+40'),
  PhoneCountry(isoCode: 'BG', name: 'Bulgaria', dialCode: '+359'),
  PhoneCountry(isoCode: 'GR', name: 'Greece', dialCode: '+30'),
  PhoneCountry(isoCode: 'TR', name: 'Turkey', dialCode: '+90'),
  PhoneCountry(isoCode: 'UA', name: 'Ukraine', dialCode: '+380'),
  PhoneCountry(isoCode: 'RU', name: 'Russia', dialCode: '+7'),
  PhoneCountry(isoCode: 'RS', name: 'Serbia', dialCode: '+381'),
  PhoneCountry(isoCode: 'HR', name: 'Croatia', dialCode: '+385'),
  PhoneCountry(isoCode: 'SI', name: 'Slovenia', dialCode: '+386'),
  PhoneCountry(isoCode: 'BA', name: 'Bosnia and Herzegovina', dialCode: '+387'),
  PhoneCountry(isoCode: 'AL', name: 'Albania', dialCode: '+355'),
  PhoneCountry(isoCode: 'MK', name: 'North Macedonia', dialCode: '+389'),
  PhoneCountry(isoCode: 'ME', name: 'Montenegro', dialCode: '+382'),
  PhoneCountry(isoCode: 'XK', name: 'Kosovo', dialCode: '+383'),
  PhoneCountry(isoCode: 'GE', name: 'Georgia', dialCode: '+995'),
  PhoneCountry(isoCode: 'AM', name: 'Armenia', dialCode: '+374'),
  PhoneCountry(isoCode: 'AZ', name: 'Azerbaijan', dialCode: '+994'),
  PhoneCountry(isoCode: 'CY', name: 'Cyprus', dialCode: '+357'),
  PhoneCountry(isoCode: 'MT', name: 'Malta', dialCode: '+356'),
  PhoneCountry(isoCode: 'SA', name: 'Saudi Arabia', dialCode: '+966'),
  PhoneCountry(isoCode: 'AE', name: 'United Arab Emirates', dialCode: '+971'),
  PhoneCountry(isoCode: 'QA', name: 'Qatar', dialCode: '+974'),
  PhoneCountry(isoCode: 'KW', name: 'Kuwait', dialCode: '+965'),
  PhoneCountry(isoCode: 'BH', name: 'Bahrain', dialCode: '+973'),
  PhoneCountry(isoCode: 'OM', name: 'Oman', dialCode: '+968'),
  PhoneCountry(isoCode: 'YE', name: 'Yemen', dialCode: '+967'),
  PhoneCountry(isoCode: 'JO', name: 'Jordan', dialCode: '+962'),
  PhoneCountry(isoCode: 'LB', name: 'Lebanon', dialCode: '+961'),
  PhoneCountry(isoCode: 'PS', name: 'Palestine', dialCode: '+970'),
  PhoneCountry(isoCode: 'IQ', name: 'Iraq', dialCode: '+964'),
  PhoneCountry(isoCode: 'EG', name: 'Egypt', dialCode: '+20'),
  PhoneCountry(isoCode: 'LY', name: 'Libya', dialCode: '+218'),
  PhoneCountry(isoCode: 'TN', name: 'Tunisia', dialCode: '+216'),
  PhoneCountry(isoCode: 'DZ', name: 'Algeria', dialCode: '+213'),
  PhoneCountry(isoCode: 'MA', name: 'Morocco', dialCode: '+212'),
  PhoneCountry(isoCode: 'SD', name: 'Sudan', dialCode: '+249'),
  PhoneCountry(isoCode: 'MR', name: 'Mauritania', dialCode: '+222'),
  PhoneCountry(isoCode: 'DJ', name: 'Djibouti', dialCode: '+253'),
  PhoneCountry(isoCode: 'SO', name: 'Somalia', dialCode: '+252'),
  PhoneCountry(isoCode: 'ET', name: 'Ethiopia', dialCode: '+251'),
  PhoneCountry(isoCode: 'ER', name: 'Eritrea', dialCode: '+291'),
  PhoneCountry(isoCode: 'KE', name: 'Kenya', dialCode: '+254'),
  PhoneCountry(isoCode: 'UG', name: 'Uganda', dialCode: '+256'),
  PhoneCountry(isoCode: 'TZ', name: 'Tanzania', dialCode: '+255'),
  PhoneCountry(isoCode: 'RW', name: 'Rwanda', dialCode: '+250'),
  PhoneCountry(isoCode: 'BI', name: 'Burundi', dialCode: '+257'),
  PhoneCountry(isoCode: 'ZA', name: 'South Africa', dialCode: '+27'),
  PhoneCountry(isoCode: 'NG', name: 'Nigeria', dialCode: '+234'),
  PhoneCountry(isoCode: 'GH', name: 'Ghana', dialCode: '+233'),
  PhoneCountry(isoCode: 'CI', name: 'Ivory Coast', dialCode: '+225'),
  PhoneCountry(isoCode: 'SN', name: 'Senegal', dialCode: '+221'),
  PhoneCountry(isoCode: 'CM', name: 'Cameroon', dialCode: '+237'),
  PhoneCountry(isoCode: 'NE', name: 'Niger', dialCode: '+227'),
  PhoneCountry(isoCode: 'ML', name: 'Mali', dialCode: '+223'),
  PhoneCountry(isoCode: 'TD', name: 'Chad', dialCode: '+235'),
  PhoneCountry(isoCode: 'BJ', name: 'Benin', dialCode: '+229'),
  PhoneCountry(isoCode: 'TG', name: 'Togo', dialCode: '+228'),
  PhoneCountry(isoCode: 'ZW', name: 'Zimbabwe', dialCode: '+263'),
  PhoneCountry(isoCode: 'ZM', name: 'Zambia', dialCode: '+260'),
  PhoneCountry(isoCode: 'MZ', name: 'Mozambique', dialCode: '+258'),
  PhoneCountry(isoCode: 'NA', name: 'Namibia', dialCode: '+264'),
  PhoneCountry(isoCode: 'AO', name: 'Angola', dialCode: '+244'),
  PhoneCountry(isoCode: 'BW', name: 'Botswana', dialCode: '+267'),
  PhoneCountry(isoCode: 'MG', name: 'Madagascar', dialCode: '+261'),
  PhoneCountry(isoCode: 'MU', name: 'Mauritius', dialCode: '+230'),
  PhoneCountry(isoCode: 'IN', name: 'India', dialCode: '+91'),
  PhoneCountry(isoCode: 'PK', name: 'Pakistan', dialCode: '+92'),
  PhoneCountry(isoCode: 'BD', name: 'Bangladesh', dialCode: '+880'),
  PhoneCountry(isoCode: 'LK', name: 'Sri Lanka', dialCode: '+94'),
  PhoneCountry(isoCode: 'NP', name: 'Nepal', dialCode: '+977'),
  PhoneCountry(isoCode: 'BT', name: 'Bhutan', dialCode: '+975'),
  PhoneCountry(isoCode: 'MV', name: 'Maldives', dialCode: '+960'),
  PhoneCountry(isoCode: 'CN', name: 'China', dialCode: '+86'),
  PhoneCountry(isoCode: 'HK', name: 'Hong Kong', dialCode: '+852'),
  PhoneCountry(isoCode: 'MO', name: 'Macau', dialCode: '+853'),
  PhoneCountry(isoCode: 'TW', name: 'Taiwan', dialCode: '+886'),
  PhoneCountry(isoCode: 'JP', name: 'Japan', dialCode: '+81'),
  PhoneCountry(isoCode: 'KR', name: 'South Korea', dialCode: '+82'),
  PhoneCountry(isoCode: 'KP', name: 'North Korea', dialCode: '+850'),
  PhoneCountry(isoCode: 'MN', name: 'Mongolia', dialCode: '+976'),
  PhoneCountry(isoCode: 'KZ', name: 'Kazakhstan', dialCode: '+7'),
  PhoneCountry(isoCode: 'UZ', name: 'Uzbekistan', dialCode: '+998'),
  PhoneCountry(isoCode: 'TM', name: 'Turkmenistan', dialCode: '+993'),
  PhoneCountry(isoCode: 'KG', name: 'Kyrgyzstan', dialCode: '+996'),
  PhoneCountry(isoCode: 'TJ', name: 'Tajikistan', dialCode: '+992'),
  PhoneCountry(isoCode: 'AF', name: 'Afghanistan', dialCode: '+93'),
  PhoneCountry(isoCode: 'IR', name: 'Iran', dialCode: '+98'),
  PhoneCountry(isoCode: 'ID', name: 'Indonesia', dialCode: '+62'),
  PhoneCountry(isoCode: 'MY', name: 'Malaysia', dialCode: '+60'),
  PhoneCountry(isoCode: 'SG', name: 'Singapore', dialCode: '+65'),
  PhoneCountry(isoCode: 'TH', name: 'Thailand', dialCode: '+66'),
  PhoneCountry(isoCode: 'VN', name: 'Vietnam', dialCode: '+84'),
  PhoneCountry(isoCode: 'PH', name: 'Philippines', dialCode: '+63'),
  PhoneCountry(isoCode: 'KH', name: 'Cambodia', dialCode: '+855'),
  PhoneCountry(isoCode: 'LA', name: 'Laos', dialCode: '+856'),
  PhoneCountry(isoCode: 'MM', name: 'Myanmar', dialCode: '+95'),
  PhoneCountry(isoCode: 'BN', name: 'Brunei', dialCode: '+673'),
  PhoneCountry(isoCode: 'AU', name: 'Australia', dialCode: '+61'),
  PhoneCountry(isoCode: 'NZ', name: 'New Zealand', dialCode: '+64'),
  PhoneCountry(isoCode: 'FJ', name: 'Fiji', dialCode: '+679'),
  PhoneCountry(isoCode: 'PG', name: 'Papua New Guinea', dialCode: '+675'),
  PhoneCountry(isoCode: 'WS', name: 'Samoa', dialCode: '+685'),
  PhoneCountry(isoCode: 'TO', name: 'Tonga', dialCode: '+676'),
  PhoneCountry(isoCode: 'SB', name: 'Solomon Islands', dialCode: '+677'),
  PhoneCountry(isoCode: 'VU', name: 'Vanuatu', dialCode: '+678'),
];

PhoneCountry defaultPhoneCountry() {
  return phoneCountries.first;
}

PhoneCountry? findPhoneCountryByPhone(String phone) {
  final normalized = phone.trim();
  if (!normalized.startsWith('+')) {
    return null;
  }

  final sorted = [...phoneCountries]
    ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));

  for (final country in sorted) {
    if (normalized.startsWith(country.dialCode)) {
      return country;
    }
  }
  return null;
}

String extractNationalNumber(String phone, PhoneCountry country) {
  var normalized = phone.trim();
  if (normalized.startsWith(country.dialCode)) {
    normalized = normalized.substring(country.dialCode.length);
  }
  return normalized.replaceAll(RegExp(r'[^\d]'), '');
}

String normalizeDialCode(String value) {
  var dial = value.trim().replaceAll(RegExp(r'[^\d+]'), '');
  if (!dial.startsWith('+')) {
    dial = '+$dial';
  }
  return dial;
}

String composeInternationalPhone({
  required PhoneCountry country,
  required String nationalNumber,
}) {
  var digits = nationalNumber.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.length > 8 && digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  return '${country.dialCode}$digits';
}
