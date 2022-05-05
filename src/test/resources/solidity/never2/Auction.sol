pragma ton-solidity >=0.58.2;

pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IAuction.sol";
import "./config/Configs.sol";
import "./common/AuctionBase.sol";
import "./common/AbstractBid.sol";
import "./BidCC.sol";

contract Auction is IAuction, AuctionConfig, AuctionBase {

	// ****************************************************************
	// Init data
	// ****************************************************************	
	address static _factory;
	TvmCell static _bidCode;
	uint64  static _tx;

	// ****************************************************************	
    // Events
	// ****************************************************************		
    event bidPlaced(address participant);
    event bidRevealed(address participant, uint128 amount);
    event auctionRevealStarted(uint128 quotingPrice);	
    event auctionFailed();
    event auctionSucceded(address participant, uint128 price, uint128 amount);
	
	//TODO Remove public
	uint64 public _bidCount;
	uint64 public _revealCount;	
	BidData _1stBid;  // auction winner
	BidData _2ndBid; // contains price that will be paid

	// ****************************************************************	
	// Constructor
	// ****************************************************************
    constructor(AuctionRules rules_) public onlyFactory {
		_rules = rules_;
    }
	
	// ****************************************************************	
	// Getters
	// ****************************************************************	
	function getMinimumValue() external view 
	 returns (uint128 requiredValue) {
		return _rules.minBid + _toValue(BID_COMMIT_FEE);
	}
	
	function getBidAddress(address bidder_) external view override 
	 returns (address bidAddress) {
		(address bidAddr, ) = _bidInit(bidder_);
		return bidAddr;
	}
	
	function getCommitHash(uint128 priceReveal_, uint128 amountReveal_, uint256 salt_) external pure override returns (uint256 bidHash) {
		return _revealHash(priceReveal_, amountReveal_, salt_);
	}
	
	function getWinner() external view override returns (address winner, uint128 winningPrice) {
		return (_1stBid.owner, _2ndBid.priceReveal);
	}	

	// ****************************************************************	
	// External
	// ****************************************************************
	// bidHash_ includes hashed info on (price + amount + salt)
    function commit(uint256 bidHash_) external internalMsg override responsible reserveGas returns (address)  {
		require(msg.value >= _toValue(BID_COMMIT_FEE), NOT_ENOUGH_VALUE);
		(address bidAddress, TvmCell bidInit) = _bidInit(msg.sender);	
		// !!!!!
		// despite using BidCC constructor to encode body, Auction here DO NOT RELY on real bid implementation
		// all Bid variants have the same constructor params and same functionID
		TvmCell payload = tvm.encodeBody(BidCC, msg.sender, bidHash_, _rules);
		_bidCount++;
		emit bidPlaced(msg.sender);
		bidAddress.transfer({value: _toValue(BID_COMMIT_DEPLOY_FEE), flag: 1, bounce: false, body: payload, stateInit: bidInit});
		return {value: 0, flag: 128}bidAddress;
    }
	
    function destroy() external internalMsg override onlyFactory {
		msg.sender.transfer(0, true, ALL_BALANCE_GAS + SELF_DESTROY);
    }	
	
    function startReveal(uint128 quotingPrice_) external internalMsg override onlyFactory {
		require(quotingPrice_ > 0, ZERO_PRICE);
		_rules.phase = AUCTION_PHASE_REVEAL;
		_rules.minPrice = quotingPrice_;
		emit auctionRevealStarted(quotingPrice_);
    }		
	
    function startTrade() external internalMsg override onlyFactory {
		if (_revealCount == 0) {
		emit auctionFailed();
		} else {
			(address bidAddress, ) = _bidInit(_1stBid.owner); // take best bid
			emit auctionSucceded(_1stBid.owner, _2ndBid.priceReveal, _1stBid.amountReveal);	
			AbstractBid(bidAddress).onTradeRequest(BID_RESULT_WON, _2ndBid.priceReveal, _1stBid.amountReveal);
		}
    }		
	
	function acceptReveal(BidData bid_) external internalMsg responsible override
	 reserveGas 
	 onlyBid(bid_.owner)
	 returns (BidData) {
		// we put if here (not require), so Auction sends correct response
		// and Bid knows that reveal failed
		if (bid_.priceReveal >= _rules.minPrice && _rules.phase == AUCTION_PHASE_REVEAL) {
			if (bid_.priceReveal > 0 && _1stBid.priceReveal == 0) {
				// first participant
				// set both places
				_1stBid = bid_;
				_2ndBid = bid_;		
			} else if (bid_.priceReveal > _1stBid.priceReveal) {
				// 1st place moves to 2nd place
				_2ndBid = _1stBid;
				// 1st place is updated with new winner
				_1stBid = bid_;
			} else if (bid_.priceReveal > _2ndBid.priceReveal) {
				// 2nd place is updated with new participant
				_2ndBid = bid_;
			}
			_revealCount++; // increment number of revealed bids;

			// check if we already won (or lose) the auction
			if (_revealCount == _bidCount && _bidCount > 0) {
				if (bid_.owner == _1stBid.owner) {
					bid_.winStatus = BID_RESULT_WON;
				} else {
					bid_.winStatus = BID_RESULT_LOSE;	
				}
			}  else {
				bid_.winStatus = BID_RESULT_UNDECIDED;
			}
			bid_.status = BID_REVEALED;
			bid_.amountLeft = bid_.amountReveal;
			emit bidRevealed(bid_.owner, bid_.amountReveal);
		}
		return{value: 0, flag: 128}bid_;
	} 

	function acceptLoserTrade(BidData bid_, uint128 amount_) external internalMsg responsible override
	 reserveGas 
	 returnChange 
	 returns (uint16 winStatus, uint128 price, uint128 amount) {
		(address bidAddress, ) = _bidInit(bid_.owner);
        require(msg.sender == bidAddress, NOT_MY_BID);	 
		require(_rules.phase == AUCTION_PHASE_TRADE, WRONG_PHASE);
		require(_revealCount > 0, AUCTION_FAILED);	
		uint128 loserPrice = math.divc(_2ndBid.priceReveal,_rules.loserFactor);
		return (BID_RESULT_LOSE, loserPrice, amount_);
	}
	
	// ****************************************************************	
	// Internal
	// ****************************************************************	
    function _bidInit(address owner_) private view 
	 returns (address, TvmCell) {
        TvmCell stateInit = tvm.buildStateInit({
            contr: BidBase,
            varInit: {
				_auction:	address(this),
                _owner:     owner_
            },
            code: _bidCode
        });

        return (address(tvm.hash(stateInit)), stateInit);
    }	
	
	//function mint() 

	
/*     onBounce(TvmSlice slice) external pure
    {
		uint32 func = slice.decode(uint32);
		if(func == tvm.functionId(revealBid)) 
        {
            // Return gas to sender?? 
        }
    } */	
	
	// Trade price for participants (increased by factor of ?)
	//function tradePrice(uint128 winningPrice) internal inline returns (uint128) {
	//	// winningPrice * 1.03 // ????????????
	//}
	
	// ****************************************************************	
	// Modifiers
	// ****************************************************************		

    modifier onlyFactory() {
        require(msg.sender == _factory, NOT_MY_FACTORY);
        _;
    }
	
    modifier onlyBid(address bidder) {
		(address bidAddress, ) = _bidInit(bidder);
        require(msg.sender == bidAddress, NOT_MY_BID);
        _;
    }	

}