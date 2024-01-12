part of check_in_facade;

@LazySingleton(as: IAuthFacade)
class FirebaseAuthFacade with ChangeNotifier implements IAuthFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;
  final LocationAuthFacade _locationFacade;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthFacade(
    this._fireStore,
    this._firebaseAuth,
    this._locationFacade,
    this._googleSignIn
  );

  ///
  /// *** HANDLE ALL FIREBASE NEW ACCOUNT CREATION METHODS *** ///
  ///

  @override
  Future<Either<AuthFailure, Unit>> createAuthUserProfile({
    required UserProfileModel profile,
    required Password password,
    }) async {

    final emailStr = profile.emailAddress.getOrCrash();
    final passwordStr = password.getOrCrash();

    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
          email: emailStr,
          password: passwordStr
      );

      await createUserToFirestore(id: _firebaseAuth.currentUser?.uid, profile: profile);
      await authenticate(email: emailStr, password: passwordStr, urlSegment: 'signInWithPassword');

      return right(unit);
    } on FirebaseAuthException catch (e) {
      return left(getErrorMessageFromFirebaseException(e));
    } catch (e) {
      return left(AuthFailure.serverError());
    }
  }


  @override
  Future<Either<AuthFailure, Unit>> createUserToFirestore({
    String? id,
    required UserProfileModel profile}) async {

    try {
      if (id != null) {
        final userRef = _fireStore.collection('users').doc(id);
        final userProfileDto = UserProfileItemDto.fromDomain(profile);

        await userRef.set(userProfileDto.toJson());
        return right(unit);
      } else {
        return left(AuthFailure.serverError());
      }
    } on FirebaseAuthException catch (e) {
      return left(getErrorMessageFromFirebaseException(e));
      // if (e.message != null && e.message!.contains('PERMISSION_DENIED')) {
      //   return left(AuthFailure.serverError());
      // } else {
      //   return left(AuthFailure.serverError());
      // }
    } on Exception catch (e) {
      return left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> createNewUserProfileLocation({
    required LocationModel location
  }) async {
    try {
      await _locationFacade.createNewProfileLocationAuth(location: location);
      return right(unit);
    } catch (e) {
      return left(AuthFailure.serverError());
    }
  }



  ///
  /// *** HANDLE ALL FIREBASE SIGN-IN METHODS: *** ///
  ///
  /// sign-in with e-mail and password - uses authenticate method to keep user signed-in on web so long as token is valid
  /// sign in with google
  /// sign in with e-mail link
  ///
  ///

  Timer? _authTimer;
  String? _token;
  String? _refresh_token;
  String? _emailAddress;
  DateTime? _expiryDate;
  String? _userId;
  bool? _verified;


  @override
  Future<bool?> get isEmailVerified async {
    if (_firebaseAuth.currentUser != null) {
      print(_firebaseAuth.currentUser!.emailVerified);
      return _firebaseAuth.currentUser!.emailVerified;
    }
    return false;
  }


  @override
  Future<bool?> get getSignInTypeVerification async {
    if (_verified != null) {
      return _verified!;
    }
    return null;
  }

  @override
  Future<User?> get getCurrentUser async {
    return _firebaseAuth.currentUser;
  }


  @override
  Future<bool> get isAuth async {
    return token != null;
  }

  @override
  Future<bool> get isAppleSignInAvailable async {
    return await SignInWithApple.isAvailable();
  }


  @override
  Future<String?> get token async {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null && _refresh_token != null) {
      return _token;
    }
    refreshSession();
    return null;
  }

  @override
  Future<String?> get userId async {
    if (_userId != null) {
      return _userId;
    }
    return null;
  }


  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<void> authenticate({
    required String email,
    required String password,
    required String urlSegment}) async {

    final Uri url = Uri.parse("https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=$WEB_API_KEY");

    try {
      final response = await http.post(url,
          body: json.encode({
            'email': email,
            'password': password,
            'returnSecureToken': true,
          }));


      final responseData = json.decode(response.body);

      if (responseData['error'] != null) {
        try {
          HttpException(responseData['error']['message'] as String);
        } catch (e) {;
        return;
        }
      }

      _token = responseData['idToken'] as String;
      _refresh_token = responseData['refreshToken'] as String;
      _userId = responseData['localId'] as String;
      _emailAddress = responseData['email'] as String;
      _expiryDate = DateTime.now().add(
          Duration(seconds: int.parse(responseData['expiresIn'] as String)));
      _autoLogout();

      notifyListeners();

      // VERIFY A USERS SIGN-IN TYPE BY CHECKING IN THE USERS FIRESTORE "USERS" DIRECTORY FOR ISREGSTERED AND DOES SNAPSHOT EXIST;
      // IF AND SNAPSHOT EXISTS AND A USERS ISREGISTERED = TRUE, THEN THE USER IS LOGGED IN AS A MANAGER ACCOUNT
      // IF AND SNAPSHOT EXISTS AND A USERS ISREGISTERED = FALSE, THEN THE USER IS LOGGED IN AS AN OCCUPANT

      try {
        final uidSnapshot = await _fireStore.collection('users').doc(_userId).get();
        if (uidSnapshot != null) {
          final verifiedState = uidSnapshot.data()!["isRegistered"] as bool;
          _verified = verifiedState;
        } else {
          _verified = false;
        }
      } catch (e) {
        _verified = false;
      }


      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'refresh_token': _refresh_token,
        'userId': _userId,
        'expiryDate': _expiryDate?.toIso8601String(),
        'verified': _verified,
        'emailAddress': _emailAddress,
      });
      prefs.setString('userData', userData);

    } catch (e) {
      return;
    }

  }


  ///
  /// HANDLE ALL FIREBASE SIGN-IN - REFRESH - AUTO LOGIN -  METHODS:
  ///


  @override
  Future<Either<AuthFailure, Unit>> signInWithEmailAndPassword({
    required EmailAddress emailAddress,
    required String password,
  }) async {

    final emailAddressStr = emailAddress.getOrCrash();
    final passwordStr = password;

    try {
      logout();

      await _firebaseAuth.signInWithEmailAndPassword(
        email: emailAddressStr,
        password: passwordStr,
      );

      await authenticate(email: emailAddressStr,
          password: passwordStr,
          urlSegment: 'signInWithPassword');

      return right(unit);
    } on FirebaseAuthException catch (e) {
      return left(getErrorMessageFromFirebaseException(e));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signInWithApple() async {

    try {

        final rawOnce = generateNonce();
        final nonce = sha256ofString(rawOnce);

        final appleIdCredential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName],
          webAuthenticationOptions: WebAuthenticationOptions(
              clientId: 'com.cico.checkInWebMobileExplore',
              redirectUri: Uri.parse('https://cico-8298b.firebaseapp.com/__/auth/handler')
          ),
          nonce: nonce
        );


        final oAuthProvider = OAuthProvider('apple.com');
        final credential = oAuthProvider.credential(
          idToken: appleIdCredential.identityToken,
          accessToken: appleIdCredential.authorizationCode,
          rawNonce: rawOnce
        );

        final appleCredential = await _firebaseAuth.signInWithCredential(credential);


        if ((appleCredential.additionalUserInfo?.isNewUser ?? false) && appleCredential.user != null) {
          print('new user');
          print(appleCredential.user);
            final givenName = appleIdCredential.givenName;
            final hasGivenName = givenName != null;
            final familyName = appleIdCredential.familyName;
            final hasFamilyName = familyName != null;

            await createUserToFirestore(
                id: appleCredential.user!.uid,
                profile: UserProfileModel(
                    userId: UniqueId.fromUniqueString(appleCredential.user!.uid),
                    legalName: FirstLastName('${hasGivenName ? givenName : ''}'),
                    legalSurname: FirstLastName('${hasFamilyName ? '$familyName' : ''}'),
                    emailAddress: EmailAddress(appleIdCredential.email),
                    isEmailAuth: appleCredential.user?.emailVerified ?? false,
                    isPhoneAuth: false,
                    joinedDate: DateTime.now()
            ));

            await appleCredential.user?.updateDisplayName('${hasGivenName ? givenName : ''}${hasFamilyName ? ' $familyName' : ''}');

        }

        return right(unit);
    } on FirebaseAuthException catch (e) {
      return left(getErrorMessageFromFirebaseException(e));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.unknown) {
        return left(const AuthFailure.exceptionError('Apple Sign In Has Been Cancelled'));
      }
      return left(AuthFailure.exceptionError(e.message));
    }
    catch (e) {
      return left(AuthFailure.exceptionError(e.toString()));
    }

  }

  @override
  Future<Either<AuthFailure, Unit>> signInWithGoogle() async {
      try {

        if (kIsWeb) {
          GoogleAuthProvider authProvider = GoogleAuthProvider();
          final resultWeb = await _firebaseAuth.signInWithPopup(authProvider);

          if ((resultWeb.additionalUserInfo?.isNewUser ?? false) && resultWeb.user != null) {
            await createUserToFirestore(
                id: resultWeb.user!.uid,
                profile: UserProfileModel(
                    userId: UniqueId.fromUniqueString(resultWeb.user!.uid),
                    legalName: FirstLastName(resultWeb.user!.displayName),
                    legalSurname: FirstLastName(''),
                    emailAddress: EmailAddress(resultWeb.user!.email),
                    isEmailAuth: resultWeb.user?.emailVerified ?? false,
                    isPhoneAuth: false,
                    joinedDate: DateTime.now()
              )
            );
          }

          return right(unit);
        }


        final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
        if (googleSignInAccount == null) {
          return left(const AuthFailure.exceptionError('Google Sign In has been Cancelled'));
        }
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleSignInAuthentication.accessToken,
            idToken: googleSignInAuthentication.idToken
        );


        final result = await _firebaseAuth.signInWithCredential(credential);

        if ((result.additionalUserInfo?.isNewUser ?? false) && result.user != null) {
          await createUserToFirestore(
              id: result.user!.uid,
              profile: UserProfileModel(
                  userId: UniqueId.fromUniqueString(result.user!.uid),
                  legalName: FirstLastName(result.user!.displayName),
                  legalSurname: FirstLastName(''),
                  emailAddress: EmailAddress(result.user!.email),
                  isEmailAuth: result.user?.emailVerified ?? false,
                  isPhoneAuth: false,
                  joinedDate: DateTime.now()
            )
          );
        }

        return right(unit);
      } on FirebaseAuthException catch (e) {
        return left(getErrorMessageFromFirebaseException(e));
      } catch (e) {
        return left(AuthFailure.exceptionError(e.toString()));
      }
  } 


  @override
  Future<void> refreshSession() async {
    final Uri url = Uri.parse("https://securetoken.googleapis.com/v1/token?key=$WEB_API_KEY");

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: json.encode({
          'grant_type': 'refresh_token',
          'refresh_token': '[REFRESH_TOKEN]'
        }),
      );
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        try {
          HttpException(responseData['error']['message'] as String);
        } catch (e) {
          return;
        }
      }

      _token = responseData['idToken'] as String;
      _refresh_token = responseData['refreshToken'] as String;
      _userId = responseData['localId'] as String;
      _emailAddress = responseData['email'] as String;
      _expiryDate = DateTime.now().add(Duration(seconds: int.parse(responseData['expiresIn'] as String)));
      _autoLogout();

      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'refresh_token': _refresh_token,
        'userId': _userId,
        'expiryDate': _expiryDate?.toIso8601String(),
        'verified': _verified,
        'emailAddress': _emailAddress,
      });
      prefs.setString('userData', userData);
    } catch (e) {
      return;
    }
  }

  @override
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }
    final extractedUserData = json.decode(prefs.getString('userData')!) as Map<
        String,
        Object>;
    // ignore: cast_nullable_to_non_nullable
    final expiryDate = DateTime.parse(extractedUserData['expiryDate'] as String);

    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }

    _token = extractedUserData['token'] as String;
    _refresh_token = extractedUserData['refresh_token'] as String;
    _userId = extractedUserData['userId'] as String;
    _expiryDate = expiryDate;
    _verified = extractedUserData['verified'] as bool;
    _emailAddress = extractedUserData['email'] as String;
    _verified = extractedUserData['verified'] as bool;

    notifyListeners();
    _autoLogout();
    return true;
  }



  ///
  ///*** HANDLE ALL FIREBASE SIGN-OUT/LOGOUT METHODS: ***///
  ///



  @override
  Future<void> signOut() =>
      Future.wait([
         logout(),
        _firebaseAuth.signOut(),
        _googleSignIn.signOut()
      ]);


  @override
  Future<void> logout() async {
    _token = null;
    _refresh_token = null;
    _userId = null;
    _expiryDate = null;
    _verified = null;
    _emailAddress = null;
    if (_authTimer != null) {
      _authTimer?.cancel();
      _authTimer = null;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');
  }


  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    final timeToExpiry = _expiryDate?.difference(DateTime.now()).inSeconds;
    if (timeToExpiry != null) {
      _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
    }
  }


  /// *** HANDLE FIREBASE WATCH METHODS *** ///

  @override
  Future<Either<AuthFailure, Unit>> validateEmailRegisterer({
    required EmailAddress email}) async {

    final emailAddress = email.value.fold(
            (l) => l.maybeMap(userProfile: (u) => u.f?.maybeMap(invalidEmail: (e) => e.failedValue ?? '', orElse: () => ''), orElse: () => ''),
            (r) => r
    );

    try {

      await _firebaseAuth.createUserWithEmailAndPassword(
        email: emailAddress ?? '',
        password: "password",
      );


      await _firebaseAuth.currentUser?.delete();

      return right(unit);
    } on FirebaseAuthException catch (e) {
      return left(getErrorMessageFromFirebaseException(e));
    }
  }


  /// *** HANDLE FIREBASE PROFILE UPDATE REQUEST METHODS *** ///

  @override
  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail({
    required String email}) async {
    try {
      _firebaseAuth.sendPasswordResetEmail(email: email);
      return right(unit);
    } catch (e) {
      return left(AuthFailure.serverError());
    }
  }


  @override
  Future<Either<AuthFailure, Unit>> verifyAccountWithEmail() async {

    try {
      await _firebaseAuth.currentUser!.sendEmailVerification();
      return right(unit);
    } catch (e) {
      return left(const AuthFailure.cannotSendEmailVerification());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> updateUserPassword({required Password password}) async {

    final passwordStr = password.getOrCrash();

    try {

      await _firebaseAuth.currentUser?.updatePassword(passwordStr);

      return right(unit);
    } on FirebaseAuthException catch (e) {
      return left(getErrorMessageFromFirebaseException(e));
    } on Exception catch (e) {
      return left(AuthFailure.exceptionError('Could not update Password'));
    }

  }



  @override
  Future<Either<AuthFailure, Unit>> updateUserProfile({required UserProfileModel profile, String? profileImageUrl, String? photoIDUrl, String? photoSelfieUrl}) async {
    try {

      var userProfileDto = UserProfileItemDto.fromDomain(profile);
      final userDoc = await _fireStore.userDocument();

      await userDoc.update(userProfileDto.toJson());

      if (profileImageUrl != null) {
        try {
          userProfileDto = userProfileDto.copyWith(
            photoUri: profileImageUrl
          );
           await userDoc.update(userProfileDto.toJson());
          _firebaseAuth.currentUser?.updatePhotoURL(profileImageUrl);
        } catch (e) {
          return left(AuthFailure.serverError());
        }
      }

      /// handle user profile identification request
      if (profile.identificationState != PhotoIdentificationState.accepted || profile.identificationState != PhotoIdentificationState.underReview) {
        updateIdVerification(userProfileDto: userProfileDto, photoIdUrl: photoIDUrl, photoSelfieUrl: photoSelfieUrl);
      }


      return right(unit);
    } catch (f) {
      return left(AuthFailure.serverError());
    }

  }

  Future<Either<AuthFailure, Unit>> updateIdVerification({required UserProfileItemDto userProfileDto, required String? photoIdUrl, required String? photoSelfieUrl}) async {
      try {
        final userDoc = await _fireStore.userDocument();
        if (photoIdUrl != null && photoSelfieUrl != null) {
          userProfileDto = userProfileDto.copyWith(
              photoIdUri: photoIdUrl,
              photoSelfieUri: photoSelfieUrl,
              identificationState: PhotoIdentificationState.underReview.toString()
          );
          await userDoc.update(userProfileDto.toJson());
        }
        return right(unit);
      } catch (e) {
        return left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> updateProfileVerification({required UserProfileModel profile}) async {
    try {

      var userProfileDto = UserProfileItemDto.fromDomain(profile);
      final userDoc = await _fireStore.userDocument();
      await userDoc.update(userProfileDto.toJson());

      return right(unit);
    } catch (e) {
      return left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> updateDefaultPaymentMethod({required UserProfileModel profile}) async {
    try {

      var userProfileDto = UserProfileItemDto.fromDomain(profile);
      final userDoc = await _fireStore.userDocument();
      await userDoc.update(userProfileDto.toJson());

      return right(unit);
    } catch (e) {
      return left(AuthFailure.serverError());
    }
  }


  @override
  Future<Either<AuthFailure, Unit>> updateUserProfileNotifications({required ProfileNotificationItems settings}) async {
    try {

      final userNotificationSettingsDto = ProfileNotificationItemsDto.fromDomain(settings);
      final userDoc = await _fireStore.userDocument();

      await userDoc.update(userNotificationSettingsDto.toJson());

      return right(unit);
    } catch (f) {
      return left(AuthFailure.serverError());
    }

  }


  @override
  Future<Either<AuthFailure, Unit>> updateUserProfileSocials({required SocialsItem socials}) async {
    try {

      print('saving social');

      final userProfileSocialDto = SocialsItemDto.fromDomain(socials);
      final userDoc = await _fireStore.userDocument();

      await userDoc.update(userProfileSocialDto.toJson());

      return right(unit);
    } catch (e) {
      print(e.toString());
      return left(AuthFailure.serverError());
    }
  }



  /// *** HANDLE FIREBASE PROFILE WATCHER STREAMS *** ///

  @override
  Stream<Either<AuthFailure, UserProfileModel>> watchUserProfile() async* {

    try {


      final userData = _firebaseAuth.currentUser;

        yield* _fireStore.collection('users')
            .doc(userData?.uid)
            .snapshots()
            .map((snapshot) => (snapshot.exists) ?
        right(UserProfileItemDto.fromFireStore(snapshot).toDomain()) :
        left(const AuthFailure.profileNotFound()));

    } catch (e) {
      yield left(AuthFailure.serverError());
    }
  }

  @override
  Stream<Either<AuthFailure, UserProfileModel>> watchSelectedUserProfile({required String userId}) async* {

    try {

      yield* _fireStore.collection('users')
          .doc(userId)
          .snapshots()
          .map((snapshot) => snapshot.exists ?
      right(UserProfileItemDto.fromFireStore(snapshot).toDomain()) :
      left(AuthFailure.profileNotFound())
      );
    } catch (e) {
      yield left(AuthFailure.serverError());
    }
  }


  @override
  Stream<Either<AuthFailure, List<UserProfileModel>>> watchAllUserProfiles() async* {
    try {

      yield* _fireStore
          .collection('users')
          .snapshots().map(
              (event) => (event.docs.isNotEmpty) ?
              right<AuthFailure, List<UserProfileModel>>(event.docs.map((profile) {
                if (profile.data().containsKey('gender')) {
                  return UserProfileItemDto.fromFireStore(profile).toDomain();
                } else {
                  return UserProfileModel.empty();
                  }
                }
              ).toList()) :
          left(AuthFailure.serverError())
      );

    } catch (e) {
      yield left(AuthFailure.serverError());
    }
  }


  @override
  Stream<Either<AuthFailure, List<ProfileSession>>> watchUserProfileSessionList({required String userId}) async* {
    try {
      yield* _fireStore.collection('users')
          .doc(userId)
          .sessionDocument
          .snapshots().map((snapshot) => snapshot.docs.isNotEmpty ?
              right<AuthFailure, List<ProfileSession>>(
                  snapshot.docs.map((session) =>
                      ProfileSessionDto.fromFirestore(session).toDomain()).toList()) :
              left(AuthFailure.serverError())
      );
    } catch (e) {
      yield left(AuthFailure.serverError());
    }
  }

  @override
  Stream<Either<AuthFailure, List<LocationModel>>> watchUserProfileLocations({required String userId}) async* {
    try {
      yield* _fireStore.collection('users')
          .doc(userId)
          .locationsDocument
          .snapshots().map((snapshot) => snapshot.docs.isNotEmpty ?
      right<AuthFailure, List<LocationModel>>(
          snapshot.docs.map((location) =>
              LocationModelDto.fromFireStore(location).toDomain()).toList()) :
      left(AuthFailure.serverError())
      );
    } catch (e) {
      yield left(AuthFailure.serverError());
    }
  }


  @override
  Stream<Either<AuthFailure, ProfileNotificationItems>> watchUserProfileNotificationSettings({required String userId}) async* {
    try {

      yield* _fireStore.collection('users')
          .doc(userId)
          .snapshots()
          .map((snapshot) {

        if (snapshot.exists) {
          if (snapshot.data()!.containsKey('notificationsAllowed')) {
            return right(ProfileNotificationItemsDto.fromFireStore(snapshot).toDomain());
          }
          return left(const AuthFailure.noNotificationSettingsFound());
          }
         return left(const AuthFailure.profileNotFound());
        }
      );
      yield left(AuthFailure.serverError());
    } catch (e) {
      yield left(AuthFailure.serverError());
    }
  }


  @override
  Stream<Either<AuthFailure, SocialsItem>> watchUserProfileSocialsSetting({required String userId}) async* {

    try {

      yield* _fireStore.collection('users')
          .doc(userId)
          .snapshots()
          .map((snapshot) {

          if (snapshot.exists) {
            if (snapshot.data()!.containsKey('twitter') || snapshot.data()!.containsKey('facebook') || snapshot.data()!.containsKey('instagram')) {
              return right(SocialsItemDto.fromFireStore(snapshot).toDomain());
            }
            return left(const AuthFailure.noSocialsFound());
          }

          return left(const AuthFailure.profileNotFound());
        }
      );
      yield left(AuthFailure.serverError());
    } catch (e) {
      yield left(AuthFailure.serverError());
    }
  }

  @override
  Stream<Either<AuthFailure, List<UserProfileModel>>> searchAllUsersFromFirebase({required String query}) async* {
    try {

      late Query<Map<String, dynamic>>? fbQuery;


      if (query.contains('@')) {
        fbQuery = _fireStore.collection('users').where('emailAddress', isEqualTo: query);
      }

      if (!query.contains('@')) {
        fbQuery = _fireStore.collection('users').where('legalName', isEqualTo: query);
      }


      if (fbQuery != null) {
       yield* fbQuery.snapshots().map(
              (event) {
            if (event.docs.isNotEmpty) {
              return right<AuthFailure, List<UserProfileModel>>(event.docs.map((user) => UserProfileItemDto.fromFireStore(user).toDomain()).toList());
            }
            return left(const AuthFailure.exceptionError('could not find anyone with that name'));
          });
      }
      yield left(AuthFailure.serverError());
    } catch (e) {
      yield left(AuthFailure.serverError());
    }
  }



  // @override
  // Stream<List<UserProfileModel>> searchFirebaseUsersProfile({required String query}) async* {
  //
  //       yield* _fireStore.collection('users').where('legalName', isGreaterThanOrEqualTo: query.toLowerCase()).where('legalSurname', isGreaterThanOrEqualTo: query.toLowerCase()).snapshots().map(
  //             (event) {
  //               if (event.docs.isNotEmpty) {
  //                 return (event.docs.map((user) => UserProfileItemDto.fromFireStore(user).toDomain()).toList());
  //               }
  //           return [];
  //   });
  // }

}
//
// Stream<List<UserProfileModel>> searchFirebaseUsersProfile({required String query}) async* {
//
//   print(query);
//   yield* FirebaseFirestore.instance.collection('users').where('legalSurname', isGreaterThanOrEqualTo: query).snapshots().map(
//           (event) {
//
//       if (event.docs.isNotEmpty) {
//         return (event.docs.map((user) {
//           print('found');
//           print(user.data()['legalName']);
//           print(user.data()['legalSurname']);
//           print(user.data()['emailAddress']);
//           return UserProfileModel(
//               userId: UniqueId.fromUniqueString(user.id),
//               legalName: FirstLastName(user.data()['legalName'] ?? 'first'),
//               legalSurname: FirstLastName(user.data()['legalSurname'] ?? 'first'),
//               emailAddress: EmailAddress(
//                   user.data()['emailAddress'] ?? 'email'),
//               isEmailAuth: false,
//               isPhoneAuth: false,
//               joinedDate: DateTime.now()
//           );
//         }).toList());
//       }
//       return [];
//    });
//
// }


AuthFailure getErrorMessageFromFirebaseException(FirebaseAuthException e) {
  switch (e.code.toLowerCase()) {
    case 'account-exists-with-different-credential':
      return const AuthFailure.exceptionError('The account already exists, but with different credentials');
    case 'email-already-in-use':
      return const AuthFailure.emailAlreadyInUse('An account already exists for the email you\'re trying to use. Login instead.');
    case 'invalid-email':
      return const AuthFailure.invalidEmailAndPasswordCombination('The email you\'re using is invalid. Please use a valid email.');
    case 'operation-not-allowed':
      return const AuthFailure.operationNotAllowed('The authentication is not enabled on Firebase. Please enable the Authentitcation type on Firebase');
    case 'weak-password':
      return const AuthFailure.weakPassword('Your password is too weak. Please use a stronger password.');
    case 'wrong-password':
      return const AuthFailure.wrongPassword('You seemed to have entered the wrong password. Double check it and try again.');
    case 'permission-denied':
      return const AuthFailure.insufficientPermission();
    default:
      return AuthFailure.serverError();
  }
}