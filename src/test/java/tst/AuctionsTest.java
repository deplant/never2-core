package tst;

import contracts.Auction;
import contracts.AuctionManager;
import contracts.Bid;
import contracts.Msig;
import lombok.extern.log4j.Log4j2;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import tech.deplant.java4ever.binding.loader.JavaLibraryPathLoader;
import tech.deplant.java4ever.framework.*;
import tech.deplant.java4ever.framework.artifact.FileArtifact;
import tech.deplant.java4ever.framework.giver.EverOSGiver;
import tech.deplant.java4ever.framework.giver.Giver;

import java.io.IOException;
import java.math.BigInteger;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Test set that:
 * <p>
 * - Use TON-SDK
 * - Made for NEVER Phase II Contest
 */
@Log4j2
public class AuctionsTest {

    final static ArtifactConfig EVER_CONFIG = new ArtifactConfig(FileArtifact.ofResourcePath("config.json"));
    final static ExplorerConfig LOCAL_CONFIG = ExplorerConfig.ofConfigFile(FileArtifact.ofResourcePath("auction.json"));
    //final static TvmLinker TVM_LINKER = EVER_CONFIG.getTvmLinker();
    //final static Solc SOLIDITY_COMPILER = EVER_CONFIG.getSolidityCompiler();
    final static Sdk SDK = new SdkBuilder()
            .networkEndpoint(new String[]{"http://80.78.254.199/"})
            .timeout(50L)
            .create(new JavaLibraryPathLoader());

    //TODO Winning EVER Bid -> DePool Stake (staker - Elector)
    // Rewards from staking -> 1/2 Validators + 1/2 EVER Reserve
    static Giver seGiver;

    static Credentials managerKeys;
    static LocalDateTime revealTime;
    static LocalDateTime tradeTime;
    static LocalDateTime closeTime;
    static Msig[] msigs = new Msig[6];
    static Bid.FutureBid[] bidders = new Bid.FutureBid[6];
    static AuctionManager manager;
    static Auction everToNever;
    static Auction neverToEver;
    static Bid[] everBids = new Bid[6];
    static Bid[] neverBids = new Bid[6];
    static AccountController governanceOfManager;
    Map<String, ContractTemplate> templates = new HashMap<>();

//    public static void compileSources() {
//        // Bank
//        ContractTemplate.ofSoliditySource(SOLIDITY_COMPILER, TVM_LINKER, EVER_CONFIG.sourcePath, EVER_CONFIG.buildPath, "AuctionManager.sol", "AuctionManager");
//        // Auction
//        ContractTemplate.ofSoliditySource(SOLIDITY_COMPILER, TVM_LINKER, EVER_CONFIG.sourcePath, EVER_CONFIG.buildPath, "Auction.sol", "Auction");
//        // Bid Implementations
//        ContractTemplate.ofSoliditySource(SOLIDITY_COMPILER, TVM_LINKER, EVER_CONFIG.sourcePath, EVER_CONFIG.buildPath, "BidEVER.sol", "BidEVER");
//        ContractTemplate.ofSoliditySource(SOLIDITY_COMPILER, TVM_LINKER, EVER_CONFIG.sourcePath, EVER_CONFIG.buildPath, "BidCC.sol", "BidCC");
//        ContractTemplate.ofSoliditySource(SOLIDITY_COMPILER, TVM_LINKER, EVER_CONFIG.sourcePath, EVER_CONFIG.buildPath, "BidTIP3.sol", "BidTIP3");
//        // DAuction Implementations
//        ContractTemplate.ofSoliditySource(SOLIDITY_COMPILER, TVM_LINKER, EVER_CONFIG.sourcePath, EVER_CONFIG.buildPath, "DAuctionEVER.sol", "DAuctionEVER");
//        ContractTemplate.ofSoliditySource(SOLIDITY_COMPILER, TVM_LINKER, EVER_CONFIG.sourcePath, EVER_CONFIG.buildPath, "DAuctionCC.sol", "DAuctionCC");
//        ContractTemplate.ofSoliditySource(SOLIDITY_COMPILER, TVM_LINKER, EVER_CONFIG.sourcePath, EVER_CONFIG.buildPath, "DAuctionTIP3.sol", "DAuctionTIP3");
//    }

