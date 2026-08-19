import 'package:flutter/material.dart';

import '../screens/wallet/wallet_screen.dart';

class WalletButton extends StatelessWidget {
  const WalletButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(
            Icons.account_balance_wallet,
          ),
        ),
        title: const Text(
          'আমার Wallet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'আপনার আয় ও Wallet Balance দেখুন',
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const WalletScreen(),
            ),
          );
        },
      ),
    );
  }
}
