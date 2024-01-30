import 'dart:async';
import 'dart:developer';
import 'dart:math' show Random;

import 'package:cloud_firestore/cloud_firestore.dart';

const kUsers = "users";
const kReferrals = "referrals";

extension _ShowLogsExtension on bool? {
  bool l(dynamic msg) {
    if (this ?? true) log("$msg");
    return true;
  }
}

class ReferralService {
  const ReferralService._();

  static String _generateCode({int length = 8}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      List.generate(length, (index) {
        return chars.codeUnitAt(Random().nextInt(chars.length));
      }),
    );
  }

  static Future<bool> _apply({
    required UserModel? user,
    required String? code,
    bool? log,
  }) {
    final uid = user?.id;
    final xInvalidCode = code == null || code.isEmpty;
    final xInvalidUid = uid == null || uid.isEmpty;
    final xInvalidUser = user == null || xInvalidUid || user.isRedeemed;
    log.l("_apply (inValidCode: $xInvalidCode, inValidUser: $xInvalidUser)");
    if (xInvalidCode || xInvalidUser) return Future.value(false);
    log.l("getReferral(id: $code)");
    return getReferral(code).then((referral) {
      final isInvalidCode = referral == null || (referral.id ?? "").isEmpty;
      final isInvalidUid = user.isReferral(referral?.id);
      final isMember = referral?.isMember(uid) ?? false;
      log.l(
        "checking referral(isInvalidCode: $isInvalidCode, isInvalidUser: $isInvalidUid, isMember: $isMember)",
      );
      if (!isInvalidCode && !isInvalidUid && !isMember) {
        log.l("updateUser(current.id : $uid)");
        final userDuration = getRemainingDuration(
          createdAt: user.rewardCreatedAt,
          days: user.rewardDuration,
        );

        final currentUDays = userDuration.inDays + Rewards.x1.duration;

        return _updateUser(uid, {
          UserKeys.i.redeemed: true,
          UserKeys.i.redeemedCode: referral.id,
          UserKeys.i.reward: Rewards.x1.category,
          UserKeys.i.rewardDuration: currentUDays,
          UserKeys.i.rewardCreatedAt: Rewards.x1.createdAt,
          UserKeys.i.rewardExpireAt: Rewards.x1.expireAt,
        }).then((_) {
          log.l("updateUser(referrer.id : ${referral.uid})");
          return _getUser(referral.uid).then((referrer) {
            if (referrer == null) return Future.value(false);
            final referrerDuration = getRemainingDuration(
              createdAt: referrer.rewardCreatedAt,
              days: referrer.rewardDuration,
            );
            final currentRDays = referrerDuration.inDays + Rewards.x2.duration;
            return _updateUser(referral.uid, {
              UserKeys.i.reward: Rewards.x2.category,
              UserKeys.i.rewardDuration: currentRDays,
              UserKeys.i.rewardCreatedAt: Rewards.x2.createdAt,
              UserKeys.i.rewardExpireAt: Rewards.x2.expireAt,
            }).then((_) {
              log.l("updateReferral(referral.id : ${referral.id})");
              return _updateReferral(referral.id, {
                ReferralKeys.i.members: FieldValue.arrayUnion([uid]),
              }).then((_) => log.l("done"));
            });
          });
        });
      } else {
        return false;
      }
    });
  }

  static Future<bool> createReferral(String? id, String? uid) {
    if (id == null || uid == null || id.isEmpty || uid.isEmpty) {
      return Future.value(false);
    }
    final data = ReferralModel(id: id, uid: uid);
    return FirebaseFirestore.instance
        .collection(kReferrals)
        .doc(data.id)
        .set(data.source, SetOptions(merge: true))
        .then((value) => true);
  }

  static Future<bool> createUser(UserModel user, {bool? log}) {
    log.l("createUser(user.source: ${user.source})");
    if (user.source.isEmpty) return Future.value(false);

    final currentUid = user.noneUid;
    final redeemCode = user.redeemedCode;
    final referralCode = _generateCode(length: 6);

    final current = user.copy(
      id: currentUid,
      referralCode: referralCode,
      redeemClear: true,
    );
    return FirebaseFirestore.instance
        .collection(kUsers)
        .doc(currentUid)
        .set(current.source, SetOptions(merge: true))
        .then((_) => createReferral(referralCode, currentUid))
        .then((_) => _apply(code: redeemCode, user: current));
  }

  static Future<bool> redeemCode(String? uid, String? code, {bool? log}) {
    log.l("addRedeem(uid: $uid, code: $code)");
    if (uid == null || code == null || uid.isEmpty || code.isEmpty) {
      return Future.value(false);
    }
    log.l("getUser(current.id: $uid)");
    return _getUser(uid).then((user) {
      log.l("checking current user (isRedeemed: ${user?.isRedeemed})");
      if (user != null && !user.isRedeemed) {
        return _apply(user: user, code: code);
      }
      return false;
    });
  }

  static Future<String> referCode(String? uid, {int length = 8}) {
    return _getUser(uid).then((value) {
      final code = value?.referralCode ?? "";
      if (code.isNotEmpty) return code;
      final current = _generateCode(length: length);
      return createReferral(current, uid).then((_) {
        return _updateUser(uid, {
          UserKeys.i.referralCode: current,
        }).then((_) => current);
      });
    });
  }

  static Future<UserModel?> referrer({required String? code, bool? log}) {
    final xInvalidCode = code == null || code.isEmpty;
    log.l("_apply (inValidCode: $xInvalidCode)");
    if (xInvalidCode) return Future.value(null);
    log.l("getReferral(id: $code)");
    return getReferral(code).then((value) => _getUser(value?.uid));
  }

  static Future<ReferralModel?> getReferral(String? id) {
    if (id == null || id.isEmpty) return Future.value(null);
    return FirebaseFirestore.instance
        .collection(kReferrals)
        .doc(id)
        .get()
        .then((value) {
      final data = value.data();
      if (data != null) {
        return ReferralModel.from(data);
      } else {
        return null;
      }
    });
  }

  static Duration getRemainingDuration({
    required int? createdAt,
    required int? days,
  }) {
    if (createdAt != null && days != null && days > 0) {
      final creationDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
      final expireDate = creationDate.add(Duration(days: days));
      final currentDate = DateTime.now();
      final remainingDuration = expireDate.difference(currentDate);
      return remainingDuration;
    }

    return Duration.zero;
  }

  static Future<UserModel?> _getUser(String? id) {
    if (id == null || id.isEmpty) return Future.value(null);
    return FirebaseFirestore.instance
        .collection(kUsers)
        .doc(id)
        .get()
        .then((value) {
      final data = value.data();
      if (data != null) {
        return UserModel.from(data);
      } else {
        return null;
      }
    });
  }

  static Future<bool> isEligible(String? uid, {int? days}) {
    if (uid == null || uid.isEmpty) return Future.value(false);
    return _getUser(uid).then((user) {
      return isEligibleWith(
        createdAt: user?.rewardCreatedAt,
        days: days ?? user?.rewardDuration,
      );
    });
  }

  static bool isEligibleWith({required int? createdAt, required int? days}) {
    if (createdAt != null && days != null && days > 0) {
      final creationDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
      final currentDate = DateTime.now();
      final endDate = creationDate.add(Duration(days: days));
      return currentDate.isBefore(endDate);
    }
    return false;
  }

  static Future<bool> updateDuration({
    required String? uid,
    bool allow = false,
    int changingAmount = -1,
    bool? log,
  }) {
    final xInvalidUid = uid == null || uid.isEmpty;
    final xInvalidAmount = changingAmount == 0;
    log.l(
      "_change(allow: $allow, inValidUser: $xInvalidUid invalidAmount: $xInvalidAmount)",
    );
    if (xInvalidUid || xInvalidAmount || !allow) return Future.value(false);

    log.l("updateUser(uid : $uid, changingAmount : $changingAmount)");
    return _updateUser(uid, {
      UserKeys.i.rewardDuration: FieldValue.increment(changingAmount),
    }).then((_) => log.l("done"));
  }

  static Future<bool> updateExpiry({
    required String? uid,
    required DateTime expiry,
    bool? log,
  }) {
    final xInvalidUid = uid == null || uid.isEmpty;

    if (xInvalidUid) return Future.value(false);

    log.l("updateUser(uid : $uid)");
    return _updateUser(uid, {
      UserKeys.i.rewardExpireAt: expiry.millisecondsSinceEpoch,
    }).then((_) => log.l("done"));
  }

  static Future<bool> _updateReferral(String? id, Map<String, dynamic>? data) {
    if (id == null || data == null || id.isEmpty || data.isEmpty) {
      return Future.value(false);
    }
    return FirebaseFirestore.instance
        .collection(kReferrals)
        .doc(id)
        .update(data)
        .then((_) => true);
  }

  static Future<bool> _updateUser(String? id, Map<String, dynamic>? data) {
    if (id == null || data == null || id.isEmpty || data.isEmpty) {
      return Future.value(false);
    }
    return FirebaseFirestore.instance
        .collection(kUsers)
        .doc(id)
        .update(data)
        .then((_) => true);
  }

  static Future<List<UserModel>> getUsers() {
    return FirebaseFirestore.instance.collection(kUsers).get().then((value) {
      return value.docs.map((e) => e.data()).map(UserModel.from).toList();
    });
  }

  static Stream<List<UserModel>> getStreamedUsers() {
    final controller = StreamController<List<UserModel>>();
    FirebaseFirestore.instance.collection(kUsers).snapshots().listen((value) {
      final list = value.docs.map((e) => e.data()).map(UserModel.from).toList();
      controller.add(list);
    });
    return controller.stream;
  }
}