    public static Msig getOrSpawnMsig(int msigNumber, Giver giver) {
        Msig msig = null;
        try {
            msig = Msig.ofLocalConfig(LOCAL_CONFIG, SDK, msigNumber);
        } catch (Sdk.SdkException e) {
            log.error("CODE: " + e.error().code() + "MSG: " + e.error().message());
            try {
                msig = Msig.ofDeploy(Credentials.ofRandom(SDK), giver, SDK);
                msig.storeTo(LOCAL_CONFIG, msigNumber);
            } catch (Sdk.SdkException ex) {
                log.error("CODE: " + ex.error().code() + "MSG: " + ex.error().message());
                throw new RuntimeException("New Msig Deployment Error!");
            }
        }
        return msig;
    }

    @BeforeAll
    public static void loadFromConfig() throws IOException, Sdk.SdkException {
        try {
            seGiver = new EverOSGiver(SDK);
        } catch (Sdk.SdkException e) {
            log.error("CODE: " + e.error().code() + "MSG: " + e.error().message());
            throw new RuntimeException("Giver initialization error!");
        }
        managerKeys = new Credentials("643f34aa1a14745048d561ab1078b231f20a015c79afb623b5710d6b4228b747", "15288cc5537da3108c9c751c503b1954ac56af696b256b91001f1c3924c690ac");

        msigs[0] = getOrSpawnMsig(0, seGiver);
        msigs[1] = getOrSpawnMsig(1, seGiver);
        msigs[2] = getOrSpawnMsig(2, seGiver);
        msigs[3] = getOrSpawnMsig(3, seGiver);
        msigs[4] = getOrSpawnMsig(4, seGiver);
        msigs[5] = getOrSpawnMsig(5, seGiver);

        bidders[0] = new Bid.FutureBid(msigs[0], true, Bid.BID_PRICE_E_2_N_SMALL, Bid.BID_AMOUNT_LARGER);
        bidders[1] = new Bid.FutureBid(msigs[1], true, Bid.BID_PRICE_E_2_N_EQUALS, Bid.BID_AMOUNT_EQUALS);
        bidders[2] = new Bid.FutureBid(msigs[2], true, Bid.BID_PRICE_E_2_N_LARGER_1, Bid.BID_AMOUNT_EQUALS);
        bidders[3] = new Bid.FutureBid(msigs[3], true, Bid.BID_PRICE_E_2_N_LARGER_4, Bid.BID_AMOUNT_EQUALS);
        bidders[4] = new Bid.FutureBid(msigs[4], true, Bid.BID_PRICE_E_2_N_LARGER_2, Bid.BID_AMOUNT_SMALL);
        bidders[5] = new Bid.FutureBid(msigs[5], true, Bid.BID_PRICE_E_2_N_LARGER_3, Bid.BID_AMOUNT_LARGER);

        manager = AuctionManager.ofLocalConfig(LOCAL_CONFIG, SDK);
        everToNever = Auction.ofLocalConfig(LOCAL_CONFIG, SDK, true);
        neverToEver = Auction.ofLocalConfig(LOCAL_CONFIG, SDK, false);
        for (int i = 0; i < 6; i++) {
            everBids[i] = Bid.ofLocalConfig(LOCAL_CONFIG, SDK, true, i);
        }
        for (int i = 0; i < 6; i++) {
            neverBids[i] = Bid.ofLocalConfig(LOCAL_CONFIG, SDK, false, i);
        }
        governanceOfManager = AccountController.ofAddress(
                ContractAbi.SAFE_MULTISIG,
                new Address("0:a9bac404ec0c47e14260c74fbfd2bdbf120de46f49de78b3439e82665cada0c8"),
                SDK,
                new Credentials(
                        "643f34aa1a14745048d561ab1078b231f20a015c79afb623b5710d6b4228b747",
                        "15288cc5537da3108c9c751c503b1954ac56af696b256b91001f1c3924c690ac"),
                null
        );

        LOCAL_CONFIG.store("src/test/resources/auction.json");
    }

