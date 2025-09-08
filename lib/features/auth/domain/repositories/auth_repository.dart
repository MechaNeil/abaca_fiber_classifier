import '../entities/user.dart';

abstract class AuthRepository {
  Future<int> registerUser(User user);
  Future<User?> loginUser(String username, String password);
  Future<User?> getUserByUsername(String username);
  Future<bool> userExists(String username);
  Future<void> deleteUser(int id);
  Future<List<User>> getAllUsers();
  Future<void> ensureAdminUserExists();
}
