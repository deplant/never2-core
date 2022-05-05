pragma ton-solidity >=0.58.2;

pragma AbiHeader expire;
pragma AbiHeader time;

import "./common/AbstractBid.sol";
import "./config/Configs.sol";
import "./interfaces/IAuctionManager.sol";

contract BidCC is AbstractBid, CCConfig {

	// ****************************************************************	
	// Constructor
	// ****************************************************************	
	// ****************************************************************	
	// Constructor
	// ****************************************************************
    constructor(address owner_, uint256 bidHash_, AuctionRules rules_) BidBase (owner_,bidHash_,rules_) public functionID(0xB1DC) {
    }
	
	// ****************************************************************	
	// Internal Overriden Implementations
	// ****************************************************************		
	function _checkBid(uint128 amount_) internal override view {
		// 0 gas check
		//TODO IMPORTANT! We use GasToValue here for needed NEVER amount calculation
		// Still! There is no info if it will correctly calculate another CCurrency gas
		// This line should be retested after native CC NEVER will be done.
		require(msg.currencies[CURRENCY_ID] >= amount_ + _toValue(BID_REVEAL_FEE), NOT_ENOUGH_VALUE);
		// 1 sender check
		// TODO IMPORTANT! Here we think that owner will be the special multisig that is able to send CCs with CC gas, so we can make check
		require(msg.sender == _owner, NOT_MY_OWNER);		
		// 2 amount check
		require(amount_ >= _rules.minBid, BID_TOO_SMALL);		
	}

	function _credit(uint128 amount_) internal override view {
		TvmCell empty;
		IAuctionManager(_rules.factory).acceptMintEVER{value: _toValue(TRADE_CALL_FEE), flag: 1, bounce: true}(_owner, amount_, empty);
	}
	
	function _debit(uint128 amount_) internal override view {
		ExtraCurrencyCollection coll;
		coll[CURRENCY_ID] = amount_;
		_rules.bidDest.transfer({value: _toValue(TRADE_CALL_FEE), flag: 0, bounce: true, currencies: coll});
	}
	
	function _badReveal(BidData bid_) internal override view {
		_refund(bid_.amountReveal);
	}		
	
	function _refund(uint128 amount_) internal override view reserveGas {
		TvmBuilder builder;
		builder.store(_bid.status);
		builder.store(amount_);			
		TvmCell cell = builder.toCell();	
		ExtraCurrencyCollection collect;
		collect[CURRENCY_ID] = amount_;	
		_owner.transfer({value: 0, flag: ALL_BALANCE_GAS, bounce: true, currencies: collect, body: cell});	
	}	
}