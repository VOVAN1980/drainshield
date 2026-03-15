import "../models/approval.dart";
import "../models/gas_estimation_result.dart";
import "erc20_abi.dart";
import "wc_service.dart";
import "../config/chains.dart";
import "package:reown_appkit/reown_appkit.dart";

class RevokeService {
  static final BigInt _zero = BigInt.zero;

  /// Returns txHash (if wallet returns it)
  static Future<String> revokeApproval({required ApprovalData a}) async {
    final data = Erc20Abi.encodeApprove(
      spender: a.spenderAddress,
      value: _zero,
    );
    if (a.chainId == 0) {
      throw "Cannot revoke: Unsupported or unapproved network. Revocation cancelled to protect wallet.";
    }
    final wc = WcService();
    if (wc.currentChainId != a.chainId) {
      throw "Wrong network selected in wallet. Please switch to the correct network before revoking.";
    }
    if (!wc.isConnected) {
      throw StateError("Wallet not connected");
    }
    final from = wc.address;
    if (from.isEmpty) {
      throw StateError("Wallet address not available");
    }
    final modal = wc.modal;
    if (modal == null) {
      throw StateError("WalletConnect modal not initialized");
    }
    final tx = <String, dynamic>{
      "from": from,
      "to": a.token,
      "data": data,
      "value": "0x0",
    };
    final session = modal.session;
    if (session == null) {
      throw StateError("No active session");
    }

    try {
      final res = await modal.request(
        topic: session.topic,
        chainId: "eip155:${a.chainId}",
        request: SessionRequestParams(
          method: "eth_sendTransaction",
          params: [tx],
        ),
      );
      return res?.toString() ?? "";
    } catch (e) {
      final err = e.toString().toLowerCase();
      final symbol = ChainConfig.getNativeSymbol(a.chainId);
      if (err.contains("insufficient funds")) {
        throw "Not enough $symbol to pay gas (~0.001 $symbol required)";
      }
      if (err.contains("user denied") || err.contains("rejected")) {
        throw "Transaction was rejected in the wallet";
      }
      throw "Network error while sending transaction";
    }
  }

  /// Estimates the gas required for the revoke transaction
  static Future<GasEstimationResult> estimateGas({
    required ApprovalData a,
  }) async {
    final data = Erc20Abi.encodeApprove(
      spender: a.spenderAddress,
      value: _zero,
    );
    if (a.chainId == 0) {
      throw "Cannot estimate gas: Unsupported network.";
    }
    final wc = WcService();
    if (wc.currentChainId != a.chainId) {
      throw "Wrong network selected in wallet. Please switch to the correct network before revoking.";
    }
    if (!wc.isConnected) {
      throw StateError("Wallet not connected");
    }
    final from = wc.address;
    if (from.isEmpty) {
      throw StateError("Wallet address not available");
    }
    final modal = wc.modal;
    if (modal == null) {
      throw StateError("WalletConnect modal not initialized");
    }
    final tx = <String, dynamic>{
      "from": from,
      "to": a.token,
      "data": data,
      "value": "0x0",
    };
    final session = modal.session;
    if (session == null) {
      throw StateError("No active session");
    }

    try {
      // Get gas estimate
      final gasEstimate = await modal.request(
        topic: session.topic,
        chainId: "eip155:${a.chainId}",
        request: SessionRequestParams(method: "eth_estimateGas", params: [tx]),
      );

      // Get current gas price
      final gasPrice = await modal.request(
        topic: session.topic,
        chainId: "eip155:${a.chainId}",
        request: const SessionRequestParams(method: "eth_gasPrice", params: []),
      );

      // Parse hexadecimal to BigInt
      BigInt estGas = BigInt.parse(
        gasEstimate?.toString().replaceFirst('0x', '') ?? '0',
        radix: 16,
      );
      BigInt estPrice = BigInt.parse(
        gasPrice?.toString().replaceFirst('0x', '') ?? '0',
        radix: 16,
      );

      // Add a 20% buffer to gas estimate to be safe
      estGas = BigInt.from(estGas.toDouble() * 1.2);

      return GasEstimationResult(
        estimatedGas: estGas,
        estimatedGasPrice: estPrice,
        symbol: ChainConfig.getNativeSymbol(a.chainId),
      );
    } catch (e) {
      throw "Failed to estimate gas: ${e.toString()}";
    }
  }
}
