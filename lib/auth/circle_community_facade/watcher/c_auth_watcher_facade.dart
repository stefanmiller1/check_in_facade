part of check_in_facade;

@LazySingleton(as: CAuthWatcherFacade)
class CommunityWatcherFacade implements CAuthWatcherFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;

  CommunityWatcherFacade(
      this._fireStore,
      this._firebaseAuth
    );

  @override
  Stream<Either<ProfileValueFailure, List<UniqueId>>> watchLinkedReservationCirclesCommunities({required UniqueId reservationId}) async* {
     try {
       
       yield* _fireStore.collection('activity_directory').doc(reservationId.getOrCrash()).collection('linked_community').snapshots().map(
               (event) {
                 if (event.docs.isNotEmpty) {
                   return right<ProfileValueFailure, List<UniqueId>>(event.docs.map((form) => UniqueId.fromUniqueString(form.id)).toList());
           }
           return left(const ProfileValueFailure.profileServerError(serverResponse: 'no communities found'));
         });
     } catch (e) {
        yield left(ProfileValueFailure.profileServerError(serverResponse: e.toString()));
     }
  }


  @override
  Stream<Either<ProfileValueFailure, CircleProfileItemDto>> watchCurrentCircleCommunity({required UniqueId communityId}) {
    // TODO: implement watchCurrentCommunity
    throw UnimplementedError();
  }

  @override
  Stream<Either<ProfileValueFailure, List<CircleProfileItemDto>>> watchCurrentUsersCreatedCircleCommunities() {
    // TODO: implement watchCurrentUsersCreatedCommunities
    throw UnimplementedError();
  }

  @override
  Stream<Either<ProfileValueFailure, List<UniqueId>>> watchCurrentUserJoinedCircleCommunities() {
    // TODO: implement watchCurrentUserJoinedCommunities
    throw UnimplementedError();
  }



}