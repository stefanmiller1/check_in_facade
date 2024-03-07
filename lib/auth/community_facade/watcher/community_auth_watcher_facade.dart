part of check_in_facade;

abstract class CAuthWatcherFacade {

  Stream<Either<CommunityProfileFailure, List<UniqueId>>> watchLinkedReservationCommunities({required UniqueId reservationId});
  Stream<Either<CommunityProfileFailure, CommunityProfileItem>> watchCurrentCommunity({required UniqueId communityId});
  Stream<Either<CommunityProfileFailure, List<CommunityProfileItem>>> watchCurrentUsersCreatedCommunities();
  Stream<Either<CommunityProfileFailure, List<UniqueId>>> watchCurrentUserJoinedCommunities();

}