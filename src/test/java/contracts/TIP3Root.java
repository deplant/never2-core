package contracts;

import lombok.Value;
import lombok.extern.log4j.Log4j2;
import tech.deplant.java4ever.framework.*;
import tech.deplant.java4ever.framework.giver.Giver;

import java.math.BigInteger;
import java.util.HashMap;
import java.util.Map;

@Value
@Log4j2
public class TIP3Root {

    AccountController controller;

    public static AuctionManager ofDeploy(ContractTemplate managerTemplate, Giver giver, Sdk sdk, Credentials governanceKeys) throws Sdk.SdkException {
        var address = Address.ofFutureDeploy(sdk, managerTemplate, 0, null, governanceKeys);
        Map<String, Object> msg = managerTemplate.giveAndDeploy(sdk, giver, Data.EVER.multiply(new BigInteger("5")), 0, new HashMap<String, Object>(), governanceKeys, new HashMap<String, Object>());
        return new AuctionManager(AccountController.ofAddress(managerTemplate.abi(), address, sdk, governanceKeys, null));
    }

    public static AuctionManager ofLocalConfig(ExplorerConfig config, Sdk sdk) {
        try {
            return new AuctionManager(config.accountController("manager", sdk));
        } catch (Sdk.SdkException e) {
            config.removeAccountController("manager");
            throw e;
        }
    }

    public void storeTo(ExplorerConfig config) {
        config.addAccountController("manager", this.controller());
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
