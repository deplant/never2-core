/* solhint-disable */
pragma ton-solidity >= 0.45.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../Interfaces.sol";
import "../libraries/Errors.sol";
import "Depoolable.sol";

contract NotValidator is Depoolable, INotValidator {

    // EVENTS
    event RevealPlz(uint256 hashedQuotation);
    event elected(bool result);
    event slashed();

    // STATUS
    uint128 public stakeSize;
    uint256 quotationToReveal;
    uint256 currentQuotationHash;
    uint256 currentQuotationTime;
    bool isElected;
    bool isSlashed;

    // AUTH DATA
    address public notElector;

    // ELECTION CYCLE PARAMS
    uint public validationStartTime;
    uint public validationDuration;
    address depooledParticipantIfSlashed;

    // COSTS
    uint128 constant SIGN_UP_COST = 0.6 ton;
    uint128 constant SET_QUOTATION_COST = 0.6 ton;
    uint128 constant REVEAL_QUOTATION_COST = 0.6 ton;

    // OTHER CONSTANTS
    uint constant QUOTATION_LIFETIME = 5;

    // METHODS
    constructor(
        address notElectorArg,
        uint validationStartTimeArg,
        uint validationDurationArg,
        mapping (address => bool) depoolsArg,
        address ownerArg,
        address depooledParticipantIfSlashedArg
    ) public {
        require(tvm.pubkey() != 0, Errors.NO_PUB_KEY);
        require(tvm.pubkey() == msg.pubkey(), Errors.WRONG_PUB_KEY);
        require(validationStartTimeArg > now, Errors.WRONG_MOMENT);
        tvm.accept();
        notElector = notElectorArg;
        validationStartTime = validationStartTimeArg;
        validationDuration = validationDurationArg;
        depooledParticipantIfSlashed = depooledParticipantIfSlashedArg;
        init(depoolsArg, ownerArg);
    }

    // ELECTION PHASE
    function signUp() override external CheckMsgPubkey {
        require(activeDepool != address(0), Errors.HAS_NO_STAKE);
        tvm.accept();
        INotElector(notElector).signUp{value: SIGN_UP_COST}(
            amountDeposited,
            validationStartTime,
            validationDuration
        );
    }

    function setIsElected(bool result) override external SenderIsNotElector {
        tvm.accept();

        isElected = result;
        emit elected(isElected);
    }

    // VALIDATION PHASE
    function setQuotation(
        uint256 hashedQuotation
    ) override external CheckMsgPubkey Elected NotSlashed {
        tvm.accept();
        currentQuotationHash = hashedQuotation;

        // simple spam reduction
        if (currentQuotationTime != now) {
            currentQuotationTime = now;
            INotElector(notElector).setQuotation{value: SET_QUOTATION_COST}(hashedQuotation);
        }
    }

    function requestRevealing() override external SenderIsNotElector {
        tvm.accept();
        quotationToReveal = currentQuotationHash;
        if (now <= currentQuotationTime + QUOTATION_LIFETIME) {
            emit RevealPlz(quotationToReveal);
        } else {
            INotElector(notElector).quotationIsTooOld{value: REVEAL_QUOTATION_COST}();
        }
    }

    function revealQuotation(
        uint128 oneUSDCost, uint256 salt
    ) override external CheckMsgPubkey Elected NotSlashed {
        TvmBuilder builder;
        builder.store(oneUSDCost, salt);
        require(tvm.hash(builder.toCell()) == quotationToReveal, Errors.INCORRECT_REVEAL_DATA);
        tvm.accept();
        INotElector(notElector).revealQuotation{value: REVEAL_QUOTATION_COST}(oneUSDCost);
    }

    function slash() override external SenderIsNotElector {
        tvm.accept();

        isSlashed = true;
        owner = notElector;
        depooledParticipant = depooledParticipantIfSlashed;
    }

    // MODIFIERS
    modifier Elected() {
        require(isElected, Errors.NOT_ELECTED);
        _;
    }

    modifier NotSlashed() {
        require(!isSlashed, Errors.SLASHED);
        _;
    }

    modifier CheckMsgPubkey() {
        require(msg.pubkey() == tvm.pubkey(), Errors.WRONG_PUB_KEY);
        _;
    }

    modifier SenderIsNotElector() {
        require(msg.sender == notElector, Errors.WRONG_SENDER);
        _;
        msg.sender.transfer({value: 0 ton, flag: 64});
    }

    modifier AfterValidation() {
        require(now >= validationStartTime + validationDuration, Errors.WRONG_MOMENT);
        _;
    }
}