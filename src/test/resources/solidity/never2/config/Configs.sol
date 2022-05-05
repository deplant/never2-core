pragma ton-solidity >=0.58.2;

import "../common/DeplantBase.sol";

abstract contract ManagerConfig is DeplantBase {
	// Default values
	uint128 constant DEFAULT_LOSER_FACTOR = 1 megaton;
	uint128 constant DEFAULT_MIN_BID = 100_000 ton;

	// Gas Fees
	uint128 constant AUCTION_START_FEE = 500_000;
	uint128 constant AUCTION_START_DEPLOY_FEE = 200_000;	
	uint128 constant MINT_FEE = 500_000;	
	uint128 constant MINT_DEPLOY_FEE = 200_000;

	// Errors
	uint16 constant NOT_MY_ELECTOR = 202;
	uint16 constant NOT_MY_GOVERNANCE = 203;
	uint16 constant NOT_MY_BID = 205;		
	uint16 constant AUCTION_CODE_EMPTY = 300;
	uint16 constant EVER_BID_CODE_EMPTY = 301;
	uint16 constant NEVER_BID_CODE_EMPTY = 302;
	uint16 constant NEVER_ROOT_EMPTY = 303;
	uint16 constant EVER_RESERVE_EMPTY = 304;
	uint16 constant ZERO_PRICE = 305;	
}

abstract contract AuctionConfig is DeplantBase {
	// Gas Fees
	uint128 constant BID_COMMIT_FEE = 700_000;
	uint128 constant BID_COMMIT_DEPLOY_FEE = 600_000;

	// Errors
	uint16 constant NOT_MY_FACTORY = 204;
	uint16 constant NOT_MY_BID = 205;	
	uint16 constant ZERO_PRICE = 305;		
	uint16 constant BID_ALREADY_SENT = 401;
	uint16 constant WRONG_PHASE = 402;	
	uint16 constant AUCTION_FAILED = 403;	
	uint16 constant PRICE_TOO_SMALL = 453;	
}

abstract contract BidConfig is DeplantBase {
	// Gas Fees
	uint128 constant BID_REVEAL_FEE = 500_000;
	uint128 constant BID_REVEAL_CALL_FEE = 200_000;	
	uint128 constant TRADE_FEE = 300_000;	
	uint128 constant TRADE_CALL_FEE = 200_000;	

	// Errors
	uint16 constant NOT_MY_AUCTION = 206;
	uint16 constant BID_TOO_SMALL = 450;
	uint16 constant NOT_REVEAL_PHASE = 451;
	uint16 constant WRONG_BID_HASH = 452;	
	uint16 constant PRICE_TOO_SMALL = 453;	
	uint16 constant BID_ALREADY_REVEALED = 454;	
	uint16 constant AUCTION_NOT_LOST = 455;
	uint16 constant NOT_TRADE_PHASE = 456;
	uint16 constant BALANCE_TOO_SMALL = 457;	
}

abstract contract CCConfig is DeplantBase {
	// ID of the NEVER Native Currency in the Currency Collection Hashmap
	// As CurrencyCollection is not implemented - this is a placeholder
	uint32 constant CURRENCY_ID = 999;
}

abstract contract TIP3Config is DeplantBase {

	// Gas Fees
	uint128 constant TIP3_DEPLOY_FEE = 300_000;
	uint128 constant TIP3_DEPLOY_BALANCE = 100_000;		
	uint128 constant TIP3_OWNER_WALLET = 100_000;			

	// Errors
	uint16 constant NOT_MY_TIP3_ROOT = 500;
	uint16 constant NOT_MY_TIP3_WALLET = 501;
	uint16 constant NOT_OWNER_TIP3_WALLET = 502;
}

abstract contract DConfig is DeplantBase {

	// Gas Fees
	uint128 constant MINT_FEE = 500_000;	
	uint128 constant MINT_DEPLOY_FEE = 200_000;	
	
	// Errors	
	uint16 constant WRONG_TOKEN_ADDRESS = 201;
	uint16 constant NOT_MY_BID = 205;	
	uint16 constant NOT_MY_AUCTION = 206;
	uint16 constant BID_TOO_SMALL = 450;	
	uint16 constant BALANCE_TOO_SMALL = 457;
	

}