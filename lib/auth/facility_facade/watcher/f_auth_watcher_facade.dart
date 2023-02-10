part of check_in_facade;


abstract class FAuthWatcherFacade {

  /// facility items watcher events ///
  Stream<Either<FacilityFormFailure, FacilityCreatorForm>> watchFacilityCreatorForm({required String facilityId});
  Stream<Either<FacilityFormFailure, List<FacilityCreatorForm>>> watchAllFacilityCreatorForms();


}