    public void fillTemplates() {
        this.templates.put("tip3-root", EVER_CONFIG.getTemplate("TIP3Root"));
        this.templates.put("tip3-wallet", EVER_CONFIG.getTemplate("TIP3Wallet"));
        this.templates.put("elector", EVER_CONFIG.getTemplate("NotElector"));
        this.templates.put("validator", EVER_CONFIG.getTemplate("NotValidator"));
        this.templates.put("depool", EVER_CONFIG.getTemplate("DePoolMock"));
        this.templates.put("manager", EVER_CONFIG.getTemplate("AuctionManager"));
        this.templates.put("auction", EVER_CONFIG.getTemplate("Auction"));
        this.templates.put("bid-cc", EVER_CONFIG.getTemplate("BidCC"));
        this.templates.put("bid-tip3", EVER_CONFIG.getTemplate("BidTIP3"));
        this.templates.put("bid-ever", EVER_CONFIG.getTemplate("BidEVER"));
    }

    @Test
    @DisplayName("getAllManagerPublics")
    public void getAllManagerPublics() {
        log.debug("Governance: " + manager.controller().runGetter("_governance", null).get("_governance"));
        log.debug("Elector: " + manager.controller().runGetter("_elector", null).get("_elector"));
        log.debug("Auction Code: " + manager.controller().runGetter("_auctionCode", null).get("_auctionCode"));
        log.debug("EVER Bid Code: " + manager.controller().runGetter("_everBidCode", null).get("_everBidCode"));
        log.debug("NEVER Bid Code: " + manager.controller().runGetter("_neverBidCode", null).get("_neverBidCode"));
        log.debug("Commit Step Duration: " + manager.controller().runGetter("_commitDuration", null).get("_commitDuration"));
        log.debug("Reveal Step Duration: " + manager.controller().runGetter("_revealDuration", null).get("_revealDuration"));
        log.debug("Trade Step Duration: " + manager.controller().runGetter("_tradeDuration", null).get("_tradeDuration"));
        log.debug("MinBid: " + manager.controller().runGetter("_minBid", null).get("_minBid"));
    }

    @Test
    public void getAuctionPublics() {
        //
        log.debug("EVER->NEVER Address: " + everToNever.controller().account().address());
        //log.debug("EVER->NEVER ABI: " + everToNever.controller().account().abi().abiJsonString());
        var rules = everToNever.getRules();
        log.debug("EVER->NEVER Min Bid: " + rules.minBid());
        log.debug("EVER->NEVER Min Price: " + rules.minPrice());

        revealTime = rules.revealDateTime();
        tradeTime = rules.tradeDateTime();
        closeTime = rules.closeDateTime();

        log.debug("EVER->NEVER Start time: " + Data.dateTimeToString(rules.startDateTime()));
        log.debug("EVER->NEVER Reveal time: " + Data.dateTimeToString(revealTime));
        log.debug("EVER->NEVER Trade time: " + Data.dateTimeToString(tradeTime));
        log.debug("EVER->NEVER Close time: " + Data.dateTimeToString(closeTime));

        log.debug("EVER->NEVER Bid Count: " + everToNever.getBidCount());
        log.debug("EVER->NEVER Reveal Count: " + everToNever.getRevealCount());
    }

    public Bid commitBid(Bid.FutureBid intention, BigInteger salt) throws Sdk.SdkException {
        var auction = intention.isBuyNever() ? everToNever : neverToEver;
        var hash = auction.getCommitHash(intention.price(), intention.amount(), salt);
        auction.commit(intention.owner().controller(), hash);
        var bid = auction.getBid(templates.get("bid-ever").abi(), intention.owner().controller());
        Bid.BidData info = bid.getBidInfo();
        log.debug("Bid address: " + bid.controller().account().address().makeAddrStd());
        log.debug("Bid commited. owner: " + info.owner());
        log.debug("Bid commited. HASH: " + info.bidHash());
        log.debug("Bid commited. PRICE: " + intention.price());
        log.debug("Bid commited. AMOUNT: " + intention.amount());
        log.debug("Bid commited. STATUS: " + info.status());
        auction.controller().refresh();
        return bid;
    }

    @Test
    @DisplayName("revealBid")
    public void revealEVERBid(Auction auction, Bid bid, BigInteger price, BigInteger amount, BigInteger salt) throws Sdk.SdkException {
        bid.reveal(price, amount, salt);
        auction.controller().refresh();
    }

