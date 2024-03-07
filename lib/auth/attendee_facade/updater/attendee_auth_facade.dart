part of check_in_facade;

@LazySingleton(as: ATTAuthFacade)
class AttendeeFormFacade implements ATTAuthFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseStorage _firebaseStorage;
  final FirebaseMessaging _firebaseMessaging;
  final NAuthFacade _notificationFacade;

  AttendeeFormFacade(
      this._fireStore,
      this._firebaseStorage,
      this._notificationFacade,
      this._firebaseMessaging
      );



  @override
  Future<Either<AttendeeFormFailure, Unit>> createNewAttendee({required AttendeeItem attendeeItem, required ActivityManagerForm? activityForm, required String? paymentIntentId}) async {

    late AttendeeItem attendee;
    attendee = attendeeItem;


    try {

      ///upload attendee profile item
      if (attendeeItem.attendeeType == AttendeeType.vendor) {
        if (attendeeItem.contactStatus == ContactStatus.joined) {
          if (attendeeItem.eventMerchantVendorProfile != null && attendeeItem.eventMerchantVendorProfile!.vendorLogo != null) {
            final Uint8List imageData = attendeeItem.eventMerchantVendorProfile!.vendorLogo!;
            /// store the file
            final urlId = attendee.attendeeOwnerId;
            final reference = _firebaseStorage.ref('activity_directory').child(attendeeItem.reservationId.getOrCrash()).child('vendors');
            await reference.child(urlId.getOrCrash()).putData(imageData);

            /// retrieve link to file stored in firebase storage
            final uri = await reference.child(urlId.getOrCrash()).getDownloadURL();

            final EventMerchantVendorProfile eventVendorMerchant = EventMerchantVendorProfile(
              brandName: attendeeItem.eventMerchantVendorProfile!.brandName,
              backgroundInfo: attendeeItem.eventMerchantVendorProfile!.backgroundInfo,
              uriImage: uri
            );

            attendee = attendee.copyWith(
                eventMerchantVendorProfile: eventVendorMerchant
            );
          } else {
          /// could not create vendor attendee
          return left(const AttendeeFormFailure.attendeeVendorCouldNotBeCreated());
          }
        }
      }


      /// check [ActivityManagerForm] for attendee limits and rules if activity form exists.
      if (activityForm != null) {
        if (attendeeItem.attendeeType == AttendeeType.free) {
          final attendeeCount = await _fireStore.collection('activity_directory')
              .doc(attendeeItem.reservationId.getOrCrash())
              .collection('attendees')
              .where('attendeeType', isEqualTo: 'AttendeeType.free')
              .where('contactStatus', isEqualTo: 'ContactStatus.joined')
              .count().get();

          if (activityForm.activityAttendance.attendanceLimit != null && activityForm.activityAttendance.attendanceLimit != 0 && (activityForm.activityAttendance.attendanceLimit! <= (attendeeCount.count ?? 0))) {
            return left(const AttendeeFormFailure.attendeeLimitReached());
          }
        }


      /// create attendee - and update attendee tickets such that they are no longer onHold.
      if (attendeeItem.attendeeType == AttendeeType.tickets) {
          /// get count for ticket in each [TicketItem] that was selected during check-out.
          await createNewTicket(attendeeItem: attendeeItem, activityForm: activityForm, isOnHold: false);
        }
      }

      /// create notification from attendee to owner for request to join
      if (attendeeItem.contactStatus == ContactStatus.requested) {
          await _notificationFacade.createRequestToJoinReservationNotification(reservationId: attendeeItem.reservationId.getOrCrash(), attendee: attendeeItem);
      }

      if (attendeeItem.contactStatus == ContactStatus.joined) {
          await _notificationFacade.createJoinedReservationNotification(reservationId: attendeeItem.reservationId.getOrCrash(), attendee: attendeeItem);
      }

      final attendeeFormDto = AttendeeItemDto.fromDomain(attendee).toJson();
      final activityDoc = await _fireStore.activityDocument(attendee.reservationId.getOrCrash());
      final attendeeDoc = activityDoc.collection('attendees').doc(attendee.attendeeOwnerId.getOrCrash());
      final attendeeProfileDoc = _fireStore.collection('users').doc(attendee.attendeeOwnerId.getOrCrash());
      final profileAttReservations = attendeeProfileDoc.collection('attending').doc(attendee.reservationId.getOrCrash());

      attendeeDoc.set(attendeeFormDto);
      profileAttReservations.set(attendeeFormDto);

      return right(unit);
    } on FirebaseAuthException catch (e) {
      if (e.toString().contains('permission-denied') || e.toString().contains('unknown')) {
        return left(const AttendeeFormFailure.attendeePermissionDenied());
      } else {
        return left(AttendeeFormFailure.attendeeServerError(failed: e.code));
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        return left(const AttendeeFormFailure.attendeePermissionDenied());
      }
      return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }


  /// check if ticket limit is reached and put ticket on hold until payment has gone through...
  @override
  Future<Either<AttendeeFormFailure, Unit>> createNewTicket({required AttendeeItem attendeeItem, required ActivityManagerForm activityForm, required bool isOnHold}) async {


    try {
      for (TicketItem ticket in attendeeItem.ticketItems ?? []) {

        if (isOnHold == false) {
          ticket = ticket.copyWith(
            isOnHold: false
          );
        }

        final ticketDoc = _fireStore.collection('activity_directory').doc(attendeeItem.reservationId.getOrCrash()).collection('tickets');
        final ticketDto = TicketItemDto.fromDomain(ticket).toJson();
        /// put tickets on hold
        final ticketCollection = ticketDoc.doc(ticket.ticketId.getOrCrash());

        /// save tickets
        await ticketCollection.set(ticketDto);

      }

      return right(unit);
    } catch (e) {
      return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }


  @override
  Future<Either<AttendeeFormFailure, Unit>> removeTicketsFromAttendee({required AttendeeItem attendeeItem, required ActivityManagerForm activityForm}) {
    // TODO: implement removeTicketsFromAttendee
    throw UnimplementedError();
  }

  @override
  Future<Either<AttendeeFormFailure, UserProfileModel>> checkVendorLimit({required AttendeeItem attendeeItem, required ActivityManagerForm activityForm, required UserProfileModel currentUser}) async {
    try {


      final vendorAttendees =  await retrieveNumberOfVendors(reservationId: attendeeItem.reservationId);
      if (activityForm.profileService.activityRequirements.eventActivityRulesRequirement != null && activityForm.profileService.activityRequirements.eventActivityRulesRequirement?.merchantLimit != null) {
        if (activityForm.profileService.activityRequirements.eventActivityRulesRequirement!.merchantLimit != 0) {
          final vendorLimit = activityForm.profileService.activityRequirements.eventActivityRulesRequirement!.merchantLimit ?? 0;

          if ((vendorAttendees ?? 0) >= vendorLimit) {
            return left(const AttendeeFormFailure.attendeeLimitReached());
          }
        }
      }

      return right(currentUser);
    } catch (e) {
      return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }

  @override
  Future<Either<AttendeeFormFailure, UserProfileModel>> checkTicketLimit({required AttendeeItem attendeeItem, required ActivityManagerForm activityForm, required UserProfileModel currentUser}) async {

    try {

      if (activityForm.activityAttendance.isTicketFixed == true && activityForm.activityAttendance.defaultActivityTickets != null) {
          final onHoldTickets = await retrieveNumberOfOnHoldTickets(reservationId: attendeeItem.reservationId, ticketId: activityForm.activityAttendance.defaultActivityTickets!.ticketId.getOrCrash());
          final purchasedTickets = await retrieveNumberOfTicketsPurchased(reservationId: attendeeItem.reservationId, ticketId: activityForm.activityAttendance.defaultActivityTickets!.ticketId.getOrCrash());
          final ticket = activityForm.activityAttendance.defaultActivityTickets!;
          final int ticketsTaken = ((onHoldTickets ?? 0) + (purchasedTickets ?? 0));
          final ticketsRemaining = ticketsTaken - ticket.ticketQuantity;

          if ((onHoldTickets ?? 0) + (purchasedTickets ?? 0) + (attendeeItem.ticketItems?.length ?? 0) > ticket.ticketQuantity) {
            return left(AttendeeFormFailure.ticketLimitReached(ticket, ticketsRemaining));
        }
      }




      else if (activityForm.activityAttendance.isTicketFixed == false && activityForm.activityAttendance.activityTickets != null && activityForm.activityAttendance.activityTickets?.isNotEmpty == true) {
        for (String selectedTicketId in attendeeItem.ticketItems?.map((e) => e.selectedTicketId.getOrCrash()).toSet() ?? []) {
          final onHoldTickets = await retrieveNumberOfOnHoldTickets(reservationId: attendeeItem.reservationId, ticketId: selectedTicketId);
          final purchasedTickets = await retrieveNumberOfTicketsPurchased(reservationId: attendeeItem.reservationId, ticketId: selectedTicketId);
          final int ticketsTaken = ((onHoldTickets ?? 0) + (purchasedTickets ?? 0));
          final ActivityTicketOption? activityTicket = activityForm.activityAttendance.activityTickets?.firstWhere((element) => element.ticketId.getOrCrash() == selectedTicketId, orElse: () => ActivityTicketOption.empty());
          final int ticketsRemaining = (activityTicket?.ticketQuantity ?? 0) - ticketsTaken;

          if (ticketsTaken + (attendeeItem.ticketItems?.where((element) => element.selectedTicketId.getOrCrash() == selectedTicketId).length ?? 0) > (activityTicket?.ticketQuantity ?? 0)) {
            return left(AttendeeFormFailure.ticketLimitReached(activityTicket, ticketsRemaining));
          }
        }
      }

      return right(currentUser);
    } catch (e) {
      return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }


  Future<int?> retrieveNumberOfVendors({
    required UniqueId reservationId,
  }) async {

    final attendeeDoc = _fireStore.collection('activity_directory').doc(reservationId.getOrCrash()).collection('attendees');

    try {
      
      final vendorsCount = await attendeeDoc
          .where('contactStatus', isEqualTo: 'ContactStatus.joined')
          .where('attendeeType', isEqualTo: 'AttendeeType.vendor').count().get();

      return vendorsCount.count;
    } catch (e) {
      return null;
    }
}

  Future<int?> retrieveNumberOfTicketsPurchased({
      required UniqueId reservationId,
      required String ticketId}) async {

    final ticketDoc = _fireStore.collection('activity_directory').doc(reservationId.getOrCrash()).collection('tickets');

    try {
      final ticketCount = await ticketDoc
          .where('selectedTicketId', isEqualTo: ticketId)
          .where('isOnHold', isEqualTo: false).count().get();

      return ticketCount.count;
    } catch (e) {
      return null;
    }
  }

  Future<int?> retrieveNumberOfOnHoldTickets({
    required UniqueId reservationId,
    required String ticketId
  }) async {

    final ticketDoc = _fireStore.collection('activity_directory').doc(reservationId.getOrCrash()).collection('tickets');

    try {

      final ticketCount = await ticketDoc
          .where('selectedTicketId', isEqualTo: ticketId)
          .where('isOnHold', isEqualTo: true)
          .where('expiresAt', isGreaterThanOrEqualTo: DateTime.now().millisecondsSinceEpoch).count().get();

      return ticketCount.count;

    } catch (e) {
      return null;
    }
  }

  @override
  Future<Either<AttendeeFormFailure, Unit>> deleteAttendee({required AttendeeItem attendeeItem, required ActivityManagerForm activityForm}) async {

    try {

      /// handle special conditions for removing from firebase storage based on attendee type.
      switch (attendeeItem.attendeeType) {
        case AttendeeType.vendor:
          final reference = _firebaseStorage.ref('activity_directory').child(attendeeItem.reservationId.getOrCrash()).child('vendors');
          await reference.child(attendeeItem.attendeeOwnerId.getOrCrash()).delete();
          break;
      }

      final activityDoc = await _fireStore.activityDocument(attendeeItem.reservationId.getOrCrash());
      final attendeeDoc = activityDoc.collection('attendees').doc(attendeeItem.attendeeOwnerId.getOrCrash());
      final attendeeProfileDoc = _fireStore.collection('users').doc(attendeeItem.attendeeOwnerId.getOrCrash());
      final profileAttReservations = attendeeProfileDoc.collection('attending').doc(attendeeItem.reservationId.getOrCrash());

      attendeeDoc.delete();
      profileAttReservations.delete();

      await _firebaseMessaging.unsubscribeFromTopic(attendeeItem.reservationId.getOrCrash());

      return right(unit);
    } on FirebaseAuthException catch (e) {
      if (e.toString().contains('permission-denied') || e.toString().contains('unknown')) {
        return left(const AttendeeFormFailure.attendeePermissionDenied());
      } else {
        return left(AttendeeFormFailure.attendeeServerError(failed: e.code));
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        return left(const AttendeeFormFailure.attendeePermissionDenied());
      }
      return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }

  }
}


