pragma ton-solidity >=0.58.2;

pragma AbiHeader expire;
pragma AbiHeader time;

import "./common/AbstractDAuction.sol";
import "./common/AbstractBid.sol";
import "./interfaces/ITokenWallet.sol";
import "./config/Configs.sol";

contract DAuctionTIP3 is TIP3Config, AbstractDAuction {

	// ****************************************************************	
	// State Vars
	// ****************************************************************
	address _dauctionTip3Wallet; // filled via contructor/callback by calling tip3root of NEVER
	address _bidTip3Wallet; // filled via contructor/callback by calling tip3root of NEVER	

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
		require(msg.value > _toValue(MINT_FEE), NOT_ENOUGH_VALUE);			
		// 1 sender check (we can only trust our TIP3 wallet)
		require(msg.sender == _dauctionTip3Wallet && _dauctionTip3Wallet != ADDRESS_ZERO, NOT_MY_TIP3_WALLET);
		// 2 amount check (this amount came from TIP3, so we can trust it)
		require(amount_ >= _minTraderBid, BID_TOO_SMALL);		
	}
	
	function _sendReveal(uint128 priceReveal_, uint128 amountReveal_, uint256 salt_) internal override {
		TvmBuilder builder;
		builder.store(priceReveal_);
		builder.store(amountReveal_);			
		builder.store(salt_);
		TvmCell cell = builder.toCell();			
		ITokenWallet(_dauctionTip3Wallet).transfer{value: 0, flag: ALL_MESSAGE_GAS, bounce: true}(
			amountReveal_,
			_bid,
			_toValue(MINT_DEPLOY_FEE),
			_owner,
			true,
			cell
		);
	}
	
	function _sendAward(address trader_, uint128 amount_) internal override {
		_awardsAmount -= amount_;	
		trader_.transfer({value: amount_, flag: 1, bounce: true});
	}	
	
	// ****************************************************************	
	// Special
	// ****************************************************************	
    function onAcceptTokensTransfer(
        address /*tokenRoot*/,
        uint128 amount,
        address sender,
        address senderWallet,
        address /*remainingGasTo*/,
        TvmCell payload
    ) external reserveGas sendChangeTo(_owner) {
	
		if (msg.sender == _dauctionTip3Wallet) {
			if (senderWallet == _bidTip3Wallet && _bidTip3Wallet != ADDRESS_ZERO) {
			TvmCell empty;
				if (payload != empty) {
					(uint16 status, uint128 decodedAmount) = payload.toSlice().decode(uint16, uint128);
					if (status == 0) {
						onBadReveal(decodedAmount);
					} else if (status == 1) {
						onBidRefund(decodedAmount);
					}
				}
			} else {
				placeTraderBid(amount, payload);
			}
		}
	}		

	// ****************************************************************	
	// Modifiers
	// ****************************************************************		


}




