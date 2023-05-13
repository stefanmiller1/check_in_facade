part of check_in_facade;

abstract class IAuthFacade {

  Future<User?> get getCurrentUser;
  Future<bool?> get isAuth;
  Future<String?> get userId;
  Future<String?> get token;
  Future<bool?> get isEmailVerified;
  Future<bool> get isAppleSignInAvailable;

  Future<void> authenticate({
    required String email,
    required String password,
    required String urlSegment
  });

  Future<void> refreshSession();
  Future<bool> tryAutoLogin();
  Future<void> logout();
  Future<void> signOut();


  /// create methods ///
  Future<Either<AuthFailure, Unit>> createAuthUserProfile({
    required UserProfileModel profile,
    required Password password,
  });

  Future<Either<AuthFailure, Unit>> createUserToFirestore({
    String? id,
    required UserProfileModel profile,
  });


  Future<Either<AuthFailure, Unit>> createNewUserProfileLocation({
  required LocationModel location,
  });


  /// sign-in methods ///
  @override
  Future<Either<AuthFailure, Unit>> signInWithEmailAndPassword({
  required EmailAddress emailAddress,
  required String password,
  });

  Future<Either<AuthFailure, Unit>> signInWithGoogle();

  Future<Either<AuthFailure, Unit>> signInWithApple();

  /// sign-in update methods ///

  Future<Either<AuthFailure, Unit>> verifyAccountWithEmail();

  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail({
    required String email
  });

  Future<Either<AuthFailure, Unit>> updateUserPassword({
    required Password password,
  });

  /// validator methods ///
  Future<Either<AuthFailure, Unit>> validateEmailRegisterer({
  required EmailAddress email,
  });


  /// User Account Profile update methods ///

  Future<Either<AuthFailure, Unit>> updateUserProfile({required UserProfileModel profile, String? profileImageUrl, String? photoIDUrl, String? photoSelfieUrl});

  Future<Either<AuthFailure, Unit>> updateProfileVerification({required UserProfileModel profile});

  Future<Either<AuthFailure, Unit>> updateUserProfileSocials({required SocialsItem socials});

  Future<Either<AuthFailure, Unit>> updateUserProfileNotifications({required ProfileNotificationItems settings});

  Future<Either<AuthFailure, Unit>> updateDefaultPaymentMethod({required UserProfileModel profile});

  /// *** PROFILE WATCHER EVENTS *** ///


  /// user profile watch events ///

  Stream<Either<AuthFailure, UserProfileModel>> watchUserProfile();
  Stream<Either<AuthFailure, UserProfileModel>> watchSelectedUserProfile({required String userId});
  Stream<Either<AuthFailure, List<UserProfileModel>>> watchAllUserProfiles();

  Stream<Either<AuthFailure, SocialsItem>> watchUserProfileSocialsSetting({required String userId});
  Stream<Either<AuthFailure, ProfileNotificationItems>> watchUserProfileNotificationSettings({required String userId});

  Stream<Either<AuthFailure, List<LocationModel>>> watchUserProfileLocations({required String userId});
  Stream<Either<AuthFailure, List<ProfileSession>>> watchUserProfileSessionList({required String userId});
  Stream<Either<AuthFailure, List<UserProfileModel>>> searchAllUsersFromFirebase({
    required String query
  });
  // Stream<List<UserProfileModel>> searchFirebaseUsersProfile({required String query});
}