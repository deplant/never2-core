package contracts;


import lombok.Value;
import lombok.extern.log4j.Log4j2;
import tech.deplant.java4ever.framework.*;
import tech.deplant.java4ever.framework.giver.Giver;

import java.math.BigInteger;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@Value
@Log4j2
public class AuctionManager {

    AccountController controller;

    public static AuctionManager ofLocalConfig(ExplorerConfig config, Sdk sdk) {
        try {
            return new AuctionManager(config.accountController("manager", sdk));
        } catch (Sdk.SdkException e) {
            config.removeAccountController("manager");
            throw e;
        }
    }

    public static AuctionManager ofDeploy(ContractTemplate managerTemplate, Giver giver, Sdk sdk, Credentials governanceKeys) throws Sdk.SdkException {
        var address = Address.ofFutureDeploy(sdk, managerTemplate, 0, null, governanceKeys);
        Map<String, Object> msg = managerTemplate.giveAndDeploy(sdk, giver, Data.EVER.multiply(new BigInteger("5")), 0, new HashMap<String, Object>(), governanceKeys, new HashMap<String, Object>());
        return new AuctionManager(AccountController.ofAddress(managerTemplate.abi(), address, sdk, governanceKeys, null));
    }

    public void storeTo(ExplorerConfig config) {
        config.addAccountController("manager", this.controller());
    }

    public Auction getEVERtoNEVERAuction(ContractAbi abi) throws Sdk.SdkException {
        return new Auction(AccountController.ofAddress(
                abi,
                new Address(
                        String.valueOf(controller.runGetter("_currentBuyNEVERAuction", null).get("_currentBuyNEVERAuction"))
                ),
                controller.account().sdk(),
                null,
                null
        ));
    }

    public Auction getNEVERtoEVERAuction(ContractAbi abi) throws Sdk.SdkException {
        return new Auction(AccountController.ofAddress(
                abi,
                new Address(
                        String.valueOf(controller.runGetter("_currentBuyEVERAuction", null).get("_currentBuyEVERAuction"))
                ),
                controller.account().sdk(),
                null,
                null
        ));
    }

    public Map<String, Object> setNEVERBidCode(ContractTemplate bidTemplate) throws Sdk.SdkException {
        var inputs = new HashMap<String, Object>();
        inputs.put("code_", bidTemplate.tvc().code(controller.account().sdk()));
        return controller.callExternalFromOwner("setNEVERBidCode", inputs);
    }

    public Map<String, Object> setEVERBidCode(ContractTemplate bidTemplate) throws Sdk.SdkException {
        var inputs = new HashMap<String, Object>();
        inputs.put("code_", bidTemplate.tvc().code(controller.account().sdk()));
        return controller.callExternalFromOwner("setEVERBidCode", inputs);
    }

    public Map<String, Object> setNEVERRoot(Address address) throws Sdk.SdkException {
        var inputs = new HashMap<String, Object>();
        inputs.put("neverRoot_", address.makeAddrStd());
        return controller.callExternalFromOwner("setNEVERRoot", inputs);
    }

    public Map<String, Object> setEVERReserve(Address address) throws Sdk.SdkException {
        var inputs = new HashMap<String, Object>();
        inputs.put("everReserve_", address.makeAddrStd());
        return controller.callExternalFromOwner("setEVERReserve", inputs);
    }

    public Map<String, Object> setAuctionCode(ContractTemplate auctionTemplate) throws Sdk.SdkException {
        var inputs = new HashMap<String, Object>();
        inputs.put("code_", auctionTemplate.tvc().code(controller.account().sdk()));
        return controller.callExternalFromOwner("setAuctionCode", inputs);
    }

    public Map<String, Object> setMinBid(BigInteger amount) throws Sdk.SdkException {
        var inputs = new HashMap<String, Object>();
        inputs.put("minBid_", amount);
        return controller.callExternalFromOwner("setMinBid", inputs);
    }

    public Map<String, Object> setElector(Address address) throws Sdk.SdkException {
        var inputs = new HashMap<String, Object>();
        inputs.put("elector_", address.makeAddrStd());
        return controller.callExternalFromOwner("setElector", inputs);
    }

    public Map<String, Object> startAuctionsFromMockElector(AccountController mockElectorMsig, Instant dtStart, BigInteger minPrice) throws Sdk.SdkException {
        var inputs = new HashMap<String, Object>();
        inputs.put("dtStart_", dtStart);
        return controller.callInternalFromCustom(mockElectorMsig,
                "startAuctions",
                inputs,
                Data.EVER.multiply(new BigInteger("5")),
                true);
    }


}