    public Bid revealBid(Bid bid, Bid.FutureBid intention, BigInteger salt) throws Sdk.SdkException {
        var auction = intention.isBuyNever() ? everToNever : neverToEver;
        bid.reveal(intention.price(), intention.amount(), salt);
        auction.controller().refresh();
        Bid.BidData info = bid.getBidInfo();
        log.debug("Bid address: " + bid.controller().account().address().makeAddrStd());
        log.debug("Bid revealed. owner: " + info.owner());
        if (info.status().compareTo(new BigInteger("0")) > 0) {
            log.debug("Bid revealed. HASH: " + info.bidHash());
            log.debug("Bid revealed. STATUS: " + info.status());
            log.debug("Bid revealed. PRICE: " + info.priceReveal());
            log.debug("Bid revealed. AMOUNT: " + info.amountReveal());
        } else {
            log.debug("Bid reveal failed." + info.status());
        }
        return bid;
    }

    @Test
    public void checkBid() {
        fillTemplates();
        var bid = Bid.ofLocalConfig(LOCAL_CONFIG, SDK, true, 4);
        var info = bid.getBidInfo();
        log.debug("Bid address: " + bid.controller().account().address().makeAddrStd());
        log.debug("Bid revealed. HASH: " + info.bidHash());
        log.debug("Bid revealed. PRICE: " + info.priceReveal());
        log.debug("Bid revealed. AMOUNT: " + info.amountReveal());
        log.debug("Bid revealed. STATUS: " + info.status());
    }


    @Test
    @DisplayName("startAuction")
    public void startAuctionRound() throws Sdk.SdkException {
        fillTemplates();
        manager.setMinBid(Data.EVER.multiply(new BigInteger("10")));
        manager.startAuctionsFromMockElector(governanceOfManager, Instant.now(), Data.EVER.multiply(new BigInteger("10")));
        everToNever = manager.getEVERtoNEVERAuction(templates.get("auction").abi());
        neverToEver = manager.getNEVERtoEVERAuction(templates.get("auction").abi());
    }

    public Address tip3RootSetup() throws Sdk.SdkException {
        // 0 Deploy TIP3.1Root with MANAGER as Owner!
        var rootTemplate = templates.get("tip3-root");
        var walletTemplate = templates.get("tip3-wallet");

        var initialData = new HashMap<String, Object>();
        initialData.put("name_", Data.strToHex("NEVER TIP3.1 Token"));
        initialData.put("symbol_", Data.strToHex("NEVER"));
        initialData.put("decimals_", 9);
        initialData.put("rootOwner_", manager.controller().account().address().makeAddrStd());
        initialData.put("walletCode_", walletTemplate.tvc().code(SDK));
        initialData.put("totalSupply_", 0);
        initialData.put("randomNonce_", 0);
        initialData.put("deployer_", Address.ZERO.makeAddrStd());

        var constructorInputs = new HashMap<String, Object>();
        constructorInputs.put("initialSupplyTo", Address.ZERO.makeAddrStd());
        constructorInputs.put("initialSupply", 0);
        constructorInputs.put("deployWalletValue", 0);
        constructorInputs.put("mintDisabled", false);
        constructorInputs.put("burnByRootDisabled", false);
        constructorInputs.put("burnPaused", false);
        constructorInputs.put("remainingGasTo", Address.ZERO.makeAddrStd());

        var deployerKeys = Credentials.ofRandom(SDK);
        var address = Address.ofFutureDeploy(SDK, rootTemplate, 0, initialData, deployerKeys);
        Map<String, Object> msg = rootTemplate.giveAndDeploy(SDK, seGiver, Data.EVER.multiply(new BigInteger("2")), 0, initialData, deployerKeys, constructorInputs);
        return address;
    }

    @Test
    @DisplayName("recompile")
    public void recompile() throws IOException, Sdk.SdkException {
        //compileSources();
    }

    public void managerSetup() throws Sdk.SdkException {
        try {
            manager = AuctionManager.ofDeploy(templates.get("manager"), seGiver, SDK, managerKeys);
        } catch (Sdk.SdkException ex) {
            if (ex.error().code() == 414) {
                log.error("Ooops! This contract already deployed!");
            } else {
                throw ex;
            }
        }

        var neverRootAddress = tip3RootSetup();

        manager.setElector(governanceOfManager.account().address());
        manager.setAuctionCode(templates.get("auction"));
        manager.setNEVERBidCode(templates.get("bid-tip3"));
        manager.setEVERBidCode(templates.get("bid-ever"));
        manager.setNEVERRoot(neverRootAddress);
    }

