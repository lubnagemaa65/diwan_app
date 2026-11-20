import 'package:flutter_test/flutter_test.dart';
import 'package:university_assets_app/core/utils/validators.dart';

void main() {
  group('email validation', () {
    test('accepts plus addressing, long TLDs and surrounding whitespace', () {
      expect(Validators.email('alice+lab@example.museum'), isNull);
      expect(Validators.email('  alice+lab@example.museum  '), isNull);
      expect(Validators.email('user@dept.example.edu'), isNull);
    });

    test('rejects malformed addresses and embedded whitespace', () {
      for (final email in [
        'alice.example.museum',
        '@example.com',
        'alice@',
        'alice@example',
        'alice@example.',
        'alice@@example.com',
        'alice smith@example.com',
      ]) {
        expect(Validators.email(email), 'يرجى إدخال بريد إلكتروني صحيح',
            reason: email);
      }
    });

    test('empty email is required and uses caller messages', () {
      expect(Validators.email(null, requiredMsg: 'required'), 'required');
      expect(Validators.email('   ', requiredMsg: 'required'), 'required');
      expect(Validators.email('bad', invalidMsg: 'invalid'), 'invalid');
    });
  });

  group('password validation', () {
    test('enforces required and minimum length boundaries', () {
      expect(Validators.password(null), 'كلمة المرور مطلوبة');
      expect(Validators.password('12345'), 'يجب ألا تقل كلمة المرور عن 6 أحرف');
      expect(Validators.password('123456'), isNull);
    });
  });
}
