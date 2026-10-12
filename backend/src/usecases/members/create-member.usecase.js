const crypto = require('crypto');
const bcrypt = require('bcrypt');
const { ConflictError, ValidationError } = require('../../domain/errors');

const SALT_ROUNDS = 10;

/**
 * Use case: Registers a new library member, with optional linked user account.
 */
class CreateMember {
  /**
   * @param {import('../../domain/repositories/member.repository')} memberRepository
   * @param {import('../../domain/repositories/user.repository')} [userRepository]
   */
  constructor(memberRepository, userRepository = null) {
    this.memberRepository = memberRepository;
    this.userRepository = userRepository;
  }

  /**
   * @param {Object} data
   * @param {string} data.fullName
   * @param {string} data.admissionNumber
   * @param {string|null} [data.phone]
   * @param {string|null} [data.email]
   * @param {string} [data.status]
   * @param {boolean} [data.createUser=false]
   * @returns {Promise<Object>}
   */
  async execute({
    fullName,
    admissionNumber,
    phone = null,
    email = null,
    status = 'active',
    createUser = false,
  }) {
    if (!fullName || typeof fullName !== 'string' || !fullName.trim()) {
      throw new ValidationError('Full name is required');
    }
    if (
      !admissionNumber ||
      typeof admissionNumber !== 'string' ||
      !admissionNumber.trim()
    ) {
      throw new ValidationError('Admission number is required');
    }

    const trimmedAdmissionNumber = admissionNumber.trim();

    // Check admission number uniqueness
    const existingMember =
      await this.memberRepository.findByAdmissionNumber(trimmedAdmissionNumber);
    if (existingMember) {
      throw new ConflictError(
        'A member with this admission number already exists'
      );
    }

    // If user account requested, ensure username is also available
    if (createUser && this.userRepository) {
      const existingUser =
        await this.userRepository.findByUsername(trimmedAdmissionNumber);
      if (existingUser) {
        throw new ConflictError(
          'A user account with this admission number already exists'
        );
      }
    }

    // Create the member
    const member = await this.memberRepository.create({
      fullName: fullName.trim(),
      admissionNumber: trimmedAdmissionNumber,
      phone: phone ? phone.trim() : null,
      email: email ? email.trim() : null,
      status: status || 'active',
    });

    let temporaryPassword = null;

    // Optionally create linked user account
    if (createUser && this.userRepository) {
      // Generate an 8-character random temporary password
      temporaryPassword = `Tmp#${crypto.randomBytes(4).toString('hex')}`;
      const passwordHash = await bcrypt.hash(temporaryPassword, SALT_ROUNDS);

      await this.userRepository.create({
        username: trimmedAdmissionNumber,
        passwordHash,
        role: 'member',
        memberId: member.id,
      });
    }

    const response = {
      id: member.id,
      fullName: member.fullName,
      admissionNumber: member.admissionNumber,
      phone: member.phone,
      email: member.email,
      joinedAt: member.joinedAt,
      status: member.status,
    };

    if (temporaryPassword) {
      response.temporaryPassword = temporaryPassword;
    }

    return response;
  }
}

module.exports = CreateMember;

