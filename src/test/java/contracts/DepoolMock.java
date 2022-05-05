package contracts;

import lombok.Value;
import tech.deplant.java4ever.framework.*;
import tech.deplant.java4ever.framework.giver.Giver;

import java.math.BigInteger;
import java.util.HashMap;
import java.util.Map;

@Value
public class DepoolMock {

    AccountController controller;

    public static DepoolMock ofDeploy(ContractTemplate template, Giver giver, Sdk sdk, Credentials governanceKeys) throws Sdk.SdkException {
        var address = Address.ofFutureDeploy(sdk, template, 0, null, governanceKeys);
        Map<String, Object> msg = template.giveAndDeploy(sdk, giver, Data.EVER.multiply(new BigInteger("5")), 0, new HashMap<String, Object>(), governanceKeys, new HashMap<String, Object>());
        return new DepoolMock(AccountController.ofAddress(template.abi(), address, sdk, governanceKeys, null));
    }
}