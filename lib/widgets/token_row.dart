import "package:flutter/material.dart";
import "../models/token_balance.dart";

class TokenRow extends StatelessWidget {
  final TokenBalance token;

  const TokenRow({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final symbol = token.symbol.isEmpty ? "TOKEN" : token.symbol;
    final balance = token.balance.toStringAsFixed(4);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.1),
            child: Text(
              symbol.substring(0, symbol.length > 2 ? 2 : 1),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              symbol,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            balance,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
