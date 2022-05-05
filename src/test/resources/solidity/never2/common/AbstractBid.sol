pragma ton-solidity >=0.58.2;

pragma AbiHeader expire;
pragma AbiHeader time;

import "../interfaces/IAuction.sol";
import "./BidBase.sol";

abstract contract AbstractBid is BidBase {

	// ****************************************************************	
	// External
	// ****************************************************************			
    function reveal(uint128 priceReveal_, uint128 amountReveal_, uint256 salt_) public view {
		require(_bid.status == BID_COMMITED,
				BID_ALREADY_REVEALED); // if Bid already revealed, fail		
		_checkBid(amountReveal_);	// this check has different implementations in EVER, TIP3-NEVER and CC-NEVER
		require(_bid.bidHash == _revealHash(priceReveal_, amountReveal_, salt_), WRONG_BID_HASH);
		BidData bid = _bid;
		bid.salt = salt_;
		bid.priceReveal = priceReveal_;
		bid.amountReveal = amountReveal_;
		IAuction(_auction).acceptReveal{value: _toValue(BID_REVEAL_CALL_FEE), flag: 1, bounce: true, callback: AbstractBid.onRevealAccepted}(bid);
    }		
		
    function onRevealAccepted(BidData bid_) external internalMsg onlyAuction reserveGas sendChangeTo(_owner) {
		require(bid_.owner == _owner, WRONG_BID_HASH);	
		require(bid_.bidHash == _bid.bidHash, WRONG_BID_HASH);		
		_bid = bid_;
		if (!(_bid.status == BID_REVEALED)) {
			// if bid didn't pass price check and isn't revealed, we return funds to owner
			_badReveal(bid_); 
		}
	}
	
    function onTradeRequest(uint16 winStatus_, uint128 price_, uint128 amount_) external internalMsg onlyAuction reserveGas sendChangeTo(_owner) {
		_bid.winStatus = winStatus_;
		_bid.priceFinal = price_;
		_trade(price_, amount_);			
	}
	
    function loserTrade(uint128 amount_) external internalMsg onlyOwner reserveGas returnChange {
		require(msg.value >= _toValue(TRADE_FEE), NOT_ENOUGH_VALUE);
		require(_bid.status == BID_REVEALED && _bid.winStatus != BID_RESULT_WON, AUCTION_NOT_LOST);
		require(_bid.amountLeft >= amount_, BALANCE_TOO_SMALL);
		if (_bid.priceFinal == 0 || _bid.winStatus == 0) {
			IAuction(_auction).acceptLoserTrade{value: _toValue(TRADE_CALL_FEE), flag: 1, bounce: true, callback: AbstractBid.onTradeRequest}(_bid, amount_);
		} else {
			_trade(_bid.priceFinal, amount_);
		}
	}
	
    function loserUnlock() view external internalMsg onlyOwner reserveGas returnChange {
		require(_bid.status == BID_REVEALED && _bid.winStatus == BID_RESULT_LOSE, AUCTION_NOT_LOST);	
		if (_bid.amountLeft > 0) {
			_refund(_bid.amountLeft);
		}
	}

	// ****************************************************************	
	// Internal
	// ****************************************************************	
	function _trade(uint128 price_, uint128 amount_) internal returns (uint256) {
		_debit(amount_); // send funds to Fund & Validators (should be virtual)
		_bid.amountLeft = _bid.amountLeft -= amount_;
		_credit(
			_exchange(
				amount_, 
				_reversePrice(price_)
			)
		);
	}

	// ****************************************************************	
	// Abstract Internal (Depends on Bid Implementation)
	// ****************************************************************		
	function _checkBid(uint128 amount_) internal view virtual;
	function _credit(uint128 amount_) internal view virtual;
	function _debit(uint128 amount_) internal view virtual;	
	function _refund(uint128 amount_) internal view virtual;		
	function _badReveal(BidData bid_) internal view virtual;

}