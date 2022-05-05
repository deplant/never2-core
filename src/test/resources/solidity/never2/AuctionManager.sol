pragma ton-solidity >=0.58.2;

pragma AbiHeader expire;
pragma AbiHeader time;

import "./config/Configs.sol";
import "./Auction.sol";
import "./common/BidBase.sol";
import "./interfaces/ITokenRoot.sol";
import "./interfaces/IBurnableByRootTokenRoot.sol";
import "./interfaces/IEVERReserve.sol";
import "./interfaces/IAuctionManager.sol";

contract AuctionManager is IAuctionManager, ManagerConfig {
	
	// ****************************************************************	
    // Events
	// ****************************************************************		
    event auctionStarted(address auction, uint64 time, bool isBuyNEVER);
	
	// ****************************************************************	
	// State Vars
	// ****************************************************************	
	address public _governance;
	address public _elector;	
	address public _neverRoot; // contract that can mint NEVER (TIP-3 or CC)
	address public _everReserve; // contract of EVER Reserve Fund
	
	TvmCell public _auctionCode;
	TvmCell public _everBidCode;
	TvmCell public _neverBidCode;	

	uint128 public _loserFactor = DEFAULT_LOSER_FACTOR;
	uint128 public _minBid = DEFAULT_MIN_BID;
	address public _currentBuyNEVERAuction;	
	address public _currentBuyEVERAuction;	
	uint32 _nonce = 95;

	// ****************************************************************	
	// Constructor
	// ****************************************************************	
	
    constructor() public {
        require(msg.pubkey() == tvm.pubkey(), NOT_MY_GOVERNANCE);			
		tvm.accept();
    }
	
	// ****************************************************************	
	// Getters
	// ****************************************************************		
	
	// ****************************************************************	
	// External
	// ****************************************************************		
	
	function startAuctions(uint64 dtStart_) external internalMsg override onlyElector reserveGas returnChange {
		require(msg.value > _toValue(AUCTION_START_FEE), NOT_ENOUGH_VALUE);
		require(!_auctionCode.toSlice().empty(), AUCTION_CODE_EMPTY);
		require(!_everBidCode.toSlice().empty(), EVER_BID_CODE_EMPTY);
		require(!_neverBidCode.toSlice().empty(), NEVER_BID_CODE_EMPTY);
		require(_everReserve.value != 0, EVER_RESERVE_EMPTY);		
		require(_neverRoot.value != 0, NEVER_ROOT_EMPTY);				
		

		// removal of old auction is needed
		// because we should end trade on old prices
		if (_currentBuyNEVERAuction != ADDRESS_ZERO) {
			IAuction(_currentBuyNEVERAuction).destroy();
		}
		if (_currentBuyEVERAuction != ADDRESS_ZERO) {
			IAuction(_currentBuyEVERAuction).destroy();
		}		
	
		// EVER -> NEVER Auction
		_currentBuyNEVERAuction = _deployAuction(dtStart_, true);
		emit auctionStarted(_currentBuyNEVERAuction, dtStart_, true);	
		// NEVER -> EVER Auction		
		_currentBuyEVERAuction = _deployAuction(dtStart_, false);
		emit auctionStarted(_currentBuyEVERAuction, dtStart_, false);			
	}
	
	function revealAuctions(uint128 minPrice_)view external internalMsg override onlyElector reserveGas returnChange {
		require(msg.value > _toValue(AUCTION_START_FEE), NOT_ENOUGH_VALUE);	
		require(minPrice_ > 0, ZERO_PRICE);	
		IAuction(_currentBuyNEVERAuction).startReveal{value: _toValue(AUCTION_START_DEPLOY_FEE), flag: 1}(minPrice_);
		IAuction(_currentBuyEVERAuction).startReveal{value: _toValue(AUCTION_START_DEPLOY_FEE), flag: 1}(_reversePrice(minPrice_));		
	}
	
	function tradeAuctions() view external internalMsg override  onlyElector reserveGas returnChange {
		IAuction(_currentBuyNEVERAuction).startTrade{value: _toValue(AUCTION_START_DEPLOY_FEE), flag: 1}();
		IAuction(_currentBuyEVERAuction).startTrade{value: _toValue(AUCTION_START_DEPLOY_FEE), flag: 1}();
	}	
	
	function setNEVERRoot(address neverRoot_) external override onlyGovernance {
		_neverRoot = neverRoot_;
	}		
	
	function setEVERReserve(address everReserve_) external override onlyGovernance {
		_everReserve = everReserve_;
	}		
	
	function setAuctionCode(TvmCell code_) external override onlyGovernance {
		_auctionCode = code_;
	}	
	
	function setEVERBidCode(TvmCell code_) external override onlyGovernance {
		_everBidCode = code_;
	}	
	
	function setNEVERBidCode(TvmCell code_) external override onlyGovernance {
		_neverBidCode = code_;
	}		
	
	function setMinBid(uint128 minBid_) external override onlyGovernance {
		_minBid = minBid_;
	}		

	function setLoserFactor(uint128 loserFactor_) external override onlyGovernance {
		_loserFactor = loserFactor_;
	}	

	function setGovernance(address governance_) external override onlyGovernance {
		_governance = governance_;
	}		
	
	function setElector(address elector_) external override onlyGovernance {
		_elector = elector_;
	}			
	
    function acceptMintEVER(address owner_, uint128 amount_, TvmCell /*payload_*/) view external internalMsg override onlyEVERBid(owner_)
    {
        IEVERReserve(_everReserve).mint{value: _toValue(MINT_FEE), flag: 0, bounce: true}(
			owner_,
			amount_
		);
    }

    function acceptMintNEVER(address owner_, uint128 amount_, TvmCell payload_) view external internalMsg override onlyNEVERBid(owner_)
    {
		// Both TIP3 and CC NEVER Roots support ITokenRoot interface
        ITokenRoot(_neverRoot).mint{value: _toValue(MINT_FEE), flag: 0, bounce: true}(
		    amount_,
			owner_,
			_toValue(MINT_DEPLOY_FEE), // deploy wallet as we can't be sure that wallet is present
			owner_,
			true,
			payload_
		);
    }	
	
    function acceptBurnNEVER(address owner_, uint128 amount_, TvmCell payload_) view external internalMsg override onlyNEVERBid(owner_)
    {
        IBurnableByRootTokenRoot(_neverRoot).burnTokens{value: _toValue(MINT_FEE), flag: 0, bounce: true}(
			amount_,
			owner_,
			owner_,
			ADDRESS_ZERO,
			payload_
		);
    }		

	// ****************************************************************	
	// Internal
	// ****************************************************************		
	function _deployAuction(uint64 dtStart_, bool isBuyNEVER_) private view returns (address)  {
		(address newAuction, TvmCell stateInit) = _auctionInit(dtStart_, isBuyNEVER_);
		AuctionBase.AuctionRules rules = AuctionBase.AuctionRules(
			{
				elector: _elector,
				factory: address(this),
				phase: 0,
				bidDest: isBuyNEVER_ ? _everReserve : _neverRoot,
				prizeSource: isBuyNEVER_ ? _neverRoot : _everReserve,
				startDate: dtStart_, 
				minBid: _minBid,
				minPrice: 0,
				loserFactor: _loserFactor
			}
		);
		new Auction{value: _toValue(AUCTION_START_DEPLOY_FEE), flag: 1, wid: address(this).wid, stateInit: stateInit, bounce: false}(rules);
		return newAuction;
	}
	
    function _auctionInit(uint64 dtStart_, bool isBuyNEVER_) private view returns (address, TvmCell)
    {
        TvmCell stateInit = tvm.buildStateInit({
            contr: Auction,
            varInit: {
				_factory:		address(this),
                _bidCode:      isBuyNEVER_ ? _everBidCode : _neverBidCode,
                _tx:       	   dtStart_
            },
            code: _auctionCode
        });

        return (address(tvm.hash(stateInit)), stateInit);
    }
	
    function _bidInit(address auction_, TvmCell code_, address owner_) private pure 
	 returns (address, TvmCell) {
        TvmCell stateInit = tvm.buildStateInit({
            contr: BidBase,
            varInit: {
				_auction:	auction_,
                _owner:     owner_
            },
            code: code_
        });

        return (address(tvm.hash(stateInit)), stateInit);
    }	
		
	
	// ****************************************************************	
	// Modifiers
	// ****************************************************************		
	
    modifier onlyElector() {
        require(msg.sender == _elector, NOT_MY_ELECTOR);
        _;
    }	

	// Functions with this modifier are governed via owner's public key until _governance state var is set
	// After setting _governance var, only calls from _governance are accepted
    modifier onlyGovernance() {
		if (msg.pubkey() == tvm.pubkey() && _governance == ADDRESS_ZERO) {
			tvm.accept();
		} else if (msg.sender == _governance && _governance != ADDRESS_ZERO) {
			_reserve();
		} else {
			revert(NOT_MY_GOVERNANCE);
		}
        _;
		if (msg.sender == _governance && _governance != ADDRESS_ZERO) {
			_sendChange(msg.sender);
		}
    }

    modifier onlyEVERBid(address bidder) {
		(address bidAddress, ) = _bidInit(_currentBuyNEVERAuction, _everBidCode, bidder);
        require(msg.sender == bidAddress, NOT_MY_BID);
        _;
    }	

    modifier onlyNEVERBid(address bidder) {
		(address bidAddress, ) = _bidInit(_currentBuyEVERAuction, _neverBidCode, bidder);
        require(msg.sender == bidAddress, NOT_MY_BID);
        _;
    }	

}