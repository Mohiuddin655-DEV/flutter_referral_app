import 'package:flutter/material.dart';

import '../services/user_service.dart';
import 'components/add_redeem_dialog.dart';

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
          stream: UserService.getStreamedUsers(),
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
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    onTap: () {
                      UserService.changeRedeem(
                        uid: item.id,
                        allow: (item.rewardDuration ?? 0) != 0,
                      );
                    },
                    contentPadding: const EdgeInsets.only(
                      left: 24,
                    ),
                    title: Text(
                      item.name ?? "Unknown",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      item.email ?? "example@gmail.com",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: !item.isRedeemed
                          ? () {
                              AddRedeemDialog.show(
                                context: context,
                                callback: (context, value) {
                                  UserService.addRedeem(item.id, value);
                                },
                              );
                            }
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
                          item.isRedeemed
                              ? "${item.rewardDuration ?? 0}"
                              : "ADD",
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
