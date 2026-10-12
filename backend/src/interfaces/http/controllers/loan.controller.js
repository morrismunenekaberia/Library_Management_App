const { ValidationError } = require('../../../domain/errors');

class LoanController {
  /**
   * @param {Object} usecases
   * @param {import('../../../usecases/loans/issue-loan.usecase')} usecases.issueLoan
   * @param {import('../../../usecases/loans/return-loan.usecase')} usecases.returnLoan
   * @param {import('../../../usecases/loans/list-loans.usecase')} usecases.listLoans
   */
  constructor({ issueLoan, returnLoan, listLoans }) {
    this.issueLoanUseCase = issueLoan;
    this.returnLoanUseCase = returnLoan;
    this.listLoansUseCase = listLoans;
  }

  /**
   * Helper to parse integer ID parameter.
   */
  _parseId(param) {
    const id = parseInt(param, 10);
    if (isNaN(id) || id <= 0) {
      throw new ValidationError('Invalid loan ID parameter');
    }
    return id;
  }

  /**
   * POST /api/loans
   */
  async issue(req, res, next) {
    try {
      const loan = await this.issueLoanUseCase.execute(req.body);
      return res.status(201).json(loan);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/loans/:id/return
   */
  async returnBook(req, res, next) {
    try {
      const loanId = this._parseId(req.params.id);
      const loan = await this.returnLoanUseCase.execute(loanId);
      return res.status(200).json(loan);
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/loans?status=...&memberId=...
   */
  async list(req, res, next) {
    try {
      const status = req.query.status;
      let memberId;

      // Access control: members can only see their own loans
      if (req.user.role === 'member') {
        memberId = req.user.memberId;
        // If the user has no linked member record, return empty list
        if (!memberId) {
          return res.status(200).json([]);
        }
      } else if (req.query.memberId) {
        memberId = parseInt(req.query.memberId, 10);
        if (isNaN(memberId) || memberId <= 0) {
          throw new ValidationError('Invalid memberId query parameter');
        }
      }

      const loans = await this.listLoansUseCase.execute({ status, memberId });
      return res.status(200).json(loans);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = LoanController;

