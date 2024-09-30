part of check_in_facade;

@LazySingleton(as: MVAuthWatcherFacade)
class MerchVendorAuthWatcherFacade implements MVAuthWatcherFacade {

  final FirebaseFirestore _fireStore;

  MerchVendorAuthWatcherFacade(
      this._fireStore
    );

  @override
  Stream<Either<ProfileValueFailure, List<EventMerchantVendorProfile>>> watchAllEventMerchProfiles({required List<String> profileIds}) async* {
    try {
      if (profileIds.isEmpty) {
        yield left(const ProfileValueFailure.profileServerError(serverResponse: 'no profile found'));
        return;
      }

      yield* _fireStore.collection('vendor_merch_profile').where('profileId', whereIn: profileIds).snapshots().map(
              (event) {
        if (event.docs.isNotEmpty) {
          return right<ProfileValueFailure, List<EventMerchantVendorProfile>>(event.docs.map((e) => EventMerchantVendorProfileDto.fromFireStore(e.data()).toDomain()).toList());
        }
        return left(const ProfileValueFailure.profileServerError(serverResponse: 'no profiles found'));
      });

      yield left(const ProfileValueFailure.profileServerError(serverResponse: 'no profile found'));
    } catch (e) {
      print(e);
      yield left(ProfileValueFailure.profileServerError(serverResponse: e.toString()));
    }
  }

  @override
  Stream<Either<ProfileValueFailure, EventMerchantVendorProfile>> watchEventMerchProfile({required String profileId}) async* {
     try {

       yield* _fireStore.collection('vendor_merch_profile').doc(profileId).snapshots().map(
             (event) {
             if (event.exists && event.data() != null) {
               return right<ProfileValueFailure, EventMerchantVendorProfile>(EventMerchantVendorProfileDto.fromFireStore(event.data()!).toDomain());
             }
             return left(ProfileValueFailure.profileServerError(serverResponse: 'no profile found'));
         });

       yield left(ProfileValueFailure.profileServerError(serverResponse: 'no profile found'));
     } catch (e) {
       yield left(ProfileValueFailure.profileServerError(serverResponse: e.toString()));
     }
  }

  @override
  Stream<Either<ProfileValueFailure, List<EventMerchantVendorProfile>>> watchCurrentUsersMerchVendorList({required String userId}) async* {
    try {


      yield* _fireStore
            .collection('vendor_merch_profile')
            .where('profileOwner', isEqualTo: userId).snapshots().map(
              (event) {
                if (event.docs.isNotEmpty) {
                  return right<ProfileValueFailure, List<EventMerchantVendorProfile>>(event.docs.map((e) => EventMerchantVendorProfileDto.fromFireStore(e.data()).toDomain()).toList());
              }
                return left(const ProfileValueFailure.profileServerError(serverResponse: 'no profiles found'));
          });
      
      yield left(const ProfileValueFailure.profileServerError(serverResponse: 'no profiles found'));
    } catch (e) {
      yield left(ProfileValueFailure.profileServerError(serverResponse: e.toString()));
    }
  }

  @override
  Stream<Either<ProfileValueFailure, List<UniqueId>>> watchCurrentPartnersMerchVendors({required String profileId}) async* {
    try {

      yield* _fireStore.collection('vendor_merch_profile').doc(profileId).collection('partners').snapshots().map(
              (event) {
            if (event.docs.isNotEmpty) {
              return right<ProfileValueFailure, List<UniqueId>>(event.docs.map((e) => UniqueId.fromUniqueString(StringItemDto.fromJson(e.data()).toDomain())).toList());
            }
            return left(ProfileValueFailure.profileServerError(serverResponse: 'no partners found'));
          });

      yield left(ProfileValueFailure.profileServerError(serverResponse: 'no partners found'));
    } catch (e) {
      yield left(ProfileValueFailure.profileServerError(serverResponse: e.toString()));
    }
  }
}

class MerchVenFacade {

  MerchVenFacade._privateConstructor() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      firebaseUser = user;
    });
  }

  /// Current logged in user in Firebase. Does not update automatically.
  /// Use [FirebaseAuth.authStateChanges] to listen to the state changes.
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  DocumentSnapshot? lastDoc = null;

  /// Gets proper [FirebaseFirestore] instance.
  FirebaseFirestore getFirebaseFirestore() => FirebaseFirestore.instance;

  static final MerchVenFacade instance = MerchVenFacade._privateConstructor();


  Future<EventMerchantVendorProfile?> getMerchVendorProfile({
    required String profileId,
    }) async {

    try {

      final profile = await getFirebaseFirestore().collection('vendor_merch_profile').doc(profileId).get();

      return (profile.data() != null) ? processProfileItem(profile) : null;
    } catch (e) {
      return null;
    }
  }


  EventMerchantVendorProfile processProfileItem(DocumentSnapshot<Map<String, dynamic>> query) {
    return EventMerchantVendorProfileDto.fromJson(query.data()!).toDomain();
  }

}