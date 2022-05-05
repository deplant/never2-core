pragma ton-solidity >=0.58.2;

pragma AbiHeader expire;
pragma AbiHeader time;

import "./common/AbstractBid.sol";
import "./interfaces/IAuctionManager.sol";

contract BidEVER is AbstractBid {

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
		require(msg.value >= amount_ + _toValue(BID_REVEAL_FEE), NOT_ENOUGH_VALUE);
		// 1 sender check 
		require(msg.sender == _owner, NOT_MY_OWNER);	
		// 2 amount check		
		require(amount_ >= _rules.minBid, BID_TOO_SMALL);				
	}

	function _credit(uint128 amount_) internal override view {
		TvmCell empty;
		IAuctionManager(_rules.factory).acceptMintNEVER{value: _toValue(TRADE_CALL_FEE), flag: 1, bounce: true}(_owner, amount_, empty);
	}
	
	function _debit(uint128 amount_) internal override view {	
		uint128 reserveAmount = math.divc(amount_, 2);
		_rules.bidDest.transfer(reserveAmount, true, FEE_EXTRA); // half of amount goes to EVER Reserve
		_rules.elector.transfer(amount_ - reserveAmount, true, FEE_EXTRA); // half of amount goes to Elector to reward Validators
	}

	function _badReveal(BidData bid_) internal override view {
		_refund(bid_.amountReveal);
	}	
	
	function _refund(uint128 amount_) internal override view reserveGas {
		TvmBuilder builder;
		builder.store(_bid.status);
		builder.store(amount_);			
		TvmCell cell = builder.toCell();	
		_owner.transfer({value: 0, flag: ALL_BALANCE_GAS, bounce: true, body: cell});
	}
}