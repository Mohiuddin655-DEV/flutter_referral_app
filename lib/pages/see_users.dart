import 'package:flutter/material.dart';
import 'package:flutter_referral_app/pages/components/dialogs.dart';

import '../services/referral_service.dart';

class SeeAllUsersPage extends StatelessWidget {
  const SeeAllUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USERS'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: ReferralService.getStreamedUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            final items = snapshot.data ?? [];
            return ListView.builder(
              itemCount: items.length,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  decoration: BoxDecoration(
                    color: item.isEligible
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    onTap: () => Dialogs.showAlert(
                      context,
                      title: "Update",
                      message: "Are you sure, update redeemed duration?",
                    ).then((value) {
                      if (value) {
                        ReferralService.updateDuration(
                          uid: item.id,
                          allow: (item.rewardDuration ?? 0) != 0,
                        );
                      }
                    }),
                    contentPadding: const EdgeInsets.only(
                      left: 24,
                    ),
                    title: Text(
                      item.referralCode ?? "Unknown",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "${item.rewardDuration ?? 0}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: !item.isRedeemed
                          ? () => Dialogs.showEditor(
                                context,
                                title: "Apply redeem code",
                              ).then((value) {
                                if (value.length == 6) {
                                  ReferralService.redeemCode(item.id, value);
                                }
                              })
                          : null,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: Colors.black12,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 24,
                        ),
                        child: Text(
                          item.redeemedCode ?? "ADD",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
