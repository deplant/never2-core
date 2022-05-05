package contracts;

import lombok.Value;
import tech.deplant.java4ever.framework.*;
import tech.deplant.java4ever.framework.giver.Giver;

import java.math.BigInteger;
import java.util.HashMap;
import java.util.Map;

@Value
public class Msig {

    AccountController controller;

    public static Msig ofDeploy(Credentials keys, Giver giver, Sdk sdk) throws Sdk.SdkException {
        var template = ContractTemplate.SAFE_MULTISIG;
        var address = Address.ofFutureDeploy(sdk, ContractTemplate.SAFE_MULTISIG, 0, null, keys);
        giver.give(address, Data.EVER);
        var params = new HashMap<String, Object>();
        params.put("owners", new String[]{"0x" + keys.publicKey()});
        params.put("reqConfirms", 1);
        Map<String, Object> msg = template.deploy(sdk, 0, null, keys, params);
        return new Msig(AccountController.ofAddress(template.abi(), address, sdk, keys, null));
    }

    public static Msig ofLocalConfig(ExplorerConfig config, Sdk sdk, int msigNumber) throws Sdk.SdkException {
        return new Msig(config.accountController("msig" + msigNumber, sdk));
    }

    public void storeTo(ExplorerConfig config, int msigNumber) {
        config.addAccountController("msig" + msigNumber, this.controller());
    }

    public void send(Address to, BigInteger amount, boolean sendBounce, String payload) throws Sdk.SdkException {
        var params = new HashMap<String, Object>();
        params.put("dest", to.makeAddrStd());
        params.put("value", amount);
        params.put("bounce", sendBounce);
        params.put("flags", 1);
        params.put("payload", payload);
        this.controller.callExternalFromOwner("sendTransaction", params);
    }

}
