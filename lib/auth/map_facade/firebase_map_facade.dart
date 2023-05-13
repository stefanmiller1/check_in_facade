part of check_in_facade;

class FirebaseMapFacade {

  FirebaseMapFacade._privateConstructor() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      firebaseUser = user;
    });
  }

  /// Current logged in user in Firebase. Does not update automatically.
  /// Use [FirebaseAuth.authStateChanges] to listen to the state changes.
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  /// Gets proper [FirebaseFirestore] instance.
  FirebaseFirestore getFirebaseFirestore() => FirebaseFirestore.instance;

  /// Singleton instance.
  static final FirebaseMapFacade instance =
  FirebaseMapFacade._privateConstructor();

  /// Returns a stream of listings either based on facility or activity for [GoogleMap] markers to be displayed.
  Stream<List<ListingManagerForm>> mapListings({
    required double latitude,
    required double longitude,
    double? selectedRadius,
    String? selectedActivityType,
    String? selectedCityRegion,
    String? selectedProvinceState,
    String? selectedCountry,
}) {

    final fu = firebaseUser;
    if (fu == null) return const Stream.empty();

    print('thhtrdhrd');
    print(latitude);
    print(longitude);

    final geo = Geoflutterfire();
    var radius = selectedRadius ?? 50 * 1000;
    GeoFirePoint center = geo.point(latitude: latitude, longitude: longitude);

    var collectionRef =  getFirebaseFirestore().collection('listing_directory');
    // /// filter by activity types offered by listed facility.
    // if (selectedActivityType != null) {
    //   collectionRef.where('listingProfileService.spaceSetting.activitiesAllowed', arrayContains: [selectedActivityType]);
    // }

    // /// filter by city, region or country.
    if (selectedCityRegion != null) {
      collectionRef.where('listingProfileService.listingLocationSetting.city', isEqualTo: selectedCityRegion);
    } else if (selectedProvinceState != null) {
      collectionRef.where('listingProfileService.listingLocationSetting.provinceState', isEqualTo: selectedProvinceState);
    } else if (selectedCountry != null) {
      collectionRef.where('listingProfileService.listingLocationSetting.countryRegion', isEqualTo: selectedCountry);
    }

      var query = geo.collection(collectionRef: collectionRef).within(
          center: center,
          radius: radius,
          field: 'listingProfileService.listingLocationSetting.locationPosition');

      return query.map((event) {
        return processListingsQuery(event);
      }
    );
  }

  List<ListingManagerForm> processListingsQuery(
  List<DocumentSnapshot<Map<String, dynamic>>> query
  ) {
    final futures = query.map((snapshot) {
      // if (snapshot.exists && snapshot.data() != null) {
          return ListingManagerFormDto.fromJson(snapshot.data()!).toDomain();
        // }
      }
    ).toList();

    return futures;
  }

}