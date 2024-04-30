part of check_in_facade;

@LazySingleton(as: RAuthWatcherFacade)
class ResWatcherFacade implements RAuthWatcherFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;

  ResWatcherFacade(this._fireStore, this._firebaseAuth);

  @override
  Stream<Either<ReservationFormFailure, List<ReservationItem>>> watchReservationFacilityItem({required List<String> facilityId, required String? activityTypeId, required bool? isPublic, required List<ReservationSlotState>? resState}) async* {

    try {
      CollectionReference reference = _fireStore.collection('reservation_directory');
      Query query = reference.where('instanceId', isEqualTo: facilityId.first);


      // .where('reservationState', whereNotIn: [ReservationSlotState.completed.toString()]);
      
      if (activityTypeId != null) {
        query.where('');
      }

      if (isPublic != null) {
        query.where('');
      }

      if (resState != null && resState.isNotEmpty) {
        query = query.where('reservationState', whereIn: resState.map((e) => e.toString()).toList());
      }

      // query.limit(2);

      yield* query.snapshots().map((event) {
            if (event.docs.isNotEmpty) {
              return right<ReservationFormFailure, List<ReservationItem>>(event.docs.map((form) => ReservationItemDto.fromFireStore(form.data() as Map<String, dynamic>).toDomain()).toList());
            }
          return left(const ReservationFormFailure.reservationServerError());
      });

      yield left(const ReservationFormFailure.reservationServerError());
    } catch (e) {
      yield left(const ReservationFormFailure.reservationServerError());
    }

  }

  @override
  Stream<Either<ReservationFormFailure, List<ReservationRequestItem>>> watchReservationRequests() async* {

  }

  @override
  Stream<Either<ReservationFormFailure, List<ReservationItem>>> watchCurrentUserReservationItem({required List<ReservationSlotState> resState, required UserProfileModel currentUser, required bool isResInvitation}) async* {

    try {
      if (isResInvitation) {

        final userItem = StringItemDto(stringItem: currentUser.userId.getOrCrash()).toJson();

        yield* _fireStore
            .collection('reservation_directory')
            .orderBy('createdAtSTC', descending: true)
            .where('reservationState', whereIn: resState.map((e) => e.toString()).toList())
            .where('affiliateIds', arrayContainsAny: [userItem]).snapshots().map(
                (event) {
                  if (event.docs.isNotEmpty) {
                    return right<ReservationFormFailure, List<ReservationItem>>(event.docs.map((form) => ReservationItemDto.fromFireStore(form.data()).toDomain()).toList());
                  }
                  return left(const ReservationFormFailure.reservationServerError(failed: 'no reservations found'));
                });
      } else {
        yield* _fireStore
            .collection('reservation_directory')
            .orderBy('createdAtSTC', descending: true)
            .where('reservationOwnerId', isEqualTo: currentUser.userId.getOrCrash())
            .where('reservationState', whereIn: resState.map((e) => e.toString()).toList())
            .snapshots().map((event) {
          if (event.docs.isNotEmpty) {
            return right<ReservationFormFailure, List<ReservationItem>>(event.docs.map((form) {
              final data = form.data();
              data['affiliates'] = [];

              return ReservationItemDto.fromFireStore(form.data()).toDomain();
              }
            ).toList());
          }
          return left(const ReservationFormFailure.reservationServerError(failed: 'no reservations found'));
        });
      }
    } catch (e) {
      yield left(ReservationFormFailure.reservationServerError(failed: e.toString()));
    }
  }

  @override
  Stream<Either<ReservationFormFailure, List<Post>>> watchReservationPostItems({required String? reservationId}) async* {
    try {

      var query = _fireStore
          .collection('reservation_post')
          .where('reservationId', isEqualTo: '$reservationId');
          // .orderBy('createdAtSTC', descending: true);
      
      yield* query.snapshots().map((event) {
         if (event.docs.isNotEmpty) {
           return right<ReservationFormFailure, List<Post>>(event.docs.map((post) => PostDto.fromFireStore(post).toDomain()).toList().where((element) => element.reservationId == reservationId).toList());
         }
         return left(const ReservationFormFailure.reservationServerError(failed: 'no posts found'));
        }
      );
    } catch (e) {
      yield left(ReservationFormFailure.reservationServerError(failed: e.toString()));
    }
  }

  @override
  Stream<Either<ReservationFormFailure, ReservationItem>> watchCurrentReservationItem({required String reservationId}) async* {
    try {

      var query = _fireStore
          .collection('reservation_directory')
          .doc(reservationId);


      yield* query.snapshots().map((event) {
        if (event.data() != null && event.exists) {
          return right<ReservationFormFailure, ReservationItem>(ReservationItemDto.fromFireStore(event.data()!).toDomain());
          }
        return left(const ReservationFormFailure.reservationServerError(failed: 'reservation not found'));
        }
      );
      yield left(const ReservationFormFailure.reservationServerError(failed: 'reservation not found'));
    } catch (e) {
      yield left(ReservationFormFailure.reservationServerError(failed: e.toString()));
    }
  }

  @override
  Stream<Either<ReservationFormFailure, List<ReservationItem>>> watchDiscoveryReservationItems({required List<ReservationSlotState> resState, required int? hoursTimeAhead, required int? hoursTimeBefore}) async* {
    
    try {
       var query = _fireStore.collection('reservation_directory')
       .where('reservationState', whereIn: resState.map((e) => e.toString()).toList());
       // .where('firstSlotTimestamp', isLessThan: DateTime.now().add(Duration(hours: hoursTimeAhead ?? 0)).millisecondsSinceEpoch);


       if (hoursTimeAhead != null && hoursTimeBefore == null) {
           /// exclude any reservation that are greater than x hours from now
           query = query.where('firstSlotTimestamp', isLessThan: DateTime.now().add(Duration(hours: hoursTimeAhead)).millisecondsSinceEpoch);
        }

        if (hoursTimeBefore != null && hoursTimeAhead == null) {
          /// exclude any reservations that are less than x number of hours
          query = query.where('lastSlotTimestamp', isGreaterThan: DateTime.now().subtract(Duration(hours: hoursTimeBefore)).millisecondsSinceEpoch);
        }



        // query.orderBy('reservationReview', descending: true);

        yield* query.snapshots().map(
              (event) {
            if (event.docs.isNotEmpty) {
              return right<ReservationFormFailure, List<ReservationItem>>(event.docs.map((form) => ReservationItemDto.fromFireStore(form.data()).toDomain()).toList());
            }
            return left(const ReservationFormFailure.reservationServerError(failed: 'no reservations found'));
          });

      yield left(const ReservationFormFailure.reservationServerError(failed: 'reservation not found'));
    } catch (e) {
      yield left(ReservationFormFailure.reservationServerError(failed: e.toString()));
    }
  }
}



