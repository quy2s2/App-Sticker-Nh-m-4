enum UserRole {
  admin,
  user,
}

UserRole parseUserRole(String? role) {
  if (role == 'admin') return UserRole.admin;
  return UserRole.user;
}