enum Rewards {
  x1(category: 1, duration: 3),
  x2(category: 2, duration: 7),
  x3(category: 3, duration: 15);

  final int category;
  final int duration;

  const Rewards({
    required this.category,
    required this.duration,
  });

  bool get isX1 => this == x1;

  bool get isX2 => this == x2;

  bool get isX3 => this == x3;

  int get createdAt => DateTime.now().millisecondsSinceEpoch;

  int get expireAt {
    final now = DateTime.now();
    if (isX1) {
      return now.add(Duration(days: x1.duration)).millisecondsSinceEpoch;
    } else if (isX2) {
      return now.add(Duration(days: x2.duration)).millisecondsSinceEpoch;
    } else {
      return now.add(Duration(days: x3.duration)).millisecondsSinceEpoch;
    }
  }
}

class ReferralKeys {
  final id = "id";
  final uid = "uid";
  final members = "members";

  const ReferralKeys._();

  static ReferralKeys? _i;

  static ReferralKeys get i => _i ??= const ReferralKeys._();
}

class ReferralModel {
  final String? id;
  final String? uid;
  final List<String>? members;

  const ReferralModel({
    this.id,
    this.uid,
    this.members,
  });

  bool isMember(String? uid) => (members ?? []).contains(uid);

  factory ReferralModel.from(Map<String, dynamic> source) {
    final id = source[ReferralKeys.i.id];
    final uid = source[ReferralKeys.i.uid];
    final members = source[ReferralKeys.i.members];
    return ReferralModel(
      id: id is String ? id : null,
      uid: uid is String ? uid : null,
      members: members is List ? members.map((e) => "$e").toList() : null,
    );
  }

  ReferralModel copy({
    String? id,
    String? uid,
    List<String>? members,
  }) {
    return ReferralModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      members: members ?? this.members,
    );
  }

  Map<String, dynamic> get source {
    return {
      ReferralKeys.i.id: id,
      ReferralKeys.i.uid: uid,
      ReferralKeys.i.members: members?.map((e) => e.toString()),
    };
  }
}

class UserKeys {
  final id = "id";
  final redeemed = "redeemed";
  final redeemedCode = "redeemed_code";
  final referralCode = "referral_code";
  final reward = "reward";
  final rewardDuration = "reward_duration";
  final rewardCreatedAt = "reward_created_at";
  final rewardExpireAt = "reward_expire_at";

  const UserKeys._();

  static UserKeys? _i;

  static UserKeys get i => _i ??= const UserKeys._();
}

class UserModel {
  final String? id;
  final bool? redeemed;
  final String? redeemedCode;
  final String? referralCode;
  final int? reward;
  final int? rewardDuration;
  final int? rewardCreatedAt;
  final int? rewardExpireAt;

  String get noneUid {
    return id ?? DateTime.timestamp().millisecondsSinceEpoch.toString();
  }

  bool get isCurrentUid => id == "1706388765933";

  bool get isEligible {
    return ReferralService.isEligibleWith(
      createdAt: rewardCreatedAt,
      days: rewardDuration,
    );
  }

