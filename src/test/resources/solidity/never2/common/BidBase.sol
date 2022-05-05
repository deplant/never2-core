pragma ton-solidity >=0.58.2;

pragma AbiHeader expire;
pragma AbiHeader time;

import "./AuctionBase.sol";
import "./DeplantBase.sol";
import "../config/Configs.sol";
import "./BidBase.sol";

contract BidBase is BidConfig, AuctionBase {


	// ****************************************************************
	// Init data
	// ****************************************************************	
	address static _auction;
	address static _owner;

	// ****************************************************************	
	// State Vars
	// ****************************************************************
	BidData public _bid;
	
	// ****************************************************************	
	// Constructor
	// ****************************************************************	
    constructor(address owner_, uint256 bidHash_, AuctionRules rules_) public onlyAuction {
		require(owner_ == _owner, WRONG_CONSTRUCTOR_VALUES);
		_bid.owner = _owner;
		_bid.bidHash = bidHash_;
		_rules = rules_;
    }
	
	// ****************************************************************	
	// Modifiers
	// ****************************************************************		
    modifier onlyAuction() {
        require(msg.sender == _auction && _auction.value != 0, NOT_MY_AUCTION);
        _;
    }		
	
    modifier onlyOwner() {
        require(msg.sender == _owner && _owner.value != 0, NOT_MY_AUCTION);
        _;
    }		

}