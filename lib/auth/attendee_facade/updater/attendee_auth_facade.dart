part of check_in_facade;

@LazySingleton(as: ATTAuthFacade)
class AttendeeFormFacade implements ATTAuthFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseStorage _firebaseStorage;
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseAuth _firebaseAuth;
  final NAuthFacade _notificationFacade;
  final EAuthFacade _emailFacade;

  AttendeeFormFacade(
      this._fireStore,
      this._firebaseStorage,
      this._firebaseAuth,
      this._notificationFacade,
      this._firebaseMessaging,
      this._emailFacade,
    );



  @override
  Future<Either<AttendeeFormFailure, Unit>> createNewAttendee({required AttendeeItem attendeeItem, required UserProfileModel activityOwner, required ActivityManagerForm? activityForm, required String? paymentIntentId, required , required List<PaymentIntent>? payments}) async {

    late AttendeeItem attendee;
    attendee = attendeeItem;


    if (paymentIntentId != null) {
      attendee = attendee.copyWith(
          paymentIntentId: paymentIntentId
      );
    }


    try {

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


      /// save documents if vendor form contains any
      if (attendeeItem.attendeeType == AttendeeType.vendor && attendee.vendorForm != null) {
        late VendorMerchantForm newVendorForm = attendeeItem.vendorForm!;

        if ((payments != null) && (payments.isEmpty == false)) {
          late List<MVBoothPayments> newPaymentBooths = [];
          newPaymentBooths.addAll(newVendorForm.boothPaymentOptions ?? []);

          newPaymentBooths = newPaymentBooths.map((booth) {
            PaymentIntent? payment = payments.firstWhere(
                    (element) => booth.selectedId != null && element.itemId == booth.selectedId!.getOrCrash(),
                    orElse: () => PaymentIntent()
            );

            return booth.copyWith(
                stripePaymentIntent: payment,
                status: AvailabilityStatus.requested
            );
          }).toList();

          newVendorForm = newVendorForm.copyWith(
            boothPaymentOptions: newPaymentBooths
          );

          attendee = attendee.copyWith(
            vendorForm: newVendorForm
          );
        }

        if (isDocumentsOptionValid(attendeeItem.vendorForm!)) {
          late List<MVCustomOption> newOptions = [];
          newOptions.addAll(newVendorForm.customOptions ?? []);

          late MVCustomOption? newCustomOption = getDocumentRuleOption(newVendorForm);
          late List<DocumentFormOption> documents = [];
          documents.addAll(getDocumentsList(newVendorForm) ?? []);

          for (DocumentFormOption document in documents) {
            if (document.documentForm.imageToUpload != null) {
              final metadata = SettableMetadata(contentType: 'application/pdf');
              final urlId = UniqueId();
              final reference = _firebaseStorage.ref('activity_directory').child(activityForm.activityFormId.getOrCrash());
              await reference.child('vendor_form').child(attendeeItem.vendorForm!.formId.getOrCrash()).child('attendee_form').child('${urlId.getOrCrash()}.pdf').putData(document.documentForm.imageToUpload!, metadata);
              /// retrieve link to file
              final uri = await reference.child('vendor_form').child(attendeeItem.vendorForm!.formId.getOrCrash()).child('attendee_form').child('${urlId.getOrCrash()}.pdf').getDownloadURL();
              final index = documents.indexWhere((element) => element.documentForm.key == document.documentForm.key);
              final newDocument = DocumentFormOption(documentForm: ImageUpload(key: uri, uriPath: uri), isRequiredOption: document.isRequiredOption);
              documents.replaceRange(index, index + 1, [newDocument]);
            }
          }

          newCustomOption = newCustomOption?.copyWith(
              customRuleOption: newCustomOption.customRuleOption?.copyWith(
                  customDocumentOptions: documents
              )
          );

          if (newVendorForm.customOptions != null && newCustomOption != null) {
            final int customIndex = newVendorForm.customOptions!.indexWhere((element) => element.customRuleOption?.ruleId == newCustomOption?.customRuleOption?.ruleId);
            newOptions.replaceRange(customIndex, customIndex + 1, [newCustomOption]);
            newVendorForm = newVendorForm.copyWith(
                customOptions: newOptions
            );


            attendee = attendee.copyWith(
              vendorForm: newVendorForm
            );

            }
          }
        }
      }

      /// create notification from attendee to owner for request to join
      if (attendeeItem.contactStatus == ContactStatus.requested) {
          if (attendeeItem.attendeeType == AttendeeType.vendor && _firebaseAuth.currentUser != null && activityForm != null) {
            final String activityTitle = activityForm.profileService.activityBackground.activityTitle.value.fold((l) => 'an Event near you', (r) => r);
            final String activityLink =  'https://cincout.ca${reservationRoute(activityForm.activityFormId.getOrCrash())}';
            final String activitySettingsLink = 'https://cincout.ca${reservationSettingsRoute(activityForm.activityFormId.getOrCrash(), SettingNavMarker.vendorForm.name)}';
            final String currentUserEmail = _firebaseAuth.currentUser?.email ?? '';

            final String activityOwnerEmail = activityOwner.emailAddress.getOrCrash();
            final String activityOwnerVendorsLink = '/${DashboardMarker.resVendorForms.name.toString()}/reservation/${activityForm.activityFormId.getOrCrash()}';
            final String attendeeTitle = _firebaseAuth.currentUser?.displayName ?? '';

            await _emailFacade.createEmailNotification(sendTo: [currentUserEmail], template: 'attendee_vendor_request_submitted', button_link: activitySettingsLink, reference_body_title: activityTitle, attachment: null);
            await _emailFacade.createEmailNotification(sendTo: [activityOwnerEmail], template: 'activity_owner_request_received', button_link: activityLink, reference_body_title: attendeeTitle, attachment: null);
          }
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


  /// send vendor confirmation of


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
      // if (activityForm.profileService.activityRequirements.eventActivityRulesRequirement != null && activityForm.profileService.activityRequirements.eventActivityRulesRequirement?.merchantLimit != null) {
      //   if (activityForm.profileService.activityRequirements.eventActivityRulesRequirement!.merchantLimit != 0) {
      //     final vendorLimit = activityForm.profileService.activityRequirements.eventActivityRulesRequirement!.merchantLimit ?? 0;
      //
      //     if ((vendorAttendees ?? 0) >= vendorLimit) {
      //       return left(const AttendeeFormFailure.attendeeLimitReached());
      //     }
      //   }
      // }

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

    /// cannot leave if at least one booth has been accepted.

    try {

      /// handle special conditions for removing from firebase storage based on attendee type.
      switch (attendeeItem.attendeeType) {
        case AttendeeType.vendor:
          break;
        case AttendeeType.free:
          // TODO: Handle this case.
        case AttendeeType.tickets:
          // TODO: Handle this case.
        case AttendeeType.pass:
          // TODO: Handle this case.
        case AttendeeType.instructor:
          // TODO: Handle this case.
        case AttendeeType.partner:
          // TODO: Handle this case.
        case AttendeeType.organization:
          // TODO: Handle this case.
        case AttendeeType.interested:
          // TODO: Handle this case.
      }

      final activityDoc = await _fireStore.activityDocument(attendeeItem.reservationId.getOrCrash());
      final attendeeDoc = activityDoc.collection('attendees').doc(attendeeItem.attendeeOwnerId.getOrCrash());

      attendeeDoc.delete();

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


  @override
  Future<Either<AttendeeFormFailure, Unit>> updateInterestedAttendee({required String reservationId, required String? userId}) async {
    try {
      if (userId == null) {
        return left(AttendeeFormFailure.attendeeFirebaseError(failed: 'not logged in'));
      }

      final reference = await _fireStore.collection('activity_directory').doc(reservationId).collection('attendees').doc(userId).get();
      final AttendeeItem? getAttendee = (reference.data() != null) ? AttendeeItemDto.fromFireStore(reference.data()!).toDomain() : null;
      final attendeeProfileDoc = _fireStore.collection('users').doc(userId);
      final profileAttReservations = attendeeProfileDoc.collection('attending').doc(reservationId);

      if (getAttendee != null) {
        Map<String, bool> interestedValue;

        if (getAttendee.isInterested == false || getAttendee.isInterested == null) {
          interestedValue = {'isInterested': true};
        } else {
          interestedValue = {'isInterested': false};
        }


        await _fireStore.collection('activity_directory').doc(reservationId).collection('attendees').doc(userId).update(interestedValue);
        await profileAttReservations.update(interestedValue);

      } else {

        final AttendeeItem attendeeItem = AttendeeItem(
            attendeeId: UniqueId(),
            attendeeOwnerId: UniqueId.fromUniqueString(userId),
            reservationId: UniqueId.fromUniqueString(reservationId),
            cost: '',
            paymentStatus: PaymentStatusType.noStatus,
            attendeeType: AttendeeType.interested,
            paymentIntentId: '',
            isInterested: true,
            dateCreated: DateTime.now()
        );
        final attendeeDto = AttendeeItemDto.fromDomain(attendeeItem).toJson();

        await _fireStore.collection('activity_directory').doc(reservationId).collection('attendees').doc(userId).set(attendeeDto);
        await profileAttReservations.set(attendeeDto);
      }

      return right(unit);
    } catch (e) {
      return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }


  @override
  Future<Either<AttendeeFormFailure, Unit>> updateVendorBoothStatus({
    required List<VendorContactDetail> attendeeItems,
    required UserProfileModel activityOwner,
    required AvailabilityStatus status, 
    required ActivityManagerForm activityForm,
    required List<PaymentIntent>? payments,
  }) async {

     try {
       for (AttendeeItem attendee in attendeeItems.map((e) => e.attendee).toSet()) {
         late UserProfileModel attendeeProfile = attendeeItems.map((e) => e.userProfile).firstWhere((element) => element.userId == attendee.attendeeOwnerId, orElse: () => UserProfileModel.empty());
         late EventMerchantVendorProfile vendorProfile = attendeeItems.map((e) => e.vendorProfile).firstWhere((element) => element.profileOwner.getOrCrash() == attendee.attendeeOwnerId.getOrCrash(), orElse: () => EventMerchantVendorProfile.empty());

         late AttendeeItem newAttendee = attendee;
         late VendorMerchantForm newVendorForm = newAttendee.vendorForm!;
         late List<MVBoothPayments> newPaymentBooths = [];
         newPaymentBooths.addAll(newVendorForm.boothPaymentOptions ?? []);

         for (MVBoothPayments boothItem in attendeeItems.map((e) => e.boothItem).toList()) {

             if ((payments != null) && (payments.isEmpty == false)) {
               newPaymentBooths = newPaymentBooths.map((booth) {
                 if (booth.selectedId == boothItem.selectedId) {
                   PaymentIntent? payment = payments.firstWhere(
                           (element) => booth.selectedId != null && element.itemId == booth.selectedId!.getOrCrash(),
                       orElse: () => PaymentIntent()
                   );

                   return booth.copyWith(
                       stripePaymentIntent: payment,
                       status: status
                    );
                   }
                 return booth;
               }).toList();

               newVendorForm = newVendorForm.copyWith(
                   boothPaymentOptions: newPaymentBooths
               );

               newAttendee = newAttendee.copyWith(
                   vendorForm: newVendorForm
               );

             } else {

               newPaymentBooths = newPaymentBooths.map((booth) {
                 if (booth.selectedId == boothItem.selectedId) {
                   return booth.copyWith(
                       status: status
                   );
                 }
                 return booth;
               }).toList();

               newVendorForm = newVendorForm.copyWith(
                   boothPaymentOptions: newPaymentBooths
               );

               newAttendee = newAttendee.copyWith(
                   vendorForm: newVendorForm
               );
             }
          }


         final String activityTitle = activityForm.profileService.activityBackground.activityTitle.value.fold((l) => 'an Event near you', (r) => r);
         final String activityLink =  'https://cincout.ca${reservationRoute(activityForm.activityFormId.getOrCrash())}';
         final String activitySettingsLink = 'https://cincout.ca${reservationSettingsRoute(activityForm.activityFormId.getOrCrash(), SettingNavMarker.vendorForm.name)}';
         final String vendorEmail = attendeeProfile.emailAddress.getOrCrash();
         final String vendorName = vendorProfile.brandName.getOrCrash();

         final String activityOwnerEmail = activityOwner.emailAddress.getOrCrash();
         final String activityOwnerVendorsLink = '/${DashboardMarker.resVendorForms.name.toString()}/reservation/${activityForm.activityFormId.getOrCrash()}';
         // final String attendeeTitle = _firebaseAuth.currentUser?.displayName ?? '';


         if (status != AvailabilityStatus.cancelled || status != AvailabilityStatus.confirmed) {
           await _notificationFacade.attendeeVendorUpdateNotification(reservationId: attendee.reservationId.getOrCrash(), activityTitle: activityTitle, attendee: attendee);
           await _emailFacade.createEmailNotification(sendTo: [vendorEmail], template: 'attendee_vendor_updates_received', button_link: activityLink, reference_body_title: activityTitle, attachment: null);
         }

         /// update via email
         /// send push notification
         switch (status) {
           case AvailabilityStatus.confirmed:
           /// send if no confirmations exist
             if (attendee.vendorForm?.boothPaymentOptions?.map((e) => e.status).contains(AvailabilityStatus.confirmed) == false) {
               newAttendee = newAttendee.copyWith(
                   contactStatus: ContactStatus.joined
               );
               /// send email from generated pdf

                final invoiceNumber = await AttendeeFacade.instance.getNumberOfAttending(attendeeOwnerId: attendee.attendeeOwnerId.getOrCrash(), status: ContactStatus.joined, attendingType: AttendeeType.vendor, isInterested: null) ?? 1;
                final invoicePdf = await generateReceiptPdf(activityForm, activityOwner, attendeeProfile, vendorProfile, attendee, invoiceNumber);
                final String base64File = base64Encode(invoicePdf);

               final Map<String, dynamic> attachment = {
                 'content': base64File,
                 'filename': '${attendee.attendeeOwnerId.getOrCrash().padLeft(4, '0')}_receipt.pdf',
               };

               await _emailFacade.createEmailNotification(sendTo: [vendorEmail], template: 'attendee_vendor_confirmation_received', button_link: activitySettingsLink, reference_body_title: activityTitle, attachment: attachment);
             }
           case AvailabilityStatus.refunded:
             if (vendorNoLongerEligible(newAttendee.vendorForm?.boothPaymentOptions ?? [])) {
               newAttendee = newAttendee.copyWith(
                   contactStatus: ContactStatus.requested
               );
             /// no need to send refund receipt - update is clear enough
             //   await _emailFacade.createEmailNotification(sendTo: [vendorEmail], template: 'attendee_vendor_cancelled_received', button_link: activityLink, reference_body_title: activityTitle, attachment:  null);
             }
           case AvailabilityStatus.denied:
           /// send if all now equal
             if (vendorNoLongerEligible(newAttendee.vendorForm?.boothPaymentOptions ?? [])) {
               newAttendee = newAttendee.copyWith(
                   contactStatus: ContactStatus.requested
               );
               await _emailFacade.createEmailNotification(sendTo: [vendorEmail], template: 'activity_owner_cancellation_received', button_link: activityLink, reference_body_title: activityTitle, attachment: null);
             }
             break;
           case AvailabilityStatus.cancelled:
           /// only if all booth options have been rejected. (or if vendor has cancelled...should appear/notify as an update has been made)
             if (vendorNoLongerEligible(newAttendee.vendorForm?.boothPaymentOptions ?? [])) {
               newAttendee = newAttendee.copyWith(
                   contactStatus: ContactStatus.requested
               );
             }

             if (_firebaseAuth.currentUser?.uid != activityOwner.userId.getOrCrash()) {
                await _emailFacade.createEmailNotification(sendTo: [activityOwnerEmail], template: 'attendee_vendor_cancelled_received', button_link: activityLink, reference_body_title: vendorName, attachment: null);
             }
           default:
             break;
         }



         final attendeeFormDto = AttendeeItemDto.fromDomain(newAttendee).toJson();
         final activityDoc = await _fireStore.activityDocument(newAttendee.reservationId.getOrCrash());
         final attendeeDoc = activityDoc.collection('attendees').doc(newAttendee.attendeeOwnerId.getOrCrash());

         attendeeDoc.update(attendeeFormDto);

       }

       return right(unit);
     } catch (e) {
       return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
     }
  }
}




