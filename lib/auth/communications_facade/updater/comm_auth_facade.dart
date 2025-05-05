part of check_in_facade;


abstract class CommAuthFacade {

Future<void> sendCommunication({required CommunicationEventItem event});

/// Notifications for Facility Owners (People who create and manage facilities)
// 1. Booking Confirmation & Details
// 	•	✅ New Reservation Made – Notifies when a booking is confirmed for their facility.
Future<void> notifyFacilityOwnerOfNewReservation({required ReservationItem? reservation, required types.User facilityOwnerUser, required String? activityTitle, required String? facilityOwnerEmail, required String? facilityImageUrl});
Future<void> notifyFacilityOwnerOfReservationRequest({required ReservationItem? reservation,  required types.User listingUser, required String? activityTitle});
// 	•	✅ Reservation Updates/Requests - Notifies of any changes to the reservation (e.g., time, date, attendees).
Future<void> notififyFacilityOwnerOfReservationUpdates({required ReservationItem? reservation, required types.User listingUser, required String? activityTitle, required String? facilityOwnerEmail});
// 	•	✅ Reservation Summary for Facility Staff – Includes time, duration, and special requirements (e.g., extra chairs, projector).
Future<void> notifyFacilityOwnerReservationSummary({required ReservationItem? reservation, required ActivityManagerForm? activity, required String? facilityOwnerEmail});
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
Future<void> notifyReservationOwnerOfBookingConfirmation({required ReservationItem reservation, required ActivityManagerForm? activity, required String? activityTitle, required String? activityImageUrl});
// 	•	✅ Payment Confirmation – Confirms successful payment.
// 	•	✅ Reservation Summary – Provides booking details (date, time, facility rules, policies).
// 	•	✅ Attendee Status – Confirms that attendee Status have been changed.
Future<void> notifyReservationOwnerOfAttendeeStatus({required ContactStatus statusType, required String reservationId, required String attendeeName, required AttendeeType attendeeType, required String activityOwnerId, required String activityOwnerEmail, required String activityLink, required String activityTitle, required String? activityImageUrl});
// 	•	✅ Attendee Application Status – Updates an attendee makes to their Status that lets reservation owner know.
Future<void> notifiyReservationOwnerOfAttendeeApplicationStatus({required AvailabilityStatus applicationStatus, required String activityOwnerEmail, required String activityLink, required String vendorName});
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
/// ✅ Attendee Status Updates - Notifies attendees if the host updates their status (e.g., from waitlist to confirmed).
Future<void> notififyAttendeeOfStatusUpdate({required ContactStatus statusType, required AttendeeItem attendee, required String currentUserEmail, required String activitySettingsLink, required String activityTitle, required String? activityImageUrl});
/// ✅ Attendee Application Form Status Updates – Notifies attendees if the host updates their application status (e.g., from waitlist to confirmed).
// Future<void> notifyAttendeeOfApplicationStatusUpdate({required ContactStatus statusType, required String currentUserEmail, required String activitySettingsLink, required String activityTitle});
/// ✅ Reservation Summary – Details date, time, location, and event details...timed(leading up to event & after confirmations made)
Future<void> notififyAttendeeOfReservationSummary();
/// ✅ Attendee Application Form Status Updates – Notifies attendees if the host updates their application status (e.g., from waitlist to confirmed).
Future<void> notifyAttendeeOfApplicationStatusUpdate({required AvailabilityStatus applicationStatus, required List<MVBoothPayments>? payments, required ActivityManagerForm activityForm, required AttendeeItem attendee, required UserProfileModel activityOwner, required UserProfileModel attendeeProfile, required EventMerchantVendorProfile vendorProfile, required String applicantEmail, required String activityLink, required String activitySettingsLink, required String activityTitle});

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