    @Test
    @DisplayName("fullTest")
    public void fullTest() throws IOException, Sdk.SdkException {
        //compileSources();
        fillTemplates();
        managerSetup();

        log.info("MANAGER Address: " + manager.controller().account().address().makeAddrStd());
        manager.storeTo(LOCAL_CONFIG);
        LOCAL_CONFIG.store("src/test/resources/auction.json");

        startAuctionRound();

        log.info("NEVER->EVER Address: " + neverToEver.controller().account().address().makeAddrStd());
        neverToEver.storeTo(LOCAL_CONFIG, false);
        log.info("EVER->NEVER Address: " + everToNever.controller().account().address().makeAddrStd());
        everToNever.storeTo(LOCAL_CONFIG, true);

        LOCAL_CONFIG.store("src/test/resources/auction.json");

        seGiver.give(msigs[0].controller().account().address(), Data.EVER.multiply(new BigInteger("25")));
        seGiver.give(msigs[1].controller().account().address(), Data.EVER.multiply(new BigInteger("25")));
        seGiver.give(msigs[2].controller().account().address(), Data.EVER.multiply(new BigInteger("25")));
        seGiver.give(msigs[3].controller().account().address(), Data.EVER.multiply(new BigInteger("25")));
        seGiver.give(msigs[4].controller().account().address(), Data.EVER.multiply(new BigInteger("25")));
        seGiver.give(msigs[5].controller().account().address(), Data.EVER.multiply(new BigInteger("25")));

        everBids[0] = commitBid(bidders[0], Bid.SALT_1).storeTo(LOCAL_CONFIG, true, 0);
        everBids[1] = commitBid(bidders[1], Bid.SALT_1).storeTo(LOCAL_CONFIG, true, 1);
        everBids[2] = commitBid(bidders[2], Bid.SALT_1).storeTo(LOCAL_CONFIG, true, 2);
        everBids[3] = commitBid(bidders[3], Bid.SALT_1).storeTo(LOCAL_CONFIG, true, 3);
        everBids[4] = commitBid(bidders[4], Bid.SALT_1).storeTo(LOCAL_CONFIG, true, 4);
        everBids[5] = commitBid(bidders[5], Bid.SALT_1).storeTo(LOCAL_CONFIG, true, 5);

        LOCAL_CONFIG.store("src/test/resources/auction.json");

        getAuctionPublics();
        while (revealTime != null && revealTime.compareTo(LocalDateTime.now()) > 0) {

        }
        log.debug("Time comes! Reveal! " + Data.dateTimeToString(LocalDateTime.now()));

        try {
            revealBid(everBids[0], bidders[0], Bid.SALT_1);
        } catch (Sdk.SdkException e) {
            if (e.error().code() == 407) {
                log.error("Not enough funds to confirm bid.");
            } else {
                throw e;
            }
        }

        try {
            revealBid(everBids[1], bidders[1], Bid.SALT_1);
        } catch (Sdk.SdkException e) {
            if (e.error().code() == 407) {
                log.error("Not enough funds to confirm bid.");
            } else {
                throw e;
            }
        }
        try {
            revealBid(everBids[2], bidders[2], Bid.SALT_1);
        } catch (Sdk.SdkException e) {
            if (e.error().code() == 407) {
                log.error("Not enough funds to confirm bid.");
            } else {
                throw e;
            }
        }
        try {
            revealBid(everBids[3], bidders[3], Bid.SALT_1);
        } catch (Sdk.SdkException e) {
            if (e.error().code() == 407) {
                log.error("Not enough funds to confirm bid.");
            } else {
                throw e;
            }
        }
        try {
            revealBid(everBids[4], bidders[4], Bid.SALT_1);
        } catch (Sdk.SdkException e) {
            if (e.error().code() == 407) {
                log.error("Not enough funds to confirm bid.");
            } else {
                throw e;
            }
        }
        try {
            revealBid(everBids[5], bidders[5], Bid.SALT_1);
        } catch (Sdk.SdkException e) {
            if (e.error().code() == 407) {
                log.error("Not enough funds to confirm bid.");
            } else {
                throw e;
            }
        }

        getAuctionPublics();
        log.debug("EVER->NEVER Auction Total. 1st bid owner: " + everToNever.get1stBid().owner());
        log.debug("EVER->NEVER Auction Total. 1st bid price: " + everToNever.get1stBid().priceReveal());
        log.debug("EVER->NEVER Auction Total. 1st bid amount: " + everToNever.get1stBid().amountReveal());
        log.debug("EVER->NEVER Auction Total. 2nd bid owner: " + everToNever.get2ndBid().owner());
        log.debug("EVER->NEVER Auction Total. 2nd bid price: " + everToNever.get2ndBid().priceReveal());
        log.debug("EVER->NEVER Auction Total. 2nd bid amount: " + everToNever.get2ndBid().amountReveal());

        // Auction end check!
        // manager.tradeAuctions();

        // get Bid statuses


        // 1 if Bid not revealed - miss

        // 2 if Bid revealed and lost

        // 2.1 refund lost bid
        // 2.2 check funds refunded (full amount)

        // 2.3 trade lost bid
        // 2.4 check funds sent (full amount)
        // 2.5 check NEVERs acquired (amount from loserPrice)

        // 3 if Bid revealed and won

        // 3.1 check funds sent (full amount)
        // 3.2 check NEVERs acquired (amount from winningPrice)

        // DAuction !

    }