  bool get isRedeemed => redeemed ?? false;

  const UserModel({
    this.id,
    this.redeemed,
    this.redeemedCode,
    this.referralCode,
    this.reward,
    this.rewardDuration,
    this.rewardCreatedAt,
    this.rewardExpireAt,
  });

  bool isReferral(String? code) => referralCode == code;

  factory UserModel.from(Map<String, dynamic> source) {
    final id = source[UserKeys.i.id];
    final redeemed = source[UserKeys.i.redeemed];
    final redeemedCode = source[UserKeys.i.redeemedCode];
    final referralCode = source[UserKeys.i.referralCode];
    final reward = source[UserKeys.i.reward];
    final rewardDuration = source[UserKeys.i.rewardDuration];
    final rewardCreatedAt = source[UserKeys.i.rewardCreatedAt];
    final rewardExpireAt = source[UserKeys.i.rewardExpireAt];
    return UserModel(
      id: id is String ? id : null,
      redeemed: redeemed is bool ? redeemed : null,
      redeemedCode: redeemedCode is String ? redeemedCode : null,
      referralCode: referralCode is String ? referralCode : null,
      reward: reward is int ? reward : null,
      rewardDuration: rewardDuration is int ? rewardDuration : null,
      rewardCreatedAt: rewardCreatedAt is int ? rewardCreatedAt : null,
      rewardExpireAt: rewardExpireAt is int ? rewardExpireAt : null,
    );
  }

  UserModel copy({
    String? id,
    bool? redeemed,
    String? redeemedCode,
    bool redeemClear = false,
    String? referralCode,
    int? reward,
    int? rewardDuration,
    int? rewardCreatedAt,
    int? rewardExpireAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      redeemed: redeemed ?? this.redeemed,
      referralCode: referralCode ?? this.referralCode,
      redeemedCode: redeemClear ? null : redeemedCode ?? this.redeemedCode,
      reward: reward ?? this.reward,
      rewardDuration: rewardDuration ?? this.rewardDuration,
      rewardCreatedAt: rewardCreatedAt ?? this.rewardCreatedAt,
      rewardExpireAt: rewardExpireAt ?? this.rewardExpireAt,
    );
  }

  Map<String, dynamic> get source {
    return {
      UserKeys.i.id: id,
      UserKeys.i.redeemed: redeemed,
      UserKeys.i.redeemedCode: redeemedCode,
      UserKeys.i.referralCode: referralCode,
      UserKeys.i.reward: reward,
      UserKeys.i.rewardDuration: rewardDuration,
      UserKeys.i.rewardCreatedAt: rewardCreatedAt,
      UserKeys.i.rewardExpireAt: rewardExpireAt,
    };
  }
}
