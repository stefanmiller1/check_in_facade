part of check_in_facade;

@LazySingleton(as: RUpdaterFacade)
class ResUpdaterFacade implements RUpdaterFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;

  ResUpdaterFacade(this._fireStore, this._firebaseAuth);

  @override
  Future<Either<ReservationFormFailure, Unit>> createReservationForm({
    required ReservationItem reservationForm,
    required String paymentIntentId
  }) async {

    final String reservationId = reservationForm.reservationId.getOrCrash();

    try {

      final currentUserId = _firebaseAuth.currentUser;
      final userDoc = await _fireStore.userDocument();
      final reservationDoc = await _fireStore.reservationDocument(reservationId);

      final userProfileSession = ProfileSession(
          profileSessionId: reservationForm.reservationId,
          ownerId: UniqueId.fromUniqueString(currentUserId!.uid),
          facilityType: ProfileFacilityType.uniqueFacility,
          activityType: ProfileActivityOption.none,
          isActivity: false,
          isFacility: true,
          isSession: false
      );

      final completeReservationFormItem = ReservationItem(
          reservationId: reservationForm.reservationId,
          reservationOwnerId: reservationForm.reservationOwnerId,
          instanceId: reservationForm.instanceId,
          reservationCost: reservationForm.reservationCost,
          paymentStatus: reservationForm.paymentStatus,
          paymentIntentId: paymentIntentId,
          reservationState: reservationForm.reservationState,
          reservationSlotItem: reservationForm.reservationSlotItem,
          dateCreated: reservationForm.dateCreated,
          reservationAffiliates: reservationForm.reservationAffiliates,
          checkInSetting: reservationForm.checkInSetting,
          customFieldRuleSetting: reservationForm.customFieldRuleSetting,
          cancelledSlotItem: reservationForm.cancelledSlotItem
      );

      /// create reservation for listing
      final reservationItemDto = ReservationItemDto.fromDomain(completeReservationFormItem).toJson();
      reservationDoc.set(reservationItemDto);

      /// add to reservation holder profile
      final userProfileSessionDto = ProfileSessionDto.fromDomain(userProfileSession).toJson();
      await userDoc.sessionDocument.doc(reservationId).set(userProfileSessionDto);

      /// create reservation chat room
      return await FirebaseChatCore.instance.createRoom(
          reservationForm.reservationOwnerId.getOrCrash(),
          metadata: {
            'listingId': reservationForm.instanceId.getOrCrash(),
            'reservationId': reservationForm.reservationId.getOrCrash()
          });

      return right(unit);
    } on FirebaseAuthException catch (e) {
      return left(ReservationFormFailure.firebaseError(failed: e.message));
    } catch (e) {
      return left(const ReservationFormFailure.reservationServerError());
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

      print('sending...');
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



}