class ReservationFacade {

  ReservationFacade._privateConstructor() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      firebaseUser = user;
    });
  }

  /// Current logged in user in Firebase. Does not update automatically.
  /// Use [FirebaseAuth.authStateChanges] to listen to the state changes.
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  DocumentSnapshot? lastDoc = null;

  /// Gets proper [FirebaseFirestore] instance.
  FirebaseFirestore getFirebaseFirestore() => FirebaseFirestore.instance;


  static final ReservationFacade instance = ReservationFacade._privateConstructor();

  Future<int> getNumberOfReservationsBooked({
  required String? listingId,
  required List<ReservationSlotState> statusType,
  required int? hoursTimeAhead,
  required int? hoursTimeBefore,
  }) async  {

    var query = getFirebaseFirestore().collection('reservation_directory')
        .where('reservationState', whereIn: statusType.map((e) => e.toString()).toList());

    if (listingId != null) {
      query = query.where('instanceId', isEqualTo: listingId);
    }

    if (hoursTimeAhead != null && hoursTimeBefore == null) {
      /// exclude any reservation that are greater than x hours from now
      query = query.where('firstSlotTimestamp', isLessThan: DateTime.now().add(Duration(hours: hoursTimeAhead)).millisecondsSinceEpoch);
    }

    if (hoursTimeBefore != null && hoursTimeAhead == null) {
      /// exclude any reservations that are less than x number of hours
      query = query.where('lastSlotTimestamp', isGreaterThan: DateTime.now().subtract(Duration(hours: hoursTimeBefore)).millisecondsSinceEpoch);
    }

    final numberOfReservations = await query.count().get();

    return numberOfReservations.count ?? 0;
}


