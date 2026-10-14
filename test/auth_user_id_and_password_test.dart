import 'package:flutter_test/flutter_test.dart';
import 'package:smart_tea_stall/core/models/app_user.dart';
import 'package:smart_tea_stall/core/services/auth_service.dart';

void main() {
  group('AuthService User ID Normalization', () {
    test('normalizes alphanumeric User ID to synthetic auth email', () {
      expect(AuthService.normalizeToEmail('admin'), 'admin@chai.app');
      expect(AuthService.normalizeToEmail('EMP101'), 'emp101@chai.app');
      expect(AuthService.normalizeToEmail('comp_tcs_01'), 'comp_tcs_01@chai.app');
      expect(AuthService.normalizeToEmail('  user.123  '), 'user.123@chai.app');
    });

    test('preserves explicit email addresses', () {
      expect(AuthService.normalizeToEmail('user@domain.com'), 'user@domain.com');
      expect(AuthService.normalizeToEmail('ADMIN@CUSTOM.ORG'), 'admin@custom.org');
    });
  });

  group('AppUser Model User ID', () {
    test('serializes and deserializes userId correctly', () {
      const user = AppUser(
        id: 1,
        authId: 'uid_test',
        userId: 'emp_raj',
        name: 'Rajesh Sharma',
        phone: '9876543210',
        role: UserRole.employee,
        status: UserStatus.active,
      );

      final map = user.toMap();
      expect(map['user_id'], 'emp_raj');
      expect(map['email'], 'emp_raj@chai.app');

      final fromDoc = AppUser.fromMap(map, 'uid_test');
      expect(fromDoc.userId, 'emp_raj');
      expect(fromDoc.email, 'emp_raj@chai.app');
      expect(fromDoc.name, 'Rajesh Sharma');
      expect(fromDoc.role, UserRole.employee);
    });

    test('falls back to email prefix if userId is missing in legacy doc', () {
      final legacyMap = {
        'name': 'Old Company',
        'email': 'tcs_indore@chai.app',
        'phone': '1234567890',
        'role': 'company',
        'status': 'active',
      };

      final fromDoc = AppUser.fromMap(legacyMap, 'uid_legacy');
      expect(fromDoc.userId, 'tcs_indore');
      expect(fromDoc.role, UserRole.company);
    });
  });
}
