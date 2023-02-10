part of check_in_facade;
/// watcher and updates that can be made without database authentication

@injectable
@LazySingleton(as: UAuthFacade)
class UnAuthFacade implements UAuthFacade {

  @override
  Stream<Either<AuthFailure, int>> watchOwnersCurrentFacilityBookingsCount({
    required UniqueId currentOwner,
    required UniqueId bookingId,
    required String facilityType,
  }) async* {
    try {

      yield right(2);
    } catch (e) {
      yield left(AuthFailure.serverError());
    }


  }


  @override
  Stream<Either<AuthFailure, int>> watchOwnersCurrentActivitiesBookingsCount({
    required UniqueId currentOwner,
    required UniqueId bookingId,
    required String activityType,
  }) async* {
    // TODO: implement watchOwnersCurrentActivitiesBookingsCount
    throw UnimplementedError();
  }



  /// check sessions by session type
  @override
  Stream<Either<AuthFailure, int>> watchOwnersCurrentSessionsBookingsCount({
    required UniqueId currentOwner,
    required UniqueId bookingId,
    required String sessionType
  }) async* {



  }





}