part of check_in_facade;

@LazySingleton(as: CommAuthFacade)
class CommunicationsUpdateFacade implements CommAuthFacade {
  
  final NAuthFacade _notificationFacade;
  final EAuthFacade _emailFacade;
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;


  CommunicationsUpdateFacade(
    this._notificationFacade, 
    this._emailFacade, 
    this._firebaseMessaging,
    this._fireStore, 
    this._firebaseAuth
  ); 
  
  
  @override
  Future<void> sendCommunication({required CommunicationEventItem event}) async {
    switch (event.channel) {
      case NotificationChannelType.email:
        if (event.emailItem == null) {
          return;
        }
        await _emailFacade.createEmailNotification(email: event.emailItem!);
      case NotificationChannelType.addToChatRoom: 
      if (event.chatRoom == null) {
          return;
        }

        switch (event.chatRoom!.type) {
          case types.RoomType.channel:
            break;
          case types.RoomType.direct:
            break;
          case types.RoomType.group:
            await FirebaseChatCore.instance.addUserToGroupRoom(
              roomId: event.chatRoom!.id,
              userId: event.chatRoom!.users.first.id,
            );
            /// subscribe to topic
            break;
          case null:
           break;
        }
        break;
        
      case NotificationChannelType.createChatRoom:
        if (event.chatRoom == null) {
          return;
        }
        
        /// handle type of chat room
          switch (event.chatRoom!.type) {
            case null:
              return;
            case types.RoomType.channel:
              break;
            case types.RoomType.direct:
               await FirebaseChatCore.instance.createDirectRoom(
                 event.chatRoom!.users.first.id, 
                 event.chatRoom!.name ?? '',
                 event.chatRoom!.imageUrl,
                 metadata: event.chatRoom!.metadata
                );
                
                /// subscripe creator to topic
               break;
            case types.RoomType.group:
              await FirebaseChatCore.instance.createGroupRoom(
                  roomId: event.chatRoom!.id,
                  imageUrl: event.chatRoom!.imageUrl,
                  name: event.chatRoom!.name ?? '', 
                  users: event.chatRoom!.users,
                  metadata: event.chatRoom!.metadata
                );
                /// subscripe creator to topic
               break;
          }
         break;

      case NotificationChannelType.message: 
          if (event.message == null || event.chatRoom == null) {
            return;
          }

          switch (event.chatRoom!.type) {
            case types.RoomType.channel:
              break;
            case types.RoomType.direct:
              final directChatRoom = await FirebaseChatCore.instance.createDirectRoom(
                 event.chatRoom!.users.first.id, 
                 event.chatRoom!.name ?? '',
                 event.chatRoom!.imageUrl,
                 metadata: event.chatRoom!.metadata
              );

              FirebaseChatCore.instance.sendMessage(event.message!, null, directChatRoom.id);
              return;

            case types.RoomType.group:

              FirebaseChatCore.instance.sendMessage(event.message!, null, event.chatRoom!.id);
              return;
            case null:
              return;
          }
          
        break;
      case NotificationChannelType.account:
        if (event.accountNotification == null) {
          return;
        }

        await _notificationFacade.createNotification(notificationItem: event.accountNotification!);
    }
  }

/// Notifications for Facility Owners (People who create and manage facilities)
// 1. Booking Confirmation & Details
// 	•	✅ New Reservation Made – Notifies when a booking is confirmed for their facility.
@override
Future<void> notifyFacilityOwnerOfNewReservation({required ReservationItem? reservation, required types.User facilityOwnerUser, required String? activityTitle, required String? facilityOwnerEmail, required String? facilityImageUrl}) async {

  /// get facility owner email from facility owner userProfileModel.
  final events = [
      /// create an email leting facility owner know a new reservation has been made
      if (reservation?.formStatus == FormStatus.published) CommunicationEventItem(
        channel: NotificationChannelType.email,
        emailItem: EmailNotificationItem(
          sendTo: ['admin@cincout.ca'],
          template: 'admin_new_reservation_submitted',
          button_link: null,
          reference_body_title: activityTitle,
          attachment: null
        ),
      ),
      /// send email to admin account (notifying that new reservation has been made)
      if (facilityOwnerEmail != null && facilityOwnerUser.id != _firebaseAuth.currentUser?.uid) CommunicationEventItem(
        channel: NotificationChannelType.email,
        emailItem: EmailNotificationItem(
          sendTo: [facilityOwnerEmail],
          template: 'admin_new_reservation_submitted',
          button_link: null,
          reference_body_title: activityTitle,
          attachment: null
        ),
      ),
      /// reservation cannot be a post & facility owner cannot be reservation owner.

      ///create new chat with owner
      if (reservation != null && facilityOwnerUser.id != _firebaseAuth.currentUser?.uid) CommunicationEventItem(
        channel: NotificationChannelType.createChatRoom,
        chatRoom: types.Room(
          id: reservation.reservationId.getOrCrash(), 
          type: types.RoomType.direct, 
          users: [facilityOwnerUser],
          name: 'Reservation for - $activityTitle',
          imageUrl: facilityImageUrl,
          metadata: {
            'listingId': reservation.instanceId.getOrCrash(),
            'reservationId': reservation.reservationId.getOrCrash(),
            'reservationSlot': reservation.reservationSlotItem.map((e) => ReservationSlotItemDto.fromDomain(e).toJson()).toList()
        }
      )
    ),

    /// create notification for facility owner
      if (reservation != null && facilityOwnerUser.id != _firebaseAuth.currentUser?.uid) CommunicationEventItem(
        channel: NotificationChannelType.account,
        accountNotification: AccountNotificationItem(
          notificationId: UniqueId(),
          isRead: false,
          receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch,
          notificationType: AccountNotificationType.reservation,
          recipientId: facilityOwnerUser.id,
          reservationId: reservation.reservationId.getOrCrash(),
          title: 'New Reservation Submitted',
          body: 'A new reservation has been submitted for $activityTitle',
          listingId: reservation.instanceId.getOrCrash(),
        ),
      ),
  ];  

  Future.wait(events.map((e) => sendCommunication(event: e)));
}

@override
Future<void> notifyFacilityOwnerOfReservationRequest({required ReservationItem? reservation,  required types.User listingUser, required String? activityTitle}) async {
  final events = [
    if (reservation != null) CommunicationEventItem(
      channel: NotificationChannelType.account,
      accountNotification: AccountNotificationItem(
          notificationId: UniqueId(),
          isRead: false,
          receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch,
          notificationType: AccountNotificationType.reservation,
          recipientId: listingUser.id,
          reservationId: reservation.reservationId.getOrCrash(),
          title: 'New Reservation Request',
          body: 'A new reservation request has been submitted for ${activityTitle}',
          listingId: reservation.instanceId.getOrCrash(),
      ),
    ),
  ];
}

// 	•	✅ Reservation Updates/Requests - Notifies of any changes to the reservation (e.g., time, date, attendees).
@override
Future<void> notififyFacilityOwnerOfReservationUpdates({required ReservationItem? reservation, required types.User listingUser, required String? activityTitle, required String? facilityOwnerEmail}) async {
  final events = [
    if (reservation != null) CommunicationEventItem(
      channel: NotificationChannelType.account,
      accountNotification: AccountNotificationItem(
          notificationId: UniqueId(),
          isRead: false,
          receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch,
          notificationType: AccountNotificationType.reservation,
          recipientId: listingUser.id,
          reservationId: reservation.reservationId.getOrCrash(),
          title: 'Updates & Changes Made to Reservation',
          body: 'Updates & Changes Made by ${_firebaseAuth.currentUser?.displayName ?? 'A'} Reservation at Your Facility',
          listingId: reservation.instanceId.getOrCrash(),
      ),
    ),
  ];
  Future.wait(events.map((e) => sendCommunication(event: e)));
}


// 	•	✅ Reservation Summary for Facility Staff – Includes time, duration, and special requirements (e.g., extra chairs, projector).
@override
Future<void> notifyFacilityOwnerReservationSummary({required ReservationItem? reservation, required ActivityManagerForm? activity, required String? facilityOwnerEmail,}) async {
//   final event = [
//       /// send email to facility owner (notifying a summary for the reservation has been made)
//       if (facilityOwnerEmail != null) CommunicationEventItem(
//       channel: NotificationChannelType.email,
//       emailItem: EmailNotificationItem(
//         sendTo: [facilityOwnerEmail],
//         template: 'admin_new_reservation_submitted',
//         button_link: null,
//         reference_body_title: activityTitle,
//         attachment: null
//       ),
//     ),
//   ];
}

// 	•	✅ Upcoming Booking Alert – A day before the reservation.


// 2. Pre-Event Maintenance & Readiness
// 	•	🚧 Facility Issue Reported – Alerts managers if a problem is logged (e.g., broken sink, power outage).
// 	•	🚧 Facility Closure Notice – Notifies managers of closures affecting a scheduled event.
// 	•	🚧 Alternative Arrangements Suggested – If a booked facility is unavailable, suggests alternative options.

// 3. Booking Modifications
// 	•	⚠️ Activity Update Notice – Alerts about changes in the purpose or nature of the event.
// 	•	⚠️ Location Change Alert – Notifies managers if the booking is moved elsewhere.
// 	•	⚠️ Rescheduling Request – Informs facility staff when a booker reschedules.
// 	•	❌ Booking Cancellation Alert – Notifies managers if a booking is canceled.
// 	•	❌ Attendee Removal - Alerts attendee they have been removed from the event.

// 4. Facility Maintenance & Incident Reports
// 	•	🛠 Equipment Request Notification – Alerts staff if extra amenities (tables, AV equipment) are needed.
// 	•	🛠 Damage or Cleanup Reported – Notifies staff if damages or issues arise.
// 	•	📷 Lost & Found Item Reported – Logs any lost belongings after an event.

// 5. Post-Event Management
// 	•	✅ Successful Checkout Notification – Confirms the facility is now available.
// 	•	💬 Feedback from Reservation Holder – Allows facility managers to review host feedback.
// 	•	🛠 Maintenance Request from Event Report – Notifies if a follow-up repair is needed.

/// Notifications for Reservation Owners (People who create and manage reservations)
// 1. Booking Confirmation & Details
// 	•	✅ Booking Confirmed – Confirms that the reservation was successfully made.
@override
Future<void> notifyReservationOwnerOfBookingConfirmation({required ReservationItem reservation, required ActivityManagerForm? activity, required String? activityTitle, required String? activityImageUrl}) async {
  final event = [
      if (reservation.formStatus == FormStatus.published && activity?.profileService.isActivityPost == true) CommunicationEventItem(
        channel: NotificationChannelType.email,
        emailItem: EmailNotificationItem(
          sendTo: [_firebaseAuth.currentUser?.email ?? ''],
          template: 'new_reservation_submitted',
          button_link: null,
          reference_body_title: null,
          attachment: null
        ),
      ),
      if (reservation.formStatus == FormStatus.published) CommunicationEventItem(
        channel: NotificationChannelType.createChatRoom,
        chatRoom: types.Room(
            createdAt: DateTime.now().millisecondsSinceEpoch,
            id: reservation.reservationId.getOrCrash(),
            type: types.RoomType.group,
            name: '${activityTitle ?? 'New Activity'} Channel',
            imageUrl: activityImageUrl,
            users: [],
            metadata: {
            'listingId': reservation.instanceId.getOrCrash(),
            'reservationId': reservation.reservationId.getOrCrash(),
            'reservationSlot': reservation.reservationSlotItem.map((e) => ReservationSlotItemDto.fromDomain(e).toJson()).toList()
        }
      )
    )
  ];
  Future.wait(event.map((e) => sendCommunication(event: e)));
}

// 	•	✅ Payment Confirmation – Confirms successful payment.
// 	•	✅ Reservation Summary – Provides booking details (date, time, facility rules, policies).
// 	•	✅ Attendee Status – Confirms that attendee Status have been changed.
@override
Future<void> notifyReservationOwnerOfAttendeeStatus({required ContactStatus statusType, required String reservationId, required String attendeeName, required AttendeeType attendeeType, required String activityOwnerId, required String activityOwnerEmail, required String activityLink, required String activityTitle, required String? activityImageUrl}) async {
  switch (statusType) {
    case ContactStatus.joined:
      final event = [
        CommunicationEventItem(
          channel: NotificationChannelType.account,
          accountNotification: AccountNotificationItem(
              notificationId: UniqueId(),
              isRead: false,
              receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch,
              notificationType: AccountNotificationType.joined,
              recipientId: activityOwnerId,
              reservationId: reservationId,
              title: '$attendeeName has Joined $activityTitle',
              body: 'Check out your attendees',
              imageUrl: activityImageUrl
          ),
        ),
      ];
      Future.wait(event.map((e) => sendCommunication(event: e)));
      break;
    case ContactStatus.requested:
      final event = [
        if (attendeeType == AttendeeType.vendor) CommunicationEventItem(
          channel: NotificationChannelType.email,
          emailItem: EmailNotificationItem(
            sendTo: [activityOwnerEmail],
            template: 'activity_owner_request_received',
            button_link: activityLink,
            reference_body_title: attendeeName,
            attachment: null
          ),
        ),
        CommunicationEventItem(
          channel: NotificationChannelType.account,
          accountNotification: AccountNotificationItem(
              notificationId: UniqueId(),
              isRead: false,
              receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch,
              notificationType: AccountNotificationType.request,
              sentFromId: _firebaseAuth.currentUser?.uid,
              recipientId: activityOwnerId,
              reservationId: reservationId,
              title: '$attendeeName wants to Join $activityTitle',
              body: 'Review New Request',
              imageUrl: activityImageUrl,
          ),
        ),
      ];

      Future.wait(event.map((e) => sendCommunication(event: e)));
      break;
    case ContactStatus.pending:
      break;
    case ContactStatus.invited:
      break;
    case ContactStatus.denied:
      break;
  }
}
// 	•	✅ Attendee Application Status – Updates an attendee makes to their Status that lets reservation owner know.
@override
Future<void> notifiyReservationOwnerOfAttendeeApplicationStatus({required AvailabilityStatus applicationStatus, required String activityOwnerEmail, required String activityLink, required String vendorName}) async {
  
  switch (applicationStatus) {
    case AvailabilityStatus.cancelled: 
      final events = [
          CommunicationEventItem(
            channel: NotificationChannelType.email,
            emailItem: EmailNotificationItem(
              sendTo: [activityOwnerEmail],
              template: 'attendee_vendor_cancelled_received',
              button_link: activityLink,
              reference_body_title: vendorName,
              attachment: null
            ),
          ),
      ];
      Future.wait(events.map((e) => sendCommunication(event: e)));
    default: 
    break;
  }
}

// 2. Pre-Event Reminders & Updates
// 	•	🔔 Upcoming Reservation Reminder – Sent a day or hours before.
// 	•	🔔 Check-In Instructions – Details about entry access (codes, keys, security).
// 	•	🔔 Facility Policy Reminders – Highlights any important policies before the event.

// 3. Booking Changes & Modifications
// 	•	⚠️ Activity Update Notice – Confirms when event details (title, agenda) are modified.
// 	•	⚠️ Location Change Alert – Notifies if the venue is updated.
// 	•	⚠️ Rescheduling Confirmation – Confirms when a booking date/time is changed.
// 	•	⚠️ Attendee RSVP Updates – Alerts when attendees accept or decline.
// 	•	⚠️ Attendee List Updated – If someone is added or removed.

// 4. Cancellation & Refunds
// 	•	❌ Booking Cancellation Notice – Confirms cancellation of the reservation.
// 	•	❌ Attendee Dropout Notice – Sent when an attendee cancels their participation.
// 	•	💰 Refund Processed – Confirms refund amount and processing timeline.
// 	•	💰 Refund Denied – Informs the booker if a refund request is denied.
/// ✅ Attendee RSVP Confirmation – Confirms when they accept or decline an invite.



/// Notifications for Attendees (People looking to be and people invited to an activity)

/// Booking Confirmation & Details
/// mostly functions that can or will be called by a reservation owner or host (and sent to attendees).
/// ✅ Attendee Status Updates - Notifies attendees if the host updates their attending status (e.g., from waitlist to confirmed).
@override
Future<void> notififyAttendeeOfStatusUpdate({required ContactStatus statusType, required AttendeeItem attendee, required String currentUserEmail, required String activitySettingsLink, required String activityTitle, required String? activityImageUrl}) async {
  
  switch (statusType) {
    case ContactStatus.joined:
      final event = [
        
      ];
      break;
    case ContactStatus.requested:
      final event = [
        CommunicationEventItem(
          channel: NotificationChannelType.email,
          emailItem: EmailNotificationItem(
            sendTo: [currentUserEmail],
            template: 'attendee_vendor_request_submitted',
            button_link: activitySettingsLink,
            reference_body_title: activityTitle,
            attachment: null
          ),
        ),
      ];

      Future.wait(event.map((e) => sendCommunication(event: e)));
      break;
    case ContactStatus.pending:
      break;
    case ContactStatus.invited:
      final event = [
        CommunicationEventItem(
          channel: NotificationChannelType.account,
          accountNotification: AccountNotificationItem(
              notificationId: UniqueId(),
              isRead: false,
              receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch,
              notificationType: AccountNotificationType.invite,
              sentFromId: _firebaseAuth.currentUser?.uid,
              recipientId: attendee.attendeeOwnerId.getOrCrash(),
              reservationId: attendee.reservationId.getOrCrash(),
              title: 'You\'re Invited to Join ${activityTitle}',
              body: 'Click here to accpet Invite.',
              imageUrl: activityImageUrl,
          ),
        ),
      ];
      Future.wait(event.map((e) => sendCommunication(event: e)));
      break;
    case ContactStatus.denied:
      break;
  }
}

/// ✅ Attendee Application Form Status Updates – Notifies attendees if the host updates their application status (e.g., from waitlist to confirmed).
@override
Future<void> notifyAttendeeOfApplicationStatusUpdate({required AvailabilityStatus applicationStatus, required List<MVBoothPayments>? payments, required ActivityManagerForm activityForm, required AttendeeItem attendee, required UserProfileModel activityOwner, required UserProfileModel attendeeProfile, required EventMerchantVendorProfile vendorProfile, required String applicantEmail, required String activityLink, required String activitySettingsLink, required String activityTitle}) async {
  
  
  if (applicationStatus != AvailabilityStatus.cancelled || applicationStatus != AvailabilityStatus.confirmed) {
      final event = [
        CommunicationEventItem(
          channel: NotificationChannelType.email,
          emailItem: EmailNotificationItem(
            sendTo: [applicantEmail],
            template: 'attendee_vendor_updates_received',
            button_link: activityLink,
            reference_body_title: activityTitle,
            attachment: null
          ),
        ),
        CommunicationEventItem(
          channel: NotificationChannelType.account,
          accountNotification: AccountNotificationItem(
              notificationId: UniqueId(),
              isRead: false,
              receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch,
              notificationType: AccountNotificationType.reservation,
              sentFromId: _firebaseAuth.currentUser?.uid,
              recipientId: attendee.attendeeOwnerId.getOrCrash(),
              reservationId: attendee.reservationId.getOrCrash(),
              title: '${activityTitle} has Updated Your Application',
              body: 'Click here to take a look.',
              imageUrl: (activityForm.profileService.activityBackground.activityProfileImages?.isNotEmpty == true) ? activityForm.profileService.activityBackground.activityProfileImages!.first.uriPath : null,
          ),
        ),
      ];
      Future.wait(event.map((e) => sendCommunication(event: e)));
  }

  if (vendorNoLongerEligible(payments ?? [])) {
      print('not eligible anymore :()');
      final event = [
        CommunicationEventItem(
          channel: NotificationChannelType.email,
          emailItem: EmailNotificationItem(
            sendTo: [applicantEmail],
            template: 'activity_owner_cancellation_received',
            button_link: activityLink,
            reference_body_title: activityTitle,
            attachment: null
          ),
        ),
        CommunicationEventItem(
          channel: NotificationChannelType.account,
          accountNotification: AccountNotificationItem(
              notificationId: UniqueId(),
              isRead: false,
              receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch,
              notificationType: AccountNotificationType.deletedAttendee,
              sentFromId: _firebaseAuth.currentUser?.uid,
              recipientId: attendee.attendeeOwnerId.getOrCrash(),
              reservationId: attendee.reservationId.getOrCrash(),
              title: 'Application at ${activityTitle} has been Refunded',
              body: 'Click here to take a look.',
              imageUrl: (activityForm.profileService.activityBackground.activityProfileImages?.isNotEmpty == true) ? activityForm.profileService.activityBackground.activityProfileImages!.first.uriPath : null,
          ),
        ),
      ];
      Future.wait(event.map((e) => sendCommunication(event: e)));
    }

  switch (applicationStatus) {
    case AvailabilityStatus.confirmed:

    final invoiceNumber = await AttendeeFacade.instance.getNumberOfAttending(attendeeOwnerId: attendee.attendeeOwnerId.getOrCrash(), status: ContactStatus.joined, attendingType: AttendeeType.vendor, isInterested: null) ?? 1;
    final invoicePdf = await generateReceiptPdf(activityForm, activityOwner, attendeeProfile, vendorProfile, attendee, invoiceNumber);
    final String base64File = base64Encode(invoicePdf);

    final Map<String, dynamic> attachment = {
      'content': base64File,
      'filename': '${attendee.attendeeOwnerId.getOrCrash().padLeft(4, '0')}_receipt.pdf',
    };

    final event = [
        CommunicationEventItem(
          channel: NotificationChannelType.email,
          emailItem: EmailNotificationItem(
            sendTo: [applicantEmail],
            template: 'attendee_vendor_confirmation_received',
            button_link: activitySettingsLink,
            reference_body_title: activityTitle,
            attachment: attachment
          ),
        ),
        ///add to reservation chat room
        CommunicationEventItem(
          channel: NotificationChannelType.addToChatRoom,
          chatRoom: types.Room(
            createdAt: DateTime.now().millisecondsSinceEpoch,
            id: activityForm.activityFormId.getOrCrash(),
            type: types.RoomType.group,
            users: [
              types.User(
                id: attendee.attendeeOwnerId.getOrCrash(),
                firstName: attendeeProfile.legalName.getOrCrash(),
                lastName: attendeeProfile.legalSurname.getOrCrash(),
                imageUrl: attendeeProfile.photoUri,
                role: types.Role.user
              ),
            ]
          )
        ),
        CommunicationEventItem(
          channel: NotificationChannelType.createChatRoom,
          chatRoom: types.Room(
            createdAt: DateTime.now().millisecondsSinceEpoch,
            id: UniqueId().getOrCrash(),
            type: types.RoomType.direct,
            users: [
              types.User(
                id: attendee.attendeeOwnerId.getOrCrash(),
                firstName: attendeeProfile.legalName.getOrCrash(),
                lastName: attendeeProfile.legalSurname.getOrCrash(),
                imageUrl: attendeeProfile.photoUri,
                role: types.Role.user
              ),
            ]
          )
        ),
        CommunicationEventItem(
          channel: NotificationChannelType.message,
          chatRoom: types.Room(
            id: UniqueId().getOrCrash(),
            type: types.RoomType.direct,
            users: [
              types.User(
                id: attendee.attendeeOwnerId.getOrCrash(),
                firstName: attendeeProfile.legalName.getOrCrash(),
                lastName: attendeeProfile.legalSurname.getOrCrash(),
                imageUrl: attendeeProfile.photoUri,
                role: types.Role.user
              ),
            ],
          ),
          message: types.PartialText(
            text: 'Welcome to ${activityTitle}!',
            
          )
        ),
        CommunicationEventItem(
          channel: NotificationChannelType.account,
          accountNotification: AccountNotificationItem(
              notificationId: UniqueId(),
              isRead: false,
              receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch,
              notificationType: AccountNotificationType.reservation,
              sentFromId: _firebaseAuth.currentUser?.uid,
              recipientId: attendee.attendeeOwnerId.getOrCrash(),
              reservationId: attendee.reservationId.getOrCrash(),
              title: '${activityTitle} has Confirmed Your Application',
              body: 'Click here to take a look.',
              imageUrl: (activityForm.profileService.activityBackground.activityProfileImages?.isNotEmpty == true) ? activityForm.profileService.activityBackground.activityProfileImages!.first.uriPath : null,
          ),
        ),
      ];
    Future.wait(event.map((e) => sendCommunication(event: e)));
      break;
    // case AvailabilityStatus.refunded:
    case AvailabilityStatus.denied:
    final event = [
        CommunicationEventItem(
          channel: NotificationChannelType.email,
          emailItem: EmailNotificationItem(
            sendTo: [applicantEmail],
            template: 'activity_owner_cancellation_received',
            button_link: activityLink,
            reference_body_title: activityTitle,
            attachment: null
          ),
        ),
      ];
      Future.wait(event.map((e) => sendCommunication(event: e)));
      break;
    case AvailabilityStatus.cancelled:
    final event = [
      /// only send notification if attendee is not current user. attendees with the option to cancel can only do so because they have yet to be confirmed. Only confirmed application attendees have been subscribed to reservation topic.
     CommunicationEventItem(
          channel: NotificationChannelType.email,
          emailItem: EmailNotificationItem(
            sendTo: [applicantEmail],
            template: 'activity_owner_cancellation_received',
            button_link: activityLink,
            reference_body_title: activityTitle,
            attachment: null
          ),
        ),
        CommunicationEventItem(
          channel: NotificationChannelType.account,
          accountNotification: AccountNotificationItem(
              notificationId: UniqueId(),
              isRead: false,
              receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch,
              notificationType: AccountNotificationType.deletedAttendee,
              sentFromId: _firebaseAuth.currentUser?.uid,
              recipientId: attendee.attendeeOwnerId.getOrCrash(),
              reservationId: attendee.reservationId.getOrCrash(),
              title: 'Application at ${activityTitle} has been Cancelled',
              body: 'Click here to take a look.',
              imageUrl: (activityForm.profileService.activityBackground.activityProfileImages?.isNotEmpty == true) ? activityForm.profileService.activityBackground.activityProfileImages!.first.uriPath : null,
          ),
        ),
      ];
    Future.wait(event.map((e) => sendCommunication(event: e)));
      break;
    default:
      break;
  }
}

/// ✅ Reservation Summary – Details date, time, location, and event details...timed(leading up to event & after confirmations made)
Future<void> notififyAttendeeOfReservationSummary() async {
  final event = [

  ];
}

/// Pre-Event Reminders & Updates
/// •	🔔 Upcoming Event Reminder – Sent a day or a few hours before.
///	•	🔔 Location Change Alert – Notifies attendees if the event location changes.
///	•	🔔 Check-In Instructions – Provides entry details (e.g., digital key, reception).
///	•	🔔 Facility Policy Reminders – Reminds them about event conduct (e.g., no outside food, cleanup requirements).

// 3. Booking Changes & Modifications
// •	⚠️ Activity Update Notice – Sent when the host updates details (title, description, start time, etc.).
// •	⚠️ Rescheduling Notice – Notifies attendees if the booking date/time is changed.
// •	⚠️ Attendee List Update – If attendees are added or removed from the event.
// •	❌ Event Cancellation Notice – Notifies attendees if the event is canceled.

// 4. Completion & Post-Event Follow-Ups
// •	✅ Successful Checkout Confirmation – Confirms the event has concluded.
// •	💬 Feedback Request – Asks attendees to review the activity or facility.

}