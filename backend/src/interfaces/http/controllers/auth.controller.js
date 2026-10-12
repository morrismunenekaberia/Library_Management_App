const { ValidationError } = require('../../../domain/errors');

class AuthController {
  /**
   * @param {import('../../../usecases/login-user.usecase')} loginUserUseCase
   */
  constructor(loginUserUseCase) {
    this.loginUserUseCase = loginUserUseCase;
  }

  /**
   * POST /api/auth/login
   */
  async login(req, res, next) {
    try {
      const { username, password } = req.body || {};

      if (
        !username ||
        typeof username !== 'string' ||
        !username.trim() ||
        !password ||
        typeof password !== 'string'
      ) {
        throw new ValidationError('Username and password are required');
      }

      if (username.trim().length > 100) {
        throw new ValidationError('Username cannot exceed 100 characters');
      }

      const result = await this.loginUserUseCase.execute({
        username: username.trim(),
        password,
      });

      return res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/auth/logout
   */
  async logout(req, res, next) {
    try {
      return res.status(200).json({ message: 'Logged out successfully' });
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/auth/me (Protected route)
   */
  async getProfile(req, res, next) {
    try {
      return res.status(200).json({ user: req.user });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = AuthController;

