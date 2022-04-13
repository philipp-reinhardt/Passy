import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';

import 'common.dart';
import 'custom_field.dart';
import 'passy_entries.dart';
import 'passy_entry.dart';
import 'encrypted_json_file.dart';

typedef PaymentCards = PassyEntries<PaymentCard>;

class PaymentCardsFile extends EncryptedJsonFile<PaymentCards> {
  PaymentCardsFile._(File file, Encrypter encrypter,
      {required PaymentCards value})
      : super(file, encrypter, value: value);

  factory PaymentCardsFile(File file, Encrypter encrypter) {
    if (file.existsSync()) {
      return PaymentCardsFile._(file, encrypter,
          value: PaymentCards.fromJson(jsonDecode(
              decrypt(file.readAsStringSync(), encrypter: encrypter))));
    }
    file.createSync(recursive: true);
    PaymentCardsFile _file =
        PaymentCardsFile._(file, encrypter, value: PaymentCards());
    _file.saveSync();
    return _file;
  }
}

class PaymentCard extends PassyEntry<PaymentCard> {
  static const csvTemplate = {
    'key': 1,
    'nickname': 2,
    'cardNumber': 3,
    'cardholderName': 4,
    'cvv': 5,
    'exp': 6,
    'additionalInfo': 7,
  };

  String nickname;
  String cardNumber;
  String cardholderName;
  String cvv;
  String exp;
  List<CustomField> customFields;
  String additionalInfo;
  List<String> tags;

  PaymentCard._({
    required String key,
    this.nickname = '',
    this.cardNumber = '',
    this.cardholderName = '',
    this.cvv = '',
    this.exp = '',
    List<CustomField>? customFields,
    this.additionalInfo = '',
    List<String>? tags,
  })  : customFields = customFields ?? [],
        tags = tags ?? [],
        super(key);

  PaymentCard({
    this.nickname = '',
    this.cardNumber = '',
    this.cardholderName = '',
    this.cvv = '',
    this.exp = '',
    List<CustomField>? customFields,
    this.additionalInfo = '',
    List<String>? tags,
  })  : customFields = customFields ?? [],
        tags = tags ?? [],
        super(DateTime.now().toUtc().toIso8601String());

  PaymentCard.fromJson(Map<String, dynamic> json)
      : nickname = json['nickname'] ?? '',
        cardNumber = json['cardNumber'] ?? '',
        cardholderName = json['cardholderName'] ?? '',
        cvv = json['cvv'] ?? '',
        exp = json['exp'] ?? '',
        customFields = (json['customFields'] as List<dynamic>?)
                ?.map((e) => CustomField.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        additionalInfo = json['additionalInfo'] ?? '',
        tags = (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        super(json['key'] ?? DateTime.now().toUtc().toIso8601String());

  factory PaymentCard.fromCSV(List<List<dynamic>> csv,
      {Map<String, Map<String, int>> templates = const {}}) {
    Map<String, int> _passwordTemplate = templates['password'] ?? csvTemplate;
    Map<String, int> _customFieldTemplate =
        templates['customField'] ?? CustomField.csvTemplate;
    PaymentCard? _paymentCard;
    List<CustomField> _customFields = [];
    List<String> _tags = [];

    for (List<dynamic> entry in csv) {
      switch (entry[0]) {
        case 'password':
          _paymentCard = PaymentCard._(
            key: entry[_passwordTemplate['key']!],
            cardNumber: entry[_passwordTemplate['cardNumber']!],
            cardholderName: entry[_passwordTemplate['cardholderName']!],
            cvv: entry[_passwordTemplate['cvv']!],
            exp: entry[_passwordTemplate['exp']!],
            additionalInfo: entry[_passwordTemplate['additionalInfo']!],
          );
          break;
        case 'customFields':
          _customFields
              .add(CustomField.fromCSV(entry, template: _customFieldTemplate));
          break;
        case 'tags':
          for (int i = 1; i != entry.length; i++) {
            _tags.add(entry[i]);
          }
          break;
      }
    }

    _paymentCard!.customFields = _customFields;
    _paymentCard.tags = _tags;
    return _paymentCard;
  }

  @override
  int compareTo(PaymentCard other) => nickname.compareTo(other.nickname);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'key': key,
        'nickname': nickname,
        'cardNumber': cardNumber,
        'cardholderName': cardholderName,
        'cvv': cvv,
        'exp': exp,
        'customFields': customFields.map((e) => e.toJson()).toList(),
        'additionalInfo': additionalInfo,
        'tags': tags,
      };

  @override
  List<List<dynamic>> toCSV() => jsonToCSV('paymentCard', toJson());
}
