library check_in_facade;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:check_in_domain/domain/misc/attendee_services/attendee_item/attendee_item.dart';
import 'package:check_in_domain/domain/misc/attendee_services/attendee_item/attendee_item_dtos.dart';
import 'package:check_in_domain/domain/auth/reservation_manager/post.dart';
import 'package:check_in_domain/domain/auth/reservation_manager/post_dtos.dart';
import 'package:check_in_domain/domain/misc/attendee_services/form/merchant_vendor/custom_options/mv_custom_options.dart';
import 'package:check_in_domain/domain/misc/attendee_services/form/merchant_vendor/booth_payments/mv_booth_payments.dart';
import 'package:check_in_domain/domain/misc/filter_services/vendor_contact_filter_model.dart';
import 'package:check_in_domain/domain/misc/stripe/business_address_service/stripe_business_address.dart';
import 'package:check_in_domain/domain/misc/stripe/tax_calculation/stripe_tax_calculation.dart';
import 'package:check_in_domain/domain/misc/stripe/receipt_services/receipt/receipt_pdf_generator.dart';
import 'package:check_in_facade/check_in_facade.config.dart';
import 'package:crypto/crypto.dart';

import 'package:check_in_credentials/check_in_credentials.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:get_it/get_it.dart';
import 'package:check_in_domain/check_in_domain.dart';
import 'package:dartz/dartz.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:core';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:geoflutterfire/geoflutterfire.dart';



part 'injection.dart';
part 'injectable_module.dart';

part 'un_auth/u_auth_facade.dart';
part 'un_auth/unAuth_facade.dart';
part 'un_auth/locations_facade/watcher/lo_un_auth_watcher_facade.dart';
part 'un_auth/locations_facade/watcher/location_un_auth_watcher_facade.dart';

part 'misc/m_misc_facade.dart';
part 'misc/misc_facade.dart';

part 'core/firestore_helpers.dart';

part 'auth/user_facade/firebase_auth_facade.dart';
part 'auth/user_facade/i_auth_facade.dart';

part 'auth/stripe_facade/watcher/s_stripe_watcher_facade.dart';
part 'auth/stripe_facade/watcher/stripe_watcher_facade.dart';
part 'auth/stripe_facade/updater/s_stripe_facade.dart';
part 'auth/stripe_facade/updater/stripe_facade.dart';

part 'auth/reservation_facade/reservation_auth_helpers.dart';
part 'auth/reservation_facade/watcher/r_watcher_facade.dart';
part 'auth/reservation_facade/watcher/res_watcher_facade.dart';

part 'auth/reservation_facade/updater/r_updater_facade.dart';
part 'auth/reservation_facade/updater/res_updater_facade.dart';

part 'auth/notification_facade/updater/n_auth_facade.dart';
part 'auth/notification_facade/updater/notification_auth_facade.dart';
part 'auth/notification_facade/watcher/n_watcher_facade.dart';
part 'auth/notification_facade/watcher/notification_watcher_facade.dart';

part 'auth/notification_facade/email_updater/email_auth_facade.dart';
part 'auth/notification_facade/email_updater/e_auth_facade.dart';

part 'auth/chat_facade/firebase_chat_core_config.dart';
part 'auth/chat_facade/firebase_chat_facade.dart';
part 'auth/chat_facade/util.dart';

part 'auth/circle_community_facade/watcher/c_auth_watcher_facade.dart';
part 'auth/circle_community_facade/watcher/circle_community_auth_watcher_facade.dart';

part 'auth/activity_facade/watcher/a_auth_watcher_facade.dart';
part 'auth/activity_facade/watcher/activity_auth_watcher_facade.dart';
part 'auth/activity_facade/ticket_facade/watcher/t_watcher_facade.dart';
part 'auth/activity_facade/ticket_facade/watcher/ticket_watcher_facade.dart';

part 'auth/attendee_facade/updater/att_auth_facade.dart';
part 'auth/attendee_facade/updater/attendee_auth_facade.dart';

part 'auth/attendee_facade/watcher/att_auth_watcher_facade.dart';
part 'auth/attendee_facade/watcher/attendee_auth_watcher_facade.dart';

part 'auth/locations_facade/updater/lo_auth_facade.dart';
part 'auth/locations_facade/updater/location_auth_facade.dart';

part 'auth/merch_vendor_facade/updater/merch_vendor_auth_facade.dart';
part 'auth/merch_vendor_facade/updater/mv_auth_facade.dart';
part 'auth/merch_vendor_facade/watcher/merch_ven_watcher_facade.dart';
part 'auth/merch_vendor_facade/watcher/mv_watcher_facade.dart';

part 'auth/listing_facade/watcher/l_m_watcher_facade.dart';
part 'auth/listing_facade/watcher/listing_manager_watcher_facade.dart';

part 'auth/listing_facade/listing_auth_helpers.dart';
part 'auth/listing_facade/updater/l_m_facade.dart';
part 'auth/listing_facade/updater/listing_manager_facade.dart';

part 'auth/facility_facade/watcher/f_auth_watcher_facade.dart';
part 'auth/facility_facade/watcher/facility_auth_watcher_facade.dart';

part 'auth/facility_facade/updater/f_auth_facade.dart';
part 'auth/facility_facade/updater/facility_auth_facade.dart';

part 'auth/activity_facade/updater/a_auth_facade.dart';
part 'auth/activity_facade/updater/activity_auth_facade.dart';

part 'auth/facility_facade/facility_auth_helpers.dart';

part 'auth/map_facade/firebase_map_facade.dart';
part 'auth/locations_facade/autocomplete_search_facade.dart';

part 'auth/notification_facade/notification_core_config.dart';

part 'un_auth/share_facade/updater/share_facade.dart';