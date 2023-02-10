part of check_in_facade;

@injectable
@LazySingleton(as: LOAuthFacade)
class LocationAuthFacade implements LOAuthFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;

  LocationAuthFacade(
      this._fireStore,
      this._firebaseAuth
      );

  @override
  Future<Either<AuthFailure, Unit>> createNewLocationFacilitySession({required ProfileSession sessionProfile}) async {

    final facilityId = sessionProfile.profileSessionId.getOrCrash();

    try {

      final locationDoc = await _fireStore.locationsDocument(facilityId);

      final profileSessionDto = ProfileSessionDto.fromDomain(sessionProfile).toJson();
      await locationDoc.locationsDocument.doc(facilityId).set(profileSessionDto);

      return right(unit);
    }  catch (e) {
      return left(AuthFailure.serverError());
    }
  }


  @override
  Future<Either<AuthFailure, Unit>> createNewProfileLocationAuth({required LocationModel location}) async {
    final facilityId = location.placeId;
    final currentUserId = _firebaseAuth.currentUser;

    try {

      final userDoc = await _fireStore.userDocument();
      final locationDoc = await _fireStore.locationsDocument(facilityId);

      // final profileLocation = LocationModel(
      //     ownerId: currentUserId!.uid,
      //     placeId: facilityId,
      //
      //     locationType: location.locationType
      // );
      final profileLocationDto = LocationModelDto.fromDomain(location).toJson();
      final locationDto = LocationModelDto.fromDomain(location).toJson();

      await userDoc.locationsDocument.doc(facilityId).set(profileLocationDto);
      await locationDoc.set(locationDto);

      return right(unit);
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        return left(AuthFailure.insufficientPermission());
      }
      return left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> deleteProfileLocationAuth({required String locationId}) {
    // TODO: implement deleteProfileLocationAuth
    throw UnimplementedError();
  }


}