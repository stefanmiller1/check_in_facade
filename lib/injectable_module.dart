part of check_in_facade;

@module
abstract class FirebaseInjectableModule {

  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;
  @lazySingleton
  FirebaseFirestore get fireStore => FirebaseFirestore.instance;
  @lazySingleton
  FirebaseFunctions get firebaseFunctions => FirebaseFunctions.instance;
  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn(
    scopes: [
      'email',
    ],
    clientId: aOAUTH_CLIENT_ID,
  );
}