package contracts;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import lombok.Value;
import lombok.extern.log4j.Log4j2;
import tech.deplant.java4ever.framework.AccountController;
import tech.deplant.java4ever.framework.Data;
import tech.deplant.java4ever.framework.ExplorerConfig;
import tech.deplant.java4ever.framework.Sdk;

import java.lang.reflect.Type;
import java.math.BigInteger;
import java.util.HashMap;
import java.util.Map;

@Value
@Log4j2
public class Bid {

    public final static BigInteger BID_AMOUNT_ZERO = Data.EVER.multiply(new BigInteger("0"));
    public final static BigInteger BID_AMOUNT_SMALL = Data.EVER.multiply(new BigInteger("8"));
    public final static BigInteger BID_AMOUNT_EQUALS = Data.EVER.multiply(new BigInteger("10"));
    public final static BigInteger BID_AMOUNT_LARGER = Data.EVER.multiply(new BigInteger("20"));
    public final static BigInteger BID_PRICE_E_2_N_ZERO = Data.EVER.multiply(new BigInteger("0"));
    public final static BigInteger BID_PRICE_E_2_N_SMALL = Data.EVER.multiply(new BigInteger("4"));
    public final static BigInteger BID_PRICE_E_2_N_EQUALS = Data.EVER.multiply(new BigInteger("5"));
    public final static BigInteger BID_PRICE_E_2_N_LARGER_1 = Data.EVER.multiply(new BigInteger("11"));
    public final static BigInteger BID_PRICE_E_2_N_LARGER_2 = Data.EVER.multiply(new BigInteger("12"));
    public final static BigInteger BID_PRICE_E_2_N_LARGER_3 = Data.EVER.multiply(new BigInteger("13"));
    public final static BigInteger BID_PRICE_E_2_N_LARGER_4 = Data.EVER.multiply(new BigInteger("14"));
    public final static BigInteger SALT_1 = Data.EVER.multiply(new BigInteger("9389"));
    public final static BigInteger SALT_2 = Data.EVER.multiply(new BigInteger("9388"));
    AccountController controller;

    public static Bid ofLocalConfig(ExplorerConfig config, Sdk sdk, boolean isBuyNever, int bidNumber) {
        var str = "bid" + (isBuyNever ? "EVER" : "NEVER") + bidNumber;
        try {
            return new Bid(config.accountController(str, sdk));
        } catch (Sdk.SdkException e) {
            config.removeAccountController(str);
            throw e;
        }
    }

    public static BidData bidInfo(Object bidStruct) {
        return Data.GSON.fromJson(new Gson().toJson(bidStruct), BidData.class);
    }

    public Object getRules() {
        return controller.runGetter("_rules", null).get("_rules");
    }

    public Object getBidHash() {
        var info = getBidInfo();
        return info.bidHash();
    }

    public BidData getBidInfo() {
        Type typeOfObjectsList = TypeToken.getParameterized(Map.class, BidData.class).getType();
        return bidInfo(controller.runGetter("_bid", null).get("_bid"));
    }

    public Map<String, Object> reveal(BigInteger price, BigInteger amount, BigInteger salt) throws Sdk.SdkException {
        var inputs = new HashMap<String, Object>();
        inputs.put("priceReveal_", price);
        inputs.put("amountReveal_", amount);
        inputs.put("salt_", salt);
        return controller.callInternalFromCustom(this.controller.internalOwner(),
                "reveal",
                inputs,
                amount.add(Data.EVER),
                true);
    }

    public Bid storeTo(ExplorerConfig config, boolean isBuyNever, int bidNumber) {
        var str = isBuyNever ? "EVER" : "NEVER";
        config.addAccountController("bid" + str + bidNumber, this.controller());
        return this;
    }

    @Value
    public static class BidData {
        String owner;
        BigInteger status;
        BigInteger winStatus;
        BigInteger bidHash;
        BigInteger salt;
        BigInteger priceReveal;
        BigInteger amountReveal;
    }

    public record FutureBid(Msig owner, boolean isBuyNever, BigInteger price, BigInteger amount) {
    }

}
