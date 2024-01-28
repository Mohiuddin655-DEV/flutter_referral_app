import 'dart:async';
import 'dart:developer';
import 'dart:math' show Random;

import 'package:cloud_firestore/cloud_firestore.dart';

const kUsers = "users";
const kReferrals = "referrals";
const kMembers = "members";

extension _ShowLogsExtension on bool? {
  void l(dynamic msg) {
    if (this ?? true) log("$msg");
  }
}

class UserService {
  const UserService._();

  static String _generateCode({int length = 8}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      List.generate(length, (index) {
        return chars.codeUnitAt(Random().nextInt(chars.length));
      }),
    );
  }

  static Future<void> _apply({
    required UserModel? user,
    required String? code,
    bool? log,
  }) {
    final uid = user?.id;
    final xInvalidCode = code == null || code.isEmpty;
    final xInvalidUid = uid == null || uid.isEmpty;
    final xInvalidUser = user == null || xInvalidUid || user.isRedeemed;
    log.l("_apply (inValidCode: $xInvalidCode, inValidUser: $xInvalidUser)");
    if (xInvalidCode || xInvalidUser) return Future.value(null);
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
        return updateUser(uid, {
          "redeemed": true,
          "redeemed_code": referral.id,
          "reward": Rewards.x1.category,
          "reward_duration": Rewards.x1.duration,
        }).then((_) {
          log.l("updateUser(referrer.id : ${referral.uid})");
          return updateUser(referral.uid, {
            "reward": Rewards.x2.category,
            "reward_duration": FieldValue.increment(Rewards.x2.duration),
          }).then((_) {
            log.l("updateReferral(referral.id : ${referral.id})");
            return updateReferral(referral.id, {
              kMembers: FieldValue.arrayUnion([uid]),
            }).then((_) => log.l("done"));
          });
        });
      }
    });
  }

  static Future<void> _change({
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
    if (xInvalidUid || xInvalidAmount || !allow) return Future.value(null);

    log.l("updateUser(uid : $uid, changingAmount : $changingAmount)");
    return updateUser(uid, {
      "reward_duration": FieldValue.increment(changingAmount),
    }).then((_) => log.l("done"));
  }

  static Future<void> createReferral(String? id, String? uid) {
    if (id == null || uid == null || id.isEmpty || uid.isEmpty) {
      return Future.value(null);
    }
    final data = ReferralModel(id: id, uid: uid);
    return FirebaseFirestore.instance
        .collection(kReferrals)
        .doc(data.id)
        .set(data.source, SetOptions(merge: true));
  }

  static Future<void> addRedeem(String? uid, String? code, {bool? log}) {
    log.l("addRedeem(uid: $uid, code: $code)");
    if (uid == null || code == null || uid.isEmpty || code.isEmpty) {
      return Future.value(null);
    }
    log.l("getUser(current.id: $uid)");
    return getUser(uid).then((user) {
      log.l("checking current user (isRedeemed: ${user?.isRedeemed})");
      if (user != null && !user.isRedeemed) {
        return _apply(user: user, code: code);
      }
    });
  }

  static Future<void> changeRedeem({
    required String? uid,
    bool allow = false,
    int changingAmount = -1,
    bool? log,
  }) {
    return _change(
      uid: uid,
      allow: allow,
      changingAmount: changingAmount,
      log: log,
    );
  }

  static Future<void> createUser(UserModel user, {bool? log}) {
    log.l("createUser(user.source: ${user.source})");
    if (user.source.isEmpty) return Future.value(null);

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

  static Future<UserModel?> getUser(String? id) {
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

  static Future<void> updateReferral(
    String? id,
    Map<String, dynamic>? updates,
  ) {
    if (id == null || updates == null || id.isEmpty || updates.isEmpty) {
      return Future.value(null);
    }
    return FirebaseFirestore.instance
        .collection(kReferrals)
        .doc(id)
        .update(updates);
  }

  static Future<void> updateUser(
    String? id,
    Map<String, dynamic>? updates,
  ) {
    if (id == null || updates == null || id.isEmpty || updates.isEmpty) {
      return Future.value(null);
    }
    return FirebaseFirestore.instance
        .collection(kUsers)
        .doc(id)
        .update(updates);
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
    final id = source["id"];
    final uid = source["uid"];
    final referrals = source[kMembers];
    return ReferralModel(
      id: id is String ? id : null,
      uid: uid is String ? uid : null,
      members: referrals is List
          ? referrals.map((e) => e.toString()).toList()
          : null,
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
      "id": id,
      "uid": uid,
      kMembers: members?.map((e) => e.toString()),
    };
  }
}

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final bool? premium;
  final bool? redeemed;
  final String? redeemedCode;
  final String? referralCode;
  final int? reward;
  final int? rewardDuration;

  bool get isRedeemed => redeemed ?? false;

  bool get isCurrentUid => id == "1706388765933";

  bool get isRewardExpired => (rewardDuration ?? 0) < 1;

  bool get isRewardAccessible => !isRewardExpired;

  bool get isPremium => premium ?? false;

  bool get isAccessible => isPremium || isRewardAccessible;

  int get currentRewardDuration {
    if (isRewardAccessible) {
      return (rewardDuration ?? 0) - 1;
    } else {
      return 0;
    }
  }

  String get noneUid {
    return id ?? DateTime.timestamp().millisecondsSinceEpoch.toString();
  }

  const UserModel({
    this.id,
    this.email,
    this.name,
    this.premium,
    this.redeemed,
    this.redeemedCode,
    this.referralCode,
    this.reward,
    this.rewardDuration,
  });

  bool isReferral(String? code) => referralCode == code;

  factory UserModel.from(Map<String, dynamic> source) {
    final id = source["id"];
    final email = source["email"];
    final name = source["name"];
    final premium = source["premium"];
    final redeemed = source["redeemed"];
    final redeemedCode = source["redeemed_code"];
    final referralCode = source["referral_code"];
    final reward = source["reward"];
    final rewardDuration = source["reward_duration"];
    return UserModel(
      id: id is String ? id : null,
      email: email is String ? email : null,
      name: name is String ? name : null,
      premium: premium is bool ? premium : null,
      redeemed: redeemed is bool ? redeemed : null,
      redeemedCode: redeemedCode is String ? redeemedCode : null,
      referralCode: referralCode is String ? referralCode : null,
      reward: reward is int ? reward : null,
      rewardDuration: rewardDuration is int ? rewardDuration : null,
    );
  }

  UserModel copy({
    String? id,
    String? email,
    String? name,
    bool? premium,
    bool? redeemed,
    String? redeemedCode,
    String? referralCode,
    int? reward,
    int? rewardDuration,
    bool redeemClear = false,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      premium: premium ?? this.premium,
      redeemed: redeemed ?? this.redeemed,
      referralCode: referralCode ?? this.referralCode,
      redeemedCode: redeemClear ? null : redeemedCode ?? this.redeemedCode,
      reward: reward ?? this.reward,
      rewardDuration: rewardDuration ?? this.rewardDuration,
    );
  }

  Map<String, dynamic> get source {
    return {
      "id": id,
      "email": email,
      "name": name,
      "premium": premium,
      "redeemed": redeemed,
      "redeemed_code": redeemedCode,
      "referral_code": referralCode,
      "reward": reward,
      "reward_duration": rewardDuration,
    };
  }
}
