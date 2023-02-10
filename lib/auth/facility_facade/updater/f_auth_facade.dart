part of check_in_facade;

abstract class FAuthFacade {

  /// *** FACILITY CREATOR EVENTS *** ///

  Future<Either<FacilityFormFailure, Unit>> createFacilityForm({
    required FacilityCreatorForm facilityForm,
  });

  Future<Either<FacilityFormFailure, Unit>> createCompletedFacilityForm({
    required FacilityCreatorForm facilityForm,
  });

}