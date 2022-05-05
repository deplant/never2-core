pragma ton -solidity >= 0.45.0;

library Errors {
    uint8 constant NO_PUB_KEY = 100;
    uint8 constant WRONG_PUB_KEY = 101;
    uint8 constant WRONG_SENDER = 102;
    uint8 constant HAS_NO_STAKE = 103;
    uint8 constant WRONG_MOMENT = 104;
    uint8 constant VALIDATOR_HAS_INCORRECT_PARAMS = 105;
    uint8 constant VALIDATOR_HAS_INCORRECT_ADDRESS = 106;
    uint8 constant NOT_REVEALING_MODE = 107;
    uint8 constant NOTHING_TO_REVEAL = 108;
    uint8 constant INCORRECT_REVEAL_DATA = 109;
    uint8 constant QUOTATION_OUTDATED = 110;
    uint8 constant ALREADY_REVEALED = 111;
    uint8 constant NOT_ELECTED = 112;
    uint8 constant SLASHED = 113;
}
