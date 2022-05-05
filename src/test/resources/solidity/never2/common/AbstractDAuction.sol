pragma ton-solidity >=0.58.2;

pragma AbiHeader expire;
pragma AbiHeader time;

import "../config/Configs.sol";
import "../interfaces/IBurnableByRootTokenRoot.sol";
import "../interfaces/ITokenRoot.sol";
import "../interfaces/IAuction.sol";

abstract contract AbstractDAuction is DConfig {

	// ****************************************************************
	// Init data
	// ****************************************************************	
	address static _owner;
	
	// ****************************************************************	
	// State Vars
	// ****************************************************************	
	address public _tokenRoot;
	
	address public _auction; // current Auction
	address public _bid; // current Bid
	uint128 _minTraderBid = 1 ton; // Dauction Min Bid
	uint128 _minAuctionBid = 10 ton;
	uint128 _totalAmount;
	uint128 _awardsAmount;	
	
	// ****************************************************************	
    // Events
	// ****************************************************************		
    event revealFailed();
	
	// ****************************************************************	
	// External
	// ****************************************************************	
	function signUpToAuction(address auction_) external onlyOwner {
		require(auction_.value != 0, 601);
		_auction = auction_;
	}
	
	function endAuction() external onlyOwner {
		_auction = ADDRESS_ZERO;
		_bid = ADDRESS_ZERO;
	}	
	
	function setTokenRoot(address tokenRoot_) external onlyOwner {
		_tokenRoot = tokenRoot_;
	}	
	
	function setMinTraderBid(uint128 minBid_) external onlyOwner {
		require(minBid_ >= 1 milli, 602);	
		_minTraderBid = minBid_;
	}	
		
	function setMinAuctionBid(uint128 minBid_) external onlyOwner {
		require(minBid_ >= 1 ton, 603);	
		_minAuctionBid = minBid_;
	}			
	
	// Step 1-2
    function placeTraderBid(uint128 amount_, TvmCell payload_) public internalMsg {
		require(_tokenRoot.value != 0);
		_checkTraderBid(amount_);
		_totalAmount += amount_;
        ITokenRoot(_tokenRoot).mint{value: _toValue(MINT_FEE), flag: 0, bounce: true}(
		    amount_,
			msg.sender,
			_toValue(MINT_DEPLOY_FEE), // deploy wallet as we can't be sure that wallet is present
			msg.sender,
			true,
			payload_
		);
		
    }	
	
	// Step 3.1
    function placeCumulativeBid(uint256 commitHash_) external internalMsg reserveGas onlyOwner 
	 {
		require(_tokenRoot.value != 0, WRONG_TOKEN_ADDRESS);
		require(_auction.value != 0, NOT_MY_AUCTION);
		require(msg.value >= _toValue(MINT_FEE), NOT_ENOUGH_VALUE);		
		IAuction(_auction).commit{value: 0, flag: ALL_MESSAGE_GAS, bounce: true, callback: AbstractDAuction.onBidPlaced}(commitHash_);
    }		

	// Step 3.1.callback	
	function onBidPlaced(address bidAddress_) external internalMsg onlyAuction reserveGas sendChangeTo(_owner) {
		_bid = bidAddress_;
	}	
	
	// Step 3.2
    function placeCumulativeReveal(uint128 priceReveal_, uint128 amountReveal_, uint256 salt_) external internalMsg reserveGas onlyOwner
	 {
		require(_tokenRoot.value != 0, WRONG_TOKEN_ADDRESS);
		require(_auction.value != 0, NOT_MY_AUCTION);
		require(amountReveal_ <= _totalAmount, BALANCE_TOO_SMALL);
		require(amountReveal_ >= _minAuctionBid, BALANCE_TOO_SMALL);		
		_totalAmount -= amountReveal_;
		_sendReveal(priceReveal_, amountReveal_, salt_);
    }		
	
	// Step 3.3
	function onBadReveal(uint128 amount_) public {
		_totalAmount += amount_;	
		emit revealFailed();
	}
	
	// Step 4.1
	function onPrizeReceive(uint128 amount_) public {
		_awardsAmount += amount_;
	}
	
	// Step 4.2
	function onBidRefund(uint128 amount_) public {
		_totalAmount += amount_;		
	}
	
	/*IAcceptTokensBurnCallback(callbackTo).onAcceptTokensBurn{
		value: 0,
		flag: TokenMsgFlag.ALL_NOT_RESERVED + TokenMsgFlag.IGNORE_ERRORS,
		bounce: false
	}(
		amount,
		walletOwner,
		msg.sender,
		remainingGasTo,
		payload
	);*/
	
	// Step 5
    function collectAwards(uint128 amount_) external internalMsg {
		require(_tokenRoot.value != 0);
		TvmCell empty;
		require(amount_ <= _totalAmount, BALANCE_TOO_SMALL);
        IBurnableByRootTokenRoot(_tokenRoot).burnTokens{value: _toValue(MINT_FEE), flag: 0, bounce: true}(
			amount_,
			msg.sender,
			msg.sender,
			address(this),
			empty
		);
    }	

	function onAcceptTokensBurn(
								uint128 amount,
								address walletOwner,
								address sender,
								address remainingGasTo,
								TvmCell payload
								) external internalMsg {
		require(msg.sender == _tokenRoot, WRONG_TOKEN_ADDRESS);
		_totalAmount -= amount;
		_sendAward(walletOwner, amount);
	}

	// ****************************************************************	
	// Internal
	// ****************************************************************	

	// ****************************************************************	
	// Abstract Internal (Depends on Bid Implementation)
	// ****************************************************************		
	// TIP3 variant checks that request was made from DAuction own wallet
	// EVER checks value
	// CC checks currencies
	function _checkTraderBid(uint128 amount_) view internal virtual;
	function _sendReveal(uint128 priceReveal_, uint128 amountReveal_, uint256 salt_) internal virtual;	
	function _sendAward(address trader_, uint128 amount_) internal virtual;		

	// ****************************************************************	
	// Modifiers
	// ****************************************************************		
    modifier onlyOwner() {
        require(msg.sender == _owner && _owner.value != 0, NOT_MY_OWNER);
        _;
    }		
	
    modifier onlyAuction() {
        require(msg.sender == _auction && _auction.value != 0, NOT_MY_AUCTION);
        _;
    }		
	
    modifier onlyBid() {
        require(msg.sender == _bid && _bid.value != 0, NOT_MY_BID);
        _;
    }		

}




