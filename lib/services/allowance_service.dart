import "../rpc/bsc_rpc.dart";
import "../rpc/rpc_config.dart";

class AllowanceService {
  final rpc = BscRpc(RpcConfig.bscMainnet);
  Future<String> getBalance(String wallet) async {
    final res = await rpc.call("eth_getBalance", [wallet, "latest"]);
    return (res["result"] as String?) ?? "0x0";
  }
}