Future<(List<ReservationItem>, DocumentSnapshot?)> getAllReservations({
  required List<ReservationSlotState> statusType,
  required int? hoursTimeAhead,
  required int? hoursTimeBefore,
  required int? limit,
  required DocumentSnapshot<Object?>? startAfterDoc
  }) async {

  var query = getFirebaseFirestore().collection('reservation_directory')
      .where('reservationState', whereIn: statusType.map((e) => e.toString()).toList());

  query = query.where('isActivity', isEqualTo: true);

  if (hoursTimeAhead != null && hoursTimeBefore == null) {
    /// exclude any reservation that are greater than x hours from now
    query = query.where('firstSlotTimestamp', isLessThan: DateTime.now().add(Duration(hours: hoursTimeAhead)).millisecondsSinceEpoch);
  }

  if (hoursTimeBefore != null && hoursTimeAhead == null) {
    /// exclude any reservations that are less than x number of hours
    query = query.where('lastSlotTimestamp', isGreaterThan: DateTime.now().subtract(Duration(hours: hoursTimeBefore)).millisecondsSinceEpoch);
  }


  if (limit != null) {
    query = query.limit(limit);
  }


  final reservations = startAfterDoc != null
      ? await query.startAfterDocument(startAfterDoc).get()
      : await query.get();


  final finalDoc = reservations.docs.length == limit ? reservations.docs.last : null;

  return (
    reservations.docs.map((e) => processReservationItem(e)).toList(),
    finalDoc
  );
}


Future<List<ReservationItem>> getReservationsBooked({
  required String listingId,
  required List<ReservationSlotState> statusType,
  required int? hoursTimeAhead,
  required int? hoursTimeBefore,
}) async {

  var query = getFirebaseFirestore().collection('reservation_directory')
      .where('reservationState', whereIn: statusType.map((e) => e.toString()).toList())
      .where('instanceId', isEqualTo: listingId);


  if (hoursTimeAhead != null && hoursTimeBefore == null) {
    /// exclude any reservation that are greater than x hours from now
    query = query.where('firstSlotTimestamp', isLessThan: DateTime.now().add(Duration(hours: hoursTimeAhead)).millisecondsSinceEpoch);
  }

  if (hoursTimeBefore != null && hoursTimeAhead == null) {
    /// exclude any reservations that are less than x number of hours
    query = query.where('lastSlotTimestamp', isGreaterThan: DateTime.now().subtract(Duration(hours: hoursTimeBefore)).millisecondsSinceEpoch);
  }



  final reservations = await query.get();

  return reservations.docs.map((e) => processReservationItem(e)).toList();
}

Future<ReservationItem?> getReservationItem({required String resId}) async {
    var query = getFirebaseFirestore().collection('reservation_directory').doc(resId);
    try {

      final reservation = await query.get();

      return (reservation.data() != null) ? processReservationItem(reservation) : null;
    } catch (e) {
      return null;
    }
}


ReservationItem processReservationItem(DocumentSnapshot<Map<String, dynamic>> query) {
  return ReservationItemDto.fromJson(query.data()!).toDomain();
}


}

