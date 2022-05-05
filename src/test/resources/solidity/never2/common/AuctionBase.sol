pragma ton-solidity >=0.58.2;

abstract contract AuctionBase {

	uint16 constant AUCTION_PHASE_COMMIT = 0;
	uint16 constant AUCTION_PHASE_REVEAL = 1;	
	uint16 constant AUCTION_PHASE_TRADE = 2;		

	uint16 constant BID_COMMITED = 0;
	uint16 constant BID_REVEALED = 1;
	
	uint16 constant BID_RESULT_UNDECIDED = 0;
	uint16 constant BID_RESULT_WON = 1;	
	uint16 constant BID_RESULT_LOSE = 2;	
	

	struct AuctionRules {
		address elector;	
		address factory;
		uint16 phase;
		address bidDest;
		address prizeSource;
		uint64 startDate;
		uint128 minBid;
		uint128 minPrice;
		uint128 loserFactor;
	}
	
	struct BidData {
		address owner;
		uint16 status;
		uint16 winStatus;		
		uint256 bidHash;		
		uint256 salt;
		uint128 priceReveal;
		uint128 amountReveal;
		uint128 priceFinal;
		uint128 amountLeft;
	}	

	// ****************************************************************	
	// State Vars
	// ****************************************************************
	AuctionRules public _rules;
	
	// ****************************************************************	
	// Internal
	// ****************************************************************		
	function _revealHash(uint128 priceReveal_, uint128 amountReveal_, uint256 salt_) internal pure inline returns (uint256) {
		TvmBuilder builder;
		builder.store(priceReveal_);
		builder.store(amountReveal_);			
		builder.store(salt_);
		TvmCell cell = builder.toCell();		
		return tvm.hash(cell);
	}		
}