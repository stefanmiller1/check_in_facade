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
  Stream<Either<CommunityProfileFailure, List<UniqueId>>> watchLinkedReservationCommunities({required UniqueId reservationId}) async* {
     try {
       
       yield* _fireStore.collection('activity_directory').doc(reservationId.getOrCrash()).collection('linked_community').snapshots().map(
               (event) {
                 if (event.docs.isNotEmpty) {
                   return right<CommunityProfileFailure, List<UniqueId>>(event.docs.map((form) => UniqueId.fromUniqueString(form.id)).toList());
           }
           return left(const CommunityProfileFailure.communityServerError(serverResponse: 'no communities found'));
         });
     } catch (e) {
        yield left(CommunityProfileFailure.communityServerError(serverResponse: e.toString()));
     }
  }


  @override
  Stream<Either<CommunityProfileFailure, CommunityProfileItem>> watchCurrentCommunity({required UniqueId communityId}) {
    // TODO: implement watchCurrentCommunity
    throw UnimplementedError();
  }

  @override
  Stream<Either<CommunityProfileFailure, List<CommunityProfileItem>>> watchCurrentUsersCreatedCommunities() {
    // TODO: implement watchCurrentUsersCreatedCommunities
    throw UnimplementedError();
  }

  @override
  Stream<Either<CommunityProfileFailure, List<UniqueId>>> watchCurrentUserJoinedCommunities() {
    // TODO: implement watchCurrentUserJoinedCommunities
    throw UnimplementedError();
  }



}