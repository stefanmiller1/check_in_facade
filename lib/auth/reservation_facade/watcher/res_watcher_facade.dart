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
  Stream<Either<ReservationFormFailure, List<ReservationItem>>> watchCurrentUserReservationItem({required List<ReservationSlotState> resState, required UserProfileModel currentUser, required bool isResInvitation, required int? limit, required bool? isActivity}) async* {

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

        var query = _fireStore.collection('reservation_directory').orderBy('createdAtSTC', descending: true);
        query = query.where('reservationOwnerId', isEqualTo: currentUser.userId.getOrCrash());
        query = query.where('reservationState', whereIn: resState.map((e) => e.toString()).toList());

        if (limit != null) {
          query = query.limit(limit);
        }
        if (isActivity != null) {
          query = query.where('isActivity', isEqualTo: isActivity);
        }

    yield* query.snapshots().map((event) {
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
  Stream<Either<ReservationFormFailure, List<ReservationItem>>> watchDiscoveryReservationItems({required List<ReservationSlotState> resState, required int? hoursTimeAhead, required int? hoursTimeBefore, required bool? isActivity}) async* {
    
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

        if (isActivity != null) {
          query = query.where('isActivity', isEqualTo: isActivity);
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
  required String? userId,
  required List<ReservationSlotState> statusType,
  required int? hoursTimeAhead,
  required int? hoursTimeBefore,
  required bool? isActivity,
  }) async  {

    var query = getFirebaseFirestore().collection('reservation_directory')
        .where('reservationState', whereIn: statusType.map((e) => e.toString()).toList());

    if (listingId != null) {
      query = query.where('instanceId', isEqualTo: listingId);
    }

    if (userId != null) {
      query = query.where('reservationOwnerId', isEqualTo: userId);
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

  Future<List<ReservationPreviewer>> getReservationsFromAttendingIds(List<UniqueId> reservationIds) async {
    List<ReservationPreviewer> resToPreview = [];

    for (UniqueId reservationId in reservationIds) {
      try {
        // Fetch reservation details
        final reservationItem = await getReservationItem(resId: reservationId.getOrCrash());
        if (reservationItem == null) {
          continue; // Skip to the next reservation if item is null
        }

        // Process reservation details and add to list
        ReservationPreviewer resPreview = ReservationPreviewer(
          reservation: reservationItem,
          previewWeight: 0, // Example weight, modify as needed
        );

        // Additional data fetching and processing
        try {
          final listingManagerForm = await ListingFacade.instance.getListingManagerItem(listingId: reservationItem.instanceId.getOrCrash());
          resPreview = resPreview.copyWith(listing: listingManagerForm);
        } catch (e) {
          print('Error fetching listing: $e');
        }

        try {
          final reservationOwnerProfile = await UserProfileFacade.instance.getCurrentUserProfile(userId: reservationItem.reservationOwnerId.getOrCrash());
          resPreview = resPreview.copyWith(reservationOwnerProfile: reservationOwnerProfile);
        } catch (e) {
          print('Error fetching owner profile: $e');
        }

        try {
          final activityManagerForm = await ActivitySettingsFacade.instance.getActivitySettings(reservationId: reservationItem.reservationId.getOrCrash());
          resPreview = resPreview.copyWith(activityManagerForm: activityManagerForm);
        } catch (e) {
          print('Error fetching activity settings: $e');
        }

        resToPreview.add(resPreview);
      } catch (e) {
        print('Error processing reservation: $e');
      }
    }
    return resToPreview;
  }

  Future<List<ReservationPreviewer>> listOfAttendingReservationItemsFiltered(
      {required ContactStatus? status,
        required AttendeeType? attendingType,
        required bool? isInterested
      }) async {

    try {
      final List<AttendeeItem> newAttendeeItems = await AttendeeFacade.instance.getCurrentUserAttending(status: status, attendingType: attendingType, isInterested: isInterested, limit: null);

      List<ReservationPreviewer> reservations = [];

      for (AttendeeItem attendeeItem in newAttendeeItems) {

        if (!reservations.map((e) => e.reservation!.reservationId).contains(attendeeItem.reservationId)) {
          final ReservationItem? res = await getReservationItem(resId: attendeeItem.reservationId.getOrCrash());

          if (res != null) {



            final ActivityManagerForm? activity = await ActivitySettingsFacade.instance.getActivitySettings(reservationId: res.reservationId.getOrCrash());
            if (activity != null) {
              ReservationPreviewer resPreviewer = ReservationPreviewer(
                  reservation: res,
                  activityManagerForm: activity,
                  attendingItem: attendeeItem,
                  previewWeight: 0
              );

              try {
                final listingManagerForm = await ListingFacade.instance.getListingManagerItem(listingId: res.instanceId.getOrCrash());
                resPreviewer = resPreviewer.copyWith(
                    listing: listingManagerForm
                );
              } catch (e) {}

              try {
                final reservationOwnerProfile = await UserProfileFacade.instance.getCurrentUserProfile(userId: res.reservationOwnerId.getOrCrash());
                resPreviewer = resPreviewer.copyWith(
                    reservationOwnerProfile: reservationOwnerProfile
                );

              } catch(e) {}

              reservations.add(resPreviewer);
            }
          }
        } else if (newAttendeeItems.length != reservations.length) {
          reservations.removeWhere((element) => element.reservation!.reservationId != attendeeItem.reservationId);
        } else if (!listEquals(newAttendeeItems.map((e) => e).toList(), reservations.map((e) => e.attendingItem).toList())) {
          reservations.removeWhere((element) => !newAttendeeItems.contains(element.attendingItem));
        }
      }

      return reservations;
    } catch (e) {
      return [];
    }
  }


Future<(List<ReservationItem>, DocumentSnapshot?)> getAllReservations({
  required List<ReservationSlotState> statusType,
  required int? hoursTimeAhead,
  required int? hoursTimeBefore,
  required bool? isActivity,
  required int? limit,
  required bool? isLookingForVendor,
  required String? userId,
  required DocumentSnapshot<Object?>? startAfterDoc
  }) async {

  var query = getFirebaseFirestore().collection('reservation_directory')
      .orderBy('createdAtSTC', descending: true)
      .where('reservationState', whereIn: statusType.map((e) => e.toString()).toList());


  if (isActivity != null) {
    query = query.where('isActivity', isEqualTo: isActivity);
  }

  if (userId != null) {
    query = query.where('reservationOwnerId', isEqualTo: userId);
  }
  if (hoursTimeAhead != null && hoursTimeBefore == null) {
    /// exclude any reservation that are greater than x hours from now
    query = query.where('firstSlotTimestamp', isLessThan: DateTime.now().add(Duration(hours: hoursTimeAhead)).millisecondsSinceEpoch);
  }

  if (hoursTimeBefore != null && hoursTimeAhead == null) {
    /// exclude any reservations that are less than x number of hours
    query = query.where('lastSlotTimestamp', isGreaterThan: DateTime.now().subtract(Duration(hours: hoursTimeBefore)).millisecondsSinceEpoch);
  }

  if (isLookingForVendor != null && isLookingForVendor != false) {
    query = query.where('isLookingForVendor', isEqualTo: isLookingForVendor);
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
  required bool? isActivity,
}) async {

  var query = getFirebaseFirestore().collection('reservation_directory')
      .where('reservationState', whereIn: statusType.map((e) => e.toString()).toList())
      .where('instanceId', isEqualTo: listingId)
      .where('isActivity', isEqualTo: isActivity);


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

Future<ReservationItem> getReservationItem({required String resId}) async {
    var query = getFirebaseFirestore().collection('reservation_directory').doc(resId);
    try {

      final reservation = await query.get();

      if (reservation.data() == null) {
        return Future.error('cannot find reservation');
      }

      return processReservationItem(reservation);
    } catch (e) {
      return Future.error('cannot find reservation');
    }
}


ReservationItem processReservationItem(DocumentSnapshot<Map<String, dynamic>> query) {
  return ReservationItemDto.fromJson(query.data()!).toDomain();
}


}

