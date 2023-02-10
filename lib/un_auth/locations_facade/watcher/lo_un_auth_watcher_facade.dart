part of check_in_facade;

abstract class LoUnAuthWatcherFacade {

  Stream<Either<FacilityFormFailure, List<LocationModel>>> watchLocationDirectory();
  Stream<Either<FacilityFormFailure, LocationModel>> watchLocationItem({required String locationId});

}