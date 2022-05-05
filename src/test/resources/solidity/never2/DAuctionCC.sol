pragma ton-solidity >=0.58.2;

pragma AbiHeader expire;
pragma AbiHeader time;

import "./common/AbstractDAuction.sol";
import "./common/AbstractBid.sol";
import "./config/Configs.sol";

contract DAuctionCC is CCConfig, AbstractDAuction {

	// ****************************************************************	
	// Constructor
	// ****************************************************************	
    constructor(bool untilWin_) public onlyAuction {
		require(_owner.value != 0 && tvm.pubkey() == msg.pubkey(), WRONG_CONSTRUCTOR_VALUES);
    }

	// ****************************************************************	
	// Abstract Internal (Depends on Bid Implementation)
	// ****************************************************************		
	function _checkTraderBid(uint128 amount_) internal override view {
		// 0 gas check
		require(msg.currencies[CURRENCY_ID] >= amount_ + _toValue(MINT_FEE), NOT_ENOUGH_VALUE);
		// 1 amount check		
		require(amount_ >= _minTraderBid, BID_TOO_SMALL);	
	}
	
	function _sendReveal(uint128 priceReveal_, uint128 amountReveal_, uint256 salt_) internal override {
		ExtraCurrencyCollection coll;
		coll[CURRENCY_ID] = amountReveal_ + _toValue(MINT_FEE);
		AbstractBid(_bid).reveal{currencies: coll, flag: 0, bounce: true}(priceReveal_, amountReveal_, salt_);
	}
	
	function _sendAward(address trader_, uint128 amount_) internal override {
		_awardsAmount -= amount_;
		trader_.transfer({value: amount_, flag: 1, bounce: true});
	}
	
	// ****************************************************************	
	// Special
	// ****************************************************************	
	receive() external {
		if (msg.sender == _bid && _bid.value != 0) {
			TvmSlice payload = msg.data;
			if (!payload.empty()) {
			    (uint16 status, uint128 amount) = payload.decode(uint16, uint128);
				if (status == 0 && msg.currencies[CURRENCY_ID] >= amount) {
					onBadReveal(amount);
				} else if (status == 1 && msg.currencies[CURRENCY_ID] >= amount) {
					onBidRefund(amount);
				}
			}
		}
    }	

	// ****************************************************************	
	// Modifiers
	// ****************************************************************		


}




