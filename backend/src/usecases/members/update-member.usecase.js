const { NotFoundError, ConflictError } = require('../../domain/errors');

/**
 * Use case: Updates an existing member.
 */
class UpdateMember {
  /**
   * @param {import('../../domain/repositories/member.repository')} memberRepository
   */
  constructor(memberRepository) {
    this.memberRepository = memberRepository;
  }

  /**
   * @param {number} id
   * @param {Object} data
   * @returns {Promise<import('../../domain/entities/member.entity')>}
   */
  async execute(id, data) {
    const existingMember = await this.memberRepository.findById(id);
    if (!existingMember) {
      throw new NotFoundError('Member not found');
    }

    const targetAdmissionNumber =
      data.admissionNumber !== undefined
        ? data.admissionNumber
        : existingMember.admissionNumber;

    if (targetAdmissionNumber !== existingMember.admissionNumber) {
      const memberWithSameAdm =
        await this.memberRepository.findByAdmissionNumber(targetAdmissionNumber);
      if (memberWithSameAdm && memberWithSameAdm.id !== id) {
        throw new ConflictError(
          'A member with this admission number already exists'
        );
      }
    }

    const fullName =
      data.fullName !== undefined ? data.fullName : existingMember.fullName;
    const phone =
      data.phone !== undefined ? data.phone : existingMember.phone;
    const email =
      data.email !== undefined ? data.email : existingMember.email;
    const status =
      data.status !== undefined ? data.status : existingMember.status;

    return this.memberRepository.update(id, {
      fullName,
      admissionNumber: targetAdmissionNumber,
      phone,
      email,
      status,
    });
  }
}

module.exports = UpdateMember;

