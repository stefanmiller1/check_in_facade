part of check_in_facade;

abstract class CAuthWatcherFacade {

  Stream<Either<ProfileValueFailure, List<UniqueId>>> watchLinkedReservationCirclesCommunities({required UniqueId reservationId});
  Stream<Either<ProfileValueFailure, CircleProfileItemDto>> watchCurrentCircleCommunity({required UniqueId communityId});
  Stream<Either<ProfileValueFailure, List<CircleProfileItemDto>>> watchCurrentUsersCreatedCircleCommunities();
  Stream<Either<ProfileValueFailure, List<UniqueId>>> watchCurrentUserJoinedCircleCommunities();

}