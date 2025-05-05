part of check_in_facade;

abstract class LOAuthFacade {

  /// *** LOCATION CREATOR EVENTS *** ///

  Future<Either<AuthFailure, LocationModel>> createNewProfileLocationAuth({
    required LocationModel location});

  Future<Either<AuthFailure, Unit>> createNewLocationFacilitySession({
    required ProfileSession sessionProfile});

  Future<Either<AuthFailure, Unit>> deleteProfileLocationAuth({
    required String locationId
  });

}