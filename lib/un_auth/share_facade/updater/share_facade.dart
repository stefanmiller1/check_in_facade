part of check_in_facade;

class ShareFacadeCore {
  ShareFacadeCore._privateConstructor() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      firebaseUser = user;
    });
  }

  /// Use [FirebaseAuth.authStateChanges] to listen to the state changes.
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  /// Singleton instance.
  static final ShareFacadeCore instance = ShareFacadeCore._privateConstructor();

  FirebaseFunctions getFirebaseFunctions() => FirebaseFunctions.instance;
  FirebaseFirestore getFirebaseFireStore() => FirebaseFirestore.instance;

  Future<String> generateAndShareLink({
    required String title,
    required String description,
    required String imageUrl,
    required appLinkRoute,
  }) async {
    // Define the Cloud Function URL
    final functionUrl = getFirebaseFunctions().httpsCallable('generateMetadata');

    String uniqueId = UniqueId().getOrCrash().substring(0, 8);
    String appLink = appLinkRoute;

    // Construct the request URL for the cloud function
    Map<String, String> metadata = {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'appLink': appLink,
    };

    try {
      final response = await functionUrl.call({'id': uniqueId, 'metadata': metadata});

      if (response.data['error'] != null) {
        return Future.error(response.data['error'] ?? 'error');
      }

      // Share the URL (use any sharing plugin)
      // For example, using the share package:
      // Share.share(shortUrl);

      String shortUrl = 'https://cincout.ca/$uniqueId';
      return shortUrl;
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  Future<String> retrieveAppLinkFromId({required linkId}) async {
      try {
        final appLinkData = await getFirebaseFireStore().collection('appLink_metadata').doc(linkId).get();

        if (appLinkData['appLink'] == null) {
          return Future.error(e.toString());
        }

        return appLinkData['appLink'];
      } catch (e) {
        return Future.error(e.toString());
      }
  }
}