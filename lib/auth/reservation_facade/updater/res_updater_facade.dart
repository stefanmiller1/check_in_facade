part of check_in_facade;

@LazySingleton(as: RUpdaterFacade)
class ResUpdaterFacade implements RUpdaterFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;
  final FirebaseMessaging _firebaseMessaging;
  final AAuthFacade _activityFormFacade;
  final LMFacade _listingManagerFacade;
  final ATTAuthFacade _attendeeFormFacade;
  final CommAuthFacade _communicationFacade;

  ResUpdaterFacade(
      this._fireStore,
      this._firebaseAuth,
      this._firebaseMessaging,
      this._activityFormFacade,
      this._listingManagerFacade,
      this._attendeeFormFacade,
      this._communicationFacade
    );
  @override
  Future<Either<ReservationFormFailure, Unit>> createReservationForm({
    required ReservationItem reservationForm,
    required ListingManagerForm? listingForm,
    required ActivityManagerForm? activityForm,
    required String paymentIntentId
  }) async {

    final String reservationId = reservationForm.reservationId.getOrCrash();

    try {

      // late List<ReservationSlotItem> resSorted = reservationForm.reservationSlotItem..sort(((a,b) => a.selectedDate.compareTo(b.selectedDate)));
      final currentUserId = _firebaseAuth.currentUser;
      // final userDoc = await _fireStore.userDocument();
      final reservationDoc = await _fireStore.reservationDocument(reservationId);

      reservationForm  = reservationForm.copyWith(
        reservationOwnerId: UniqueId.fromUniqueString(currentUserId!.uid),
        // reservationSlotItem: resSorted,
      );

      /// add new listing if new.
      if (listingForm != null) {
          final newListing = await _listingManagerFacade.updateListingForm(listingForm: listingForm);
          if (newListing.isLeft()) {
            return left(const ReservationFormFailure.reservationServerError(failed: 'Failed to create new listing'));
        }
      }

      /// create activity for reservation
      if (activityForm != null) {
        final newActivity = await _activityFormFacade.updateActivitySettingsForm(activityForm: activityForm, activityResId: reservationForm.reservationId);
        if (activitySetupComplete(activityForm)) {
          reservationDoc.update({'isActivity': true});
        } else {
          reservationDoc.update({'isActivity': false});
        }
        if (newActivity.isLeft()) {
          return left(const ReservationFormFailure.reservationServerError(failed: 'Failed to create new activity'));
        }
      }



      /// create reservation for listing
      final reservationItemDto = ReservationItemDto.fromDomain(reservationForm).toJson();
      await reservationDoc.set(reservationItemDto);

      
      /// create reservation-listing owner private chat room
      /// TODO: Add reservation owner name & name of space - and add the all reservation slot, archive chat once last slot is completed.
      /// TODO: save system message with details about reservation confirmation & option to see reservation...?
      
      // await FirebaseChatCore.instance.createRoom(
      //     reservationId,
      //     listing.listingProfileService.backgroundInfoServices.listingOwner.getOrCrash(),
      //     listing.listingProfileService.backgroundInfoServices.listingName.getOrCrash(),
      //     metadata: {
      //       'listingId': reservationForm.instanceId.getOrCrash(),
      //       'reservationId': reservationForm.reservationId.getOrCrash(),
      //       'reservationSlot': reservationForm.reservationSlotItem.map((e) => ReservationSlotItemDto.fromDomain(e).toJson()).toList()
      //     });


      // if (!(kIsWeb)) {
      //   /// create reservation subscription
      //   await _firebaseMessaging.subscribeToTopic(reservationId);
      //   // await _firebaseMessaging.un

      //   /// notify listing subscription
      //   await http.post(
      //       Uri.parse('https://fcm.googleapis.com/fcm/send'),
      //       headers: <String, String>{
      //         'Content-Type': 'application/json',
      //         'Authorization': 'key=$CMF_SERVER_KEY',
      //       },
      //       body: jsonEncode(
      //           <String, dynamic>{
      //             'priority': 'high',
      //             'data': <String, dynamic>{
      //               'reservationId': reservationForm.instanceId.getOrCrash(),
      //               'status': 'done',
      //             },
      //             'notification': {
      //               'title': 'New Reservation!',
      //               'body': 'Someone has booked a new Reservation with you!',
      //             },
      //             'topic': reservationForm.instanceId.getOrCrash(),
      //       }
      //     )
      //   );
      // } else {

      // }

      // /// called on creating a published reservation (not on re-publishing)
      // if (reservationForm.formStatus == FormStatus.published) {
      //   /// send email to admin on new reservation created
      //     await _emailFacade.createEmailNotification(sendTo: ['admin@cincout.ca'], template: 'admin_new_reservation_submitted', button_link: null, reference_body_title: activityForm?.profileService.activityBackground.activityTitle.value.fold((l) => 'New Reservation', (r) => r), attachment: null);
      //     /// TODO NEED TO DIFFERENTIATE BETWEEN RESERVATION AND POST
      //     if (activityForm?.profileService.isActivityPost == true) {
      //       await _emailFacade.createEmailNotification(sendTo: [_firebaseAuth.currentUser?.email ?? ''], template: 'new_reservation_submitted', button_link: null, reference_body_title: null, attachment: null);
      //     }
      // }
      final String activityTitle = (activityForm != null) ? activityForm.profileService.activityBackground.activityTitle.value.fold((l) => 'New Reservation', (r) => r) : 'New Reservation';
      final String? activityImageUrl = (activityForm != null && activityForm.profileService.activityBackground.activityProfileImages?.isNotEmpty == true) ? activityForm.profileService.activityBackground.activityProfileImages!.first.uriPath : null;

      if (listingForm != null) {  
        final listingUser = types.User(
          id: listingForm.listingProfileService.backgroundInfoServices.listingOwner.getOrCrash(), 
          lastName: listingForm.listingProfileService.backgroundInfoServices.listingName.getOrCrash(),
        );

        final facilityOwnerEmail = await _fireStore
            .collection('users')
            .doc(listingForm.listingProfileService.backgroundInfoServices.listingOwner.getOrCrash())
            .get()
            .then((doc) => doc.data()?['email'] as String);
        _communicationFacade.notifyFacilityOwnerOfNewReservation(reservation: reservationForm, facilityOwnerUser: listingUser, activityTitle: activityTitle, facilityOwnerEmail: facilityOwnerEmail, facilityImageUrl: activityImageUrl);
      }
      _communicationFacade.notifyReservationOwnerOfBookingConfirmation(reservation: reservationForm, activity: activityForm, activityTitle: activityTitle, activityImageUrl: activityImageUrl);
      // FirebaseChatCore.instance.sendMessage(sendSystemMessage, roomId);

      return right(unit);
    } on FirebaseAuthException catch (e) {
      return left(ReservationFormFailure.firebaseError(failed: e.message));
    } catch (e) {
      return left(ReservationFormFailure.reservationServerError(failed: e.toString()));
    }
  }

  @override
  Future<Either<ReservationFormFailure, Unit>> updateReservationFormRequest(
      {required ReservationItem reservationForm}) async {

    final String reservationId = reservationForm.reservationId.getOrCrash();

    try {

      final currentUserId = _firebaseAuth.currentUser;
      final reservationDoc = await _fireStore.reservationDocument(reservationId);

      final reservationUpdateRequest = ReservationRequestItem(
        requestId: UniqueId(),
        requestOwner: UniqueId.fromUniqueString(currentUserId!.uid),
        requestReceiver: reservationForm.reservationOwnerId,
        isOpened: false,
        isAccepted: false,
        requestTime: DateTime.now(),
        requestType: ReservationRequestType.changeUpdate,
        reservationChangeRequest: reservationForm,
      );

      final reservationUpdateRequestDto = ReservationRequestDto.fromDomain(reservationUpdateRequest).toJson();
      reservationDoc.reservationRequestDocuments.doc(reservationUpdateRequest.requestId.getOrCrash()).set(reservationUpdateRequestDto);

      return right(unit);
    } catch (e) {
      return left(const ReservationFormFailure.reservationServerError());
    }

  }


  @override
  Future<Either<ReservationFormFailure, Unit>> cancelReservationForm(
      {
        required ReservationCancelRequest cancelRequest,
        required ReservationItem reservationForm
      }) async {

    final String reservationId = reservationForm.reservationId.getOrCrash();

    try {

      final currentUserId = _firebaseAuth.currentUser;
      final reservationDoc = await _fireStore.reservationDocument(reservationId);

      final reservationUpdateRequest = ReservationRequestItem(
        requestId: UniqueId(),
        requestOwner: UniqueId.fromUniqueString(currentUserId!.uid),
        requestReceiver: reservationForm.reservationOwnerId,
        isOpened: false,
        isAccepted: true,
        requestTime: DateTime.now(),
        requestType: ReservationRequestType.cancellation,
        reservationCancelRequest: cancelRequest
      );

      final completeReservationFormItem = ReservationItem(
          reservationId: reservationForm.reservationId,
          reservationOwnerId: reservationForm.reservationOwnerId,
          instanceId: reservationForm.instanceId,
          reservationCost: reservationForm.reservationCost,
          paymentStatus: reservationForm.paymentStatus,
          paymentIntentId: reservationForm.paymentIntentId,
          refundId: cancelRequest.stripeRefundId,
          reservationState: ReservationSlotState.refunded,
          reservationSlotItem: reservationForm.reservationSlotItem,
          dateCreated: reservationForm.dateCreated,
          reservationAffiliates: reservationForm.reservationAffiliates,
          checkInSetting: reservationForm.checkInSetting,
          customFieldRuleSetting: reservationForm.customFieldRuleSetting,
          cancelledSlotItem: reservationForm.cancelledSlotItem
      );

      final reservationItemDto = ReservationItemDto.fromDomain(completeReservationFormItem).toJson();
      reservationDoc.update(reservationItemDto);

      final reservationUpdateRequestDto = ReservationRequestDto.fromDomain(reservationUpdateRequest).toJson();
      reservationDoc.reservationRequestDocuments.doc(reservationUpdateRequest.requestId.getOrCrash()).set(reservationUpdateRequestDto);

      return right(unit);
    } catch (e) {
      return left(const ReservationFormFailure.reservationServerError());
    }

  }


  @override
  Future<Either<ReservationFormFailure, Unit>> createReservationPost({required Post reservationPost, required List<AttendeeItem> attendees}) async {

    try {
      final reservationPostDto = PostDto.fromDomain(reservationPost).toJson();
      final resPostDoc = await _fireStore.reservationPostDocument(reservationPost.id);

      // _notificationFacade.createNewReservationPostNotification(attendees: attendees, post: reservationPost);

      resPostDoc.set(reservationPostDto);
      return right(unit);
    } catch (e) {
      return left (const ReservationFormFailure.reservationServerError(failed: 'cannot create new post'));
    }

  }


  @override
  Future<Either<ReservationFormFailure, Unit>> replyReservationPost({required Post replyReservationPost}) async {

    try {
      final reservationPostDto = PostDto.fromDomain(replyReservationPost).toJson();
      final resPostDoc = await _fireStore.reservationPostDocument(replyReservationPost.id);

      resPostDoc.set(reservationPostDto);
      return right(unit);

    } catch (e) {
      return left(const ReservationFormFailure.reservationServerError(failed: 'cannot create new post'));
    }
  }


  @override
  Future<Either<ReservationFormFailure, Unit>> bookMarkReservationPost({required Post reservationPost}) async {

      try {

        final reservationPostDto = PostDto.fromDomain(reservationPost).toJson();
        final resPostDoc = await _fireStore.reservationPostDocument(reservationPost.id);

        resPostDoc.update(reservationPostDto);
        return right(unit);
      } catch (e) {

        return left (const ReservationFormFailure.reservationServerError());
    }

  }


  @override
  Future<Either<ReservationFormFailure, Unit>> flagReservationPost({required Post reservationPost}) async {
    try {

      final reservationPostDto = PostDto.fromDomain(reservationPost).toJson();
      final resPostDoc = await _fireStore.reservationPostDocument(reservationPost.id);

      resPostDoc.update(reservationPostDto);
      return right(unit);
    } catch (e) {

      return left (const ReservationFormFailure.reservationServerError());
    }
  }

  @override
  Future<Either<ReservationFormFailure, Unit>> likeReservationPost({required Post reservationPost}) async {
    try {

      final reservationPostDto = {'postLikes': reservationPost.postLikes?.map((e) => StringItemDto.fromDomain(e.getOrCrash()).toJson()).toList(), 'likeCount': reservationPost.postLikes?.length};
      final resPostDoc = await _fireStore.reservationPostDocument(reservationPost.id);
      resPostDoc.update(reservationPostDto);

      /// send notification to post owner
      if (_firebaseAuth.currentUser?.uid != reservationPost.authorId.getOrCrash()) {
        // _notificationFacade.createDidLikePostNotification(likedPost: reservationPost);
      }
      return right(unit);
    } catch (e) {

      return left (const ReservationFormFailure.reservationServerError());
    }
  }

  @override
  Future<Either<ReservationFormFailure, Unit>> removePost({required Post reservationPost}) async {
    try {

      final resPostDoc = await _fireStore.reservationDocument(reservationPost.id);
      resPostDoc.delete();

      return right(unit);
    } catch (e) {
      return left (const ReservationFormFailure.reservationServerError());
    }
  }

  @override
  Future<Either<ReservationFormFailure, Uri>> createShareLink({required ReservationItem reservationItem}) async {

    // final DynamicLinkParameters parameters = DynamicLinkParameters(
    //     uriPrefix: 'https://cico.page.link',
    //     link: Uri.parse('https://cincout.ca/reservation/?id=${reservationItem.reservationId.getOrCrash()}'),
    //     androidParameters: const AndroidParameters(
    //         packageName: 'com.example.check_in_web_mobile_explore',
    //         minimumVersion: 1
    //     ),
    //     iosParameters: const IOSParameters(
    //       bundleId: 'com.example.check_in_web_mobile_explore',
    //       minimumVersion: '1',
    //       // appStoreId: '11111'
    //     )
    // );

    try {

      Uri url;
      // final ShortDynamicLink shortLink = await _dynamicLinks.buildShortLink(parameters);
      // url = shortLink.shortUrl;

      return right(Uri());
    } catch (e) {
      return left (ReservationFormFailure.reservationServerError(failed: e.toString()));
    }
  }



  @override
  Future<Either<AttendeeFormFailure, Unit>> sendInvitationToUsers({required String reservationId, required ActivityManagerForm? activityForm, required List<AttendeeItem> invitations}) async {

    try {

      for (AttendeeItem attendee in invitations) {
        // final attendeeFacade = await _attendeeFormFacade.createNewAttendee(attendeeItem: attendee, activityForm: activityForm, paymentIntentId: null, payments: null);

        // if (attendeeFacade.isLeft()) {
        //   return left(const AttendeeFormFailure.attendeeServerError(failed: 'error creating attendee'));
        // }
      }


      /// send notifications to all invited contacts if contacts have yet to be invited.
      for (AttendeeItem attendee in invitations) {

        final currentUserEmail = _firebaseAuth.currentUser?.email;
        final activitySettingsLink = 'https://cincout.ca${reservationRoute(reservationId)}';
        final activityTitle = (activityForm != null) ? activityForm.profileService.activityBackground.activityTitle.value.fold((l) => 'a New Reservation', (r) => r) : 'a New Reservation';
        final String? activityImageUrl =  (activityForm?.profileService.activityBackground.activityProfileImages?.isNotEmpty == true) ? activityForm!.profileService.activityBackground.activityProfileImages!.first.uriPath : null;
    
        // final notificationFacade = await _notificationFacade.createReservationInvitationNotification(
        //     reservationId: reservationId,
        //     attendee: attendee
        // );

        _communicationFacade.notififyAttendeeOfStatusUpdate(statusType: ContactStatus.invited, attendee: attendee, currentUserEmail: currentUserEmail ?? '', activitySettingsLink: activitySettingsLink, activityTitle: activityTitle, activityImageUrl: activityImageUrl);
      }

      return right(unit);
    } catch (e) {
      return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }

  @override
  Future<Either<AttendeeFormFailure, Unit>> removeSelectedAttendee({required String reservationId, required String attendeeId}) async {

    try {

      final activityDoc = await _fireStore.activityDocument(reservationId);
      final attendeeDoc = activityDoc.collection('attendees').doc(attendeeId);
      final attendeeProfileDoc = _fireStore.collection('users').doc(attendeeId);
      final profileAttReservations = attendeeProfileDoc.collection('attending').doc(reservationId);

        attendeeDoc.delete();
        profileAttReservations.delete();

        /// remove notification & unsubscribe.
        // await _notificationFacade.deleteReservationInvitationNotification(reservationId: reservationId, attendeeUserId: attendeeId);
        // await _communcationFacade.
      return right(unit);
    } catch (e) {
      return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }
}