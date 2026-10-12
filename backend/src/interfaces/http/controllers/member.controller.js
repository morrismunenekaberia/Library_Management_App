const { ValidationError } = require('../../../domain/errors');

class MemberController {
  /**
   * @param {Object} usecases
   * @param {import('../../../usecases/members/list-members.usecase')} usecases.listMembers
   * @param {import('../../../usecases/members/get-member.usecase')} usecases.getMember
   * @param {import('../../../usecases/members/create-member.usecase')} usecases.createMember
   * @param {import('../../../usecases/members/update-member.usecase')} usecases.updateMember
   * @param {import('../../../usecases/members/delete-member.usecase')} usecases.deleteMember
   */
  constructor({
    listMembers,
    getMember,
    createMember,
    updateMember,
    deleteMember,
  }) {
    this.listMembers = listMembers;
    this.getMember = getMember;
    this.createMember = createMember;
    this.updateMember = updateMember;
    this.deleteMember = deleteMember;
  }

  /**
   * Helper to parse integer ID parameter.
   */
  _parseId(param) {
    const id = parseInt(param, 10);
    if (isNaN(id) || id <= 0) {
      throw new ValidationError('Invalid member ID parameter');
    }
    return id;
  }

  /**
   * GET /api/members?search=
   */
  async list(req, res, next) {
    try {
      let search;
      if (req.query.search !== undefined) {
        if (typeof req.query.search !== 'string') {
          throw new ValidationError('Search query parameter must be a string');
        }
        search = req.query.search.trim();
        if (search.length > 200) {
          throw new ValidationError('Search query parameter cannot exceed 200 characters');
        }
      }
      const members = await this.listMembers.execute(search);
      return res.status(200).json(members);
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/members/:id
   */
  async getById(req, res, next) {
    try {
      const id = this._parseId(req.params.id);
      const member = await this.getMember.execute(id);
      return res.status(200).json(member);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/members
   */
  async create(req, res, next) {
    try {
      const result = await this.createMember.execute(req.body);
      return res.status(201).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * PUT /api/members/:id
   */
  async update(req, res, next) {
    try {
      const id = this._parseId(req.params.id);
      const updatedMember = await this.updateMember.execute(id, req.body);
      return res.status(200).json(updatedMember);
    } catch (err) {
      next(err);
    }
  }

  /**
   * DELETE /api/members/:id
   */
  async delete(req, res, next) {
    try {
      const id = this._parseId(req.params.id);
      await this.deleteMember.execute(id);
      return res.status(200).json({ message: 'Member deleted successfully' });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = MemberController;

