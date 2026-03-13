import "package:drainshield_app/services/rpc_service.dart";

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print("Usage: dart run tool/rpc_smoketest.dart <0xYourAddress>");
    return;
  }
  final addr = args[0];
  final chainId = await DsRpc.getChainId();
  final wei = await DsRpc.getBalanceWei(addr);
  final bnb = DsRpc.weiToBnb(wei);
  print("RPC: ${DsRpc.rpcUrl}");
  print("chainId: $chainId");
  print("address: $addr");
  print("balanceWei: $wei");
  print("balanceBNB: $bnb");
}
