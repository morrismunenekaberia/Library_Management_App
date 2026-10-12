const { test, describe, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const bcrypt = require('bcrypt');

const MemberRepository = require('../src/domain/repositories/member.repository');
const UserRepository = require('../src/domain/repositories/user.repository');
const Member = require('../src/domain/entities/member.entity');
const User = require('../src/domain/entities/user.entity');
const CreateMember = require('../src/usecases/members/create-member.usecase');
const { ConflictError, ValidationError } = require('../src/domain/errors');

/**
 * Fake in-memory MemberRepository for unit tests.
 */
class FakeMemberRepository extends MemberRepository {
  constructor() {
    super();
    this.members = [];
    this.nextId = 1;
    this.activeLoans = new Set();
  }

  async findAll() {
    return [...this.members];
  }

  async findById(id) {
    return this.members.find((m) => m.id === id) || null;
  }

  async findByAdmissionNumber(admissionNumber) {
    return (
      this.members.find((m) => m.admissionNumber === admissionNumber) || null
    );
  }

  async create(data) {
    const member = new Member({
      id: this.nextId++,
      fullName: data.fullName,
      admissionNumber: data.admissionNumber,
      phone: data.phone || null,
      email: data.email || null,
      joinedAt: new Date(),
      status: data.status || 'active',
    });
    this.members.push(member);
    return member;
  }

  async update(id, data) {
    const index = this.members.findIndex((m) => m.id === id);
    if (index === -1) return null;
    const updated = new Member({ id, ...data });
    this.members[index] = updated;
    return updated;
  }

  async delete(id) {
    const index = this.members.findIndex((m) => m.id === id);
    if (index === -1) return false;
    this.members.splice(index, 1);
    return true;
  }

  async hasActiveLoans(memberId) {
    return this.activeLoans.has(memberId);
  }
}

/**
 * Fake in-memory UserRepository for unit tests.
 */
class FakeUserRepository extends UserRepository {
  constructor() {
    super();
    this.users = [];
    this.nextId = 1;
  }

  async findByUsername(username) {
    return this.users.find((u) => u.username === username) || null;
  }

  async create(userData) {
    const user = new User({
      id: this.nextId++,
      username: userData.username,
      passwordHash: userData.passwordHash,
      role: userData.role,
      memberId: userData.memberId || null,
    });
    this.users.push(user);
    return user;
  }
}

describe('CreateMember Use Case', () => {
  let fakeMemberRepo;
  let fakeUserRepo;
  let createMember;

  beforeEach(() => {
    fakeMemberRepo = new FakeMemberRepository();
    fakeUserRepo = new FakeUserRepository();
    createMember = new CreateMember(fakeMemberRepo, fakeUserRepo);
  });

  test('successfully creates a member without a user account when createUser is false', async () => {
    const result = await createMember.execute({
      fullName: 'John Doe',
      admissionNumber: 'ADM-2024-100',
      phone: '0711000111',
      email: 'john@example.com',
      createUser: false,
    });

    assert.equal(result.id, 1);
    assert.equal(result.fullName, 'John Doe');
    assert.equal(result.admissionNumber, 'ADM-2024-100');
    assert.equal(result.phone, '0711000111');
    assert.equal(result.email, 'john@example.com');
    assert.equal(result.status, 'active');
    assert.equal(result.temporaryPassword, undefined);
    assert.equal(fakeMemberRepo.members.length, 1);
    assert.equal(fakeUserRepo.users.length, 0);
  });

  test('successfully creates a member with a linked user account when createUser is true', async () => {
    const result = await createMember.execute({
      fullName: 'Jane Doe',
      admissionNumber: 'ADM-2024-101',
      createUser: true,
    });

    assert.equal(result.id, 1);
    assert.equal(result.admissionNumber, 'ADM-2024-101');
    assert.ok(result.temporaryPassword);
    assert.ok(typeof result.temporaryPassword === 'string');
    assert.ok(result.temporaryPassword.length >= 8);

    // Verify user account in fake repository
    assert.equal(fakeUserRepo.users.length, 1);
    const createdUser = fakeUserRepo.users[0];
    assert.equal(createdUser.username, 'ADM-2024-101');
    assert.equal(createdUser.role, 'member');
    assert.equal(createdUser.memberId, result.id);

    // Verify that the password was hashed with bcrypt
    const passwordMatches = await bcrypt.compare(
      result.temporaryPassword,
      createdUser.passwordHash
    );
    assert.equal(passwordMatches, true);
  });

  test('throws ConflictError (409) when admissionNumber already exists in members', async () => {
    await createMember.execute({
      fullName: 'First Member',
      admissionNumber: 'ADM-2024-200',
    });

    await assert.rejects(
      async () => {
        await createMember.execute({
          fullName: 'Duplicate Member',
          admissionNumber: 'ADM-2024-200',
        });
      },
      (err) => {
        assert(err instanceof ConflictError);
        assert.equal(err.statusCode, 409);
        assert.equal(
          err.message,
          'A member with this admission number already exists'
        );
        return true;
      }
    );
  });

  test('throws ConflictError (409) when createUser is true and username already exists', async () => {
    // Seed existing user with the same admission number
    await fakeUserRepo.create({
      username: 'ADM-2024-300',
      passwordHash: 'dummyhash',
      role: 'member',
    });

    await assert.rejects(
      async () => {
        await createMember.execute({
          fullName: 'Member With Existing Account',
          admissionNumber: 'ADM-2024-300',
          createUser: true,
        });
      },
      (err) => {
        assert(err instanceof ConflictError);
        assert.equal(err.statusCode, 409);
        assert.equal(
          err.message,
          'A user account with this admission number already exists'
        );
        return true;
      }
    );
  });

  test('throws ValidationError (400) when required fullName is missing or empty', async () => {
    await assert.rejects(
      async () => {
        await createMember.execute({
          fullName: '   ',
          admissionNumber: 'ADM-2024-400',
        });
      },
      (err) => {
        assert(err instanceof ValidationError);
        assert.equal(err.statusCode, 400);
        assert.equal(err.message, 'Full name is required');
        return true;
      }
    );
  });

  test('throws ValidationError (400) when required admissionNumber is missing or empty', async () => {
    await assert.rejects(
      async () => {
        await createMember.execute({
          fullName: 'Valid Name',
          admissionNumber: '',
        });
      },
      (err) => {
        assert(err instanceof ValidationError);
        assert.equal(err.statusCode, 400);
        assert.equal(err.message, 'Admission number is required');
        return true;
      }
    );
  });
});