    // NEVER DePoolMock Deployment
    @Test
    @DisplayName("test DePoolMock deploy")
    public void testDePoolMockDeploy() throws Sdk.SdkException {
        var keys = Credentials.ofRandom(this.SDK);
        log.debug("Public: " + keys.publicKey());
        log.debug("Secret: " + keys.secretKey());
        var address = Address.ofFutureDeploy(this.SDK, templates.get("depool"), 0, null, keys);
        log.debug("Future address: " + address.makeAddrStd());

        seGiver.give(address, Data.EVER.multiply(new BigInteger("1")));

        Map<String, Object> msg = templates.get("depool").deploy(this.SDK, 0, null, keys, null);

    }

    // NEVER DePoolMock Deployment
    @Test
    @DisplayName("test DePoolMock transferStake call")
    public void testDePoolMockCallTransferStake() throws Sdk.SdkException {
        var keys = new Credentials("3b6f5c626dae475183b46afec0a6fe777d2663b7872c3c674cabb9fc1f75651b", "4af978eb58fde85678838d9c583a2cd9079b1f7972f374ed8fad3f692b08d6f8");
        log.debug("Public: " + keys.publicKey());
        log.debug("Secret: " + keys.secretKey());
        var address = new Address("0:7e9b82a46957f69c097b8c30f85eb45870826d29826193e0de5999789884f9f2");
        log.debug("Future address: " + address.makeAddrStd());

        Account account = Account.ofAddress(
                this.SDK,
                address,
                templates.get("depool").abi()
        );

        var params = new HashMap<String, Object>();
        params.put("dest", address.makeAddrStd());
        params.put("amount", Data.MILLIEVER.toString());
        account.callExternal(keys, "transferStake", params);

    }

    // NEVER Elector Deployment
    @Test
    @DisplayName("test Elector deploy")
    public void testElectorDeploy() throws Sdk.SdkException {
// 13:27:35.547 [Test worker] DEBUG tst.NeverAuctionsTests - Public: 3b6f5c626dae475183b46afec0a6fe777d2663b7872c3c674cabb9fc1f75651b
// 13:27:35.551 [Test worker] DEBUG tst.NeverAuctionsTests - Secret: 4af978eb58fde85678838d9c583a2cd9079b1f7972f374ed8fad3f692b08d6f8
// 13:27:35.625 [Test worker] DEBUG tst.NeverAuctionsTests - Future address: 0:7e9b82a46957f69c097b8c30f85eb45870826d29826193e0de5999789884f9f2

        var keys = Credentials.ofRandom(this.SDK);
        var address = Address.ofFutureDeploy(this.SDK, templates.get("elector"), 0, null, keys);
        log.debug("Future address: " + address.makeAddrStd());
    }
}
