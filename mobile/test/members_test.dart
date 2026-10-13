import 'package:flutter_test/flutter_test.dart';
import 'package:library_mobile/core/errors/app_exceptions.dart';
import 'package:library_mobile/features/members/domain/entities/member.dart';
import 'package:library_mobile/features/members/domain/repositories/member_repository.dart';
import 'package:library_mobile/features/members/domain/usecases/create_member.dart';
import 'package:library_mobile/features/members/domain/usecases/delete_member.dart';
import 'package:library_mobile/features/members/domain/usecases/get_member.dart';
import 'package:library_mobile/features/members/domain/usecases/list_members.dart';
import 'package:library_mobile/features/members/domain/usecases/update_member.dart';
import 'package:library_mobile/features/members/presentation/controllers/members_controller.dart';

class FakeMemberRepository implements MemberRepository {
  final List<Member> members = [
    Member(
      id: 1,
      fullName: 'Alice Smith',
      admissionNumber: 'ADM001',
      phone: '+1234567890',
      email: 'alice@example.com',
      joinedAt: DateTime(2026, 1, 15),
      status: 'active',
    ),
    Member(
      id: 2,
      fullName: 'Bob Jones',
      admissionNumber: 'ADM002',
      phone: null,
      email: null,
      joinedAt: DateTime(2026, 2, 10),
      status: 'suspended',
    ),
  ];

  bool shouldThrow = false;
  Exception? customException;

  @override
  Future<List<Member>> listMembers({String? search}) async {
    if (shouldThrow) {
      throw customException ?? Exception('Failed to load members');
    }
    if (search != null && search.isNotEmpty) {
      final query = search.toLowerCase();
      return members
          .where((m) =>
              m.fullName.toLowerCase().contains(query) ||
              m.admissionNumber.toLowerCase().contains(query))
          .toList();
    }
    return List.of(members);
  }

  @override
  Future<Member> getMember(int id) async {
    if (shouldThrow) {
      throw customException ?? const NotFoundException('Member not found');
    }
    return members.firstWhere((m) => m.id == id);
  }

  @override
  Future<CreateMemberResult> createMember({
    required String fullName,
    required String admissionNumber,
    String? phone,
    String? email,
    String? status,
    bool createUser = false,
  }) async {
    if (shouldThrow) {
      throw customException ??
          const ConflictException('A member with this admission number already exists');
    }
    final newMember = Member(
      id: members.length + 1,
      fullName: fullName,
      admissionNumber: admissionNumber,
      phone: phone,
      email: email,
      joinedAt: DateTime.now(),
      status: status ?? 'active',
    );
    members.insert(0, newMember);
    return CreateMemberResult(
      member: newMember,
      temporaryPassword: createUser ? 'Tmp#test1234' : null,
    );
  }

  @override
  Future<Member> updateMember(
    int id, {
    String? fullName,
    String? admissionNumber,
    String? phone,
    String? email,
    String? status,
  }) async {
    if (shouldThrow) {
      throw customException ??
          const ConflictException('A member with this admission number already exists');
    }
    final index = members.indexWhere((m) => m.id == id);
    if (index == -1) throw const NotFoundException('Member not found');
    final updated = members[index].copyWith(
      fullName: fullName,
      admissionNumber: admissionNumber,
      phone: phone,
      email: email,
      status: status,
    );
    members[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteMember(int id) async {
    if (shouldThrow) {
      throw customException ??
          const ConflictException(
            'Cannot delete member because they currently have active unreturned loans',
          );
    }
    members.removeWhere((m) => m.id == id);
  }
}

void main() {
  late FakeMemberRepository repository;
  late MembersController controller;

  setUp(() {
    repository = FakeMemberRepository();
    controller = MembersController(
      listMembersUseCase: ListMembers(repository),
      getMemberUseCase: GetMember(repository),
      createMemberUseCase: CreateMember(repository),
      updateMemberUseCase: UpdateMember(repository),
      deleteMemberUseCase: DeleteMember(repository),
    );
  });

  group('Members Feature Tests', () {
    test('fetchMembers loads members into controller state', () async {
      await controller.fetchMembers();
      expect(controller.members.length, 2);
      expect(controller.members.first.fullName, 'Alice Smith');
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('search filters members according to query', () async {
      await controller.search('ADM002');
      expect(controller.members.length, 1);
      expect(controller.members.first.fullName, 'Bob Jones');
      expect(controller.searchQuery, 'ADM002');

      await controller.clearSearch();
      expect(controller.members.length, 2);
      expect(controller.searchQuery, isEmpty);
    });

    test('fetchMembers sets errorMessage on failure', () async {
      repository.shouldThrow = true;
      repository.customException = const NetworkException();
      await controller.fetchMembers();
      expect(controller.errorMessage, contains('Cannot reach the server'));
      expect(controller.isLoading, isFalse);
    });

    test('createMember successfully creates member and returns temporary password when requested',
        () async {
      final result = await controller.createMember(
        fullName: 'Charlie Brown',
        admissionNumber: 'ADM003',
        createUser: true,
      );

      expect(result, isNotNull);
      expect(result!.member.fullName, 'Charlie Brown');
      expect(result.temporaryPassword, 'Tmp#test1234');
      expect(controller.members.first.fullName, 'Charlie Brown');
      expect(controller.formErrorMessage, isNull);
    });

    test('createMember captures 409 conflict error in plain English', () async {
      repository.shouldThrow = true;
      repository.customException =
          const ConflictException('A member with this admission number already exists');

      final result = await controller.createMember(
        fullName: 'Duplicate Member',
        admissionNumber: 'ADM001',
      );

      expect(result, isNull);
      expect(
        controller.formErrorMessage,
        'A member with this admission number already exists',
      );
    });

    test('deleteMember successfully removes member from state', () async {
      await controller.fetchMembers();
      expect(controller.members.length, 2);

      final success = await controller.deleteMember(1);
      expect(success, isTrue);
      expect(controller.members.length, 1);
      expect(controller.members.any((m) => m.id == 1), isFalse);
    });

    test('deleteMember captures 409 active loans conflict error in plain English', () async {
      repository.shouldThrow = true;
      repository.customException = const ConflictException(
        'Cannot delete member because they currently have active unreturned loans',
      );

      final success = await controller.deleteMember(1);
      expect(success, isFalse);
      expect(
        controller.errorMessage,
        'Cannot delete member because they currently have active unreturned loans',
      );
    });
  });
}

