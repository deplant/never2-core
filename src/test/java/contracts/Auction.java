package contracts;

import lombok.Value;
import lombok.extern.log4j.Log4j2;
import tech.deplant.java4ever.framework.*;

import java.math.BigInteger;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Value
@Log4j2
public class Auction {

    AccountController controller;

    public static Auction ofLocalConfig(ExplorerConfig config, Sdk sdk, boolean isBuyNever) {
        var str = isBuyNever ? "auctionEVERtoNEVER" : "auctionNEVERtoEVER";
        try {
            return new Auction(config.accountController(str, sdk));
        } catch (Sdk.SdkException e) {
            config.removeAccountController(str);
            throw e;
        } catch (NullPointerException ex) {
            config.removeAccountController(str);
            log.warn("Auction not found!");
            return null;
        }
    }

    public static BigInteger hashForCommit(BigInteger price, BigInteger amount, BigInteger salt) {
        return new BigInteger("0");
    }

    public void storeTo(ExplorerConfig config, boolean isBuyNever) {
        var str = isBuyNever ? "auctionEVERtoNEVER" : "auctionNEVERtoEVER";
        config.addAccountController(str, this.controller());
    }

    public Object getBidCount() {
        return controller.runGetter("_bidCount", null).get("_bidCount");
    }

    public Object getRevealCount() {
        return controller.runGetter("_revealCount", null).get("_revealCount");
    }

    public AuctionRules getRules() {
        return Data.GSON.fromJson(controller.runGetter("_rules", null).get("_rules").toString(), AuctionRules.class);
    }

    public Bid.BidData get1stBid() {
        return Bid.bidInfo(controller.runGetter("_1stBid", null).get("_1stBid"));
    }

    public Bid.BidData get2ndBid() {
        return Bid.bidInfo(controller.runGetter("_2ndBid", null).get("_2ndBid"));
    }

    public Bid getBid(ContractAbi bidAbi, AccountController bidder) throws Sdk.SdkException {
        var inputs = new HashMap<String, Object>();
        inputs.put("bidder_", bidder.account().address().makeAddrStd());
        return new Bid(AccountController.ofAddress(bidAbi,
                new Address(controller.runGetter("getBidAddress", inputs).get("bidAddress").toString()),
                this.controller.account().sdk(),
                null,
                bidder
        ));
    }

    public BigInteger getCommitHash(BigInteger price, BigInteger amount, BigInteger salt) {
        var inputs = new HashMap<String, Object>();
        inputs.put("priceReveal_", price);
        inputs.put("amountReveal_", amount);
        inputs.put("salt_", salt);
        return Data.hexToBigInt(controller.runGetter("getCommitHash", inputs).get("bidHash").toString());
    }

    public Map<String, Object> commit(AccountController bidder, BigInteger bidHash) throws Sdk.SdkException {
        var inputs = new HashMap<String, Object>();
        inputs.put("bidHash_", bidHash);
        return controller.callInternalFromCustom(bidder,
                "commit",
                inputs,
                Data.EVER.multiply(new BigInteger("5")),
                true);
    }

    @Value
    public static class AuctionRules {
        boolean isBuyNEVER;
        long startDate;
        long revealDate;
        long tradeDate;
        long closeDate;
        BigInteger minBid;
        BigInteger minPrice;
        BigInteger loserFactor;

        public LocalDateTime startDateTime() {
            return Data.longToDateTime(this.startDate);
        }

        public LocalDateTime revealDateTime() {
            return Data.longToDateTime(this.revealDate);
        }

        public LocalDateTime tradeDateTime() {
            return Data.longToDateTime(this.tradeDate);
        }

        public LocalDateTime closeDateTime() {
            return Data.longToDateTime(this.closeDate);
        }
    }
}
