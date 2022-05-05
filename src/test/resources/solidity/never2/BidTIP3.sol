pragma ton-solidity >=0.58.2;

pragma AbiHeader expire;
pragma AbiHeader time;


import "./interfaces/ITokenRoot.sol";
import "./interfaces/ITokenWallet.sol";
import "./interfaces/IAcceptTokensTransferCallback.sol";
import "./interfaces/IAuctionManager.sol";
import "./common/AbstractBid.sol";
import "./config/Configs.sol";

contract BidTIP3 is AbstractBid, TIP3Config, IAcceptTokensTransferCallback {

	// ****************************************************************	
	// State Vars
	// ****************************************************************
	address _ownerTip3Wallet; // filled via contructor/callback by calling tip3root of NEVER
	address _bidTip3Wallet; // filled via contructor/callback by calling tip3root of NEVER	

	// ****************************************************************	
	// Constructor
	// ****************************************************************
    constructor(address owner_, uint256 bidHash_, AuctionRules rules_) BidBase (owner_,bidHash_,rules_) public functionID(0xB1DC) {
		ITokenRoot(_rules.bidDest).deployWallet{value: _toValue(TIP3_DEPLOY_FEE), callback: BidTIP3.onTip3RootDeployed, flag: 0, bounce: true}(address(this), _toValue(TIP3_DEPLOY_BALANCE));
		ITokenRoot(_rules.bidDest).walletOf{value: _toValue(TIP3_OWNER_WALLET), callback: BidTIP3.onTip3RootWalletInfo, flag: 0, bounce: true}(msg.sender);
    }

	// ****************************************************************	
	// External
	// ****************************************************************		
    function onAcceptTokensTransfer(
        address /*tokenRoot*/,
        uint128 amount,
        address sender,
        address senderWallet,
        address /*remainingGasTo*/,
        TvmCell payload
    ) external override reserveGas sendChangeTo(_owner) {
		require(senderWallet == _ownerTip3Wallet && _ownerTip3Wallet != ADDRESS_ZERO, NOT_OWNER_TIP3_WALLET);
		require(sender == _owner, NOT_OWNER_TIP3_WALLET);
	
		(uint128 price, uint128 salt) = abi.decode(payload, (uint128, uint128)); // decode payload	
		reveal(price, amount,salt);
	}	
	
	// Callback that returns after creating wallet for a Bid
	function onTip3RootDeployed(address bidWallet_) external reserveGas sendChangeTo(_owner) onlyTIP3Root {
		_bidTip3Wallet = bidWallet_;
	}
	
	// Callback that returns after checking address of bidder's TIP3 Wallet
	function onTip3RootWalletInfo(address ownerWallet_) external reserveGas sendChangeTo(_owner) onlyTIP3Root {
		_ownerTip3Wallet = ownerWallet_;
	}	

	// ****************************************************************	
	// Internal Overriden Implementations
	// ****************************************************************		
	function _checkBid(uint128 amount_) internal override view {
		// 0 gas check
		require(msg.value > _toValue(BID_REVEAL_FEE), NOT_ENOUGH_VALUE);			
		// 1 sender check (we can only trust our TIP3 wallet)
		require(msg.sender == _bidTip3Wallet && _bidTip3Wallet != ADDRESS_ZERO, NOT_MY_TIP3_WALLET);
		// 2 amount check (this amount came from TIP3, so we can trust it)
		require(amount_ >= _rules.minBid, BID_TOO_SMALL);				
	}	

	function _credit(uint128 amount_) internal override view {
		TvmCell empty;
		IAuctionManager(_rules.factory).acceptMintEVER{value: _toValue(TRADE_CALL_FEE), flag: 1, bounce: true}(_owner, amount_, empty);
	}
	
	function _debit(uint128 amount_) internal override view {
		TvmCell empty;
		IAuctionManager(_rules.factory).acceptBurnNEVER{value: _toValue(TRADE_CALL_FEE), flag: 1, bounce: true}(_owner, amount_, empty);		
	}
	
	function _badReveal(BidData bid_) internal override view {
		_refund(bid_.amountReveal);	
	}		
	
	function _refund(uint128 amount_) internal override view reserveGas {
		TvmBuilder builder;
		builder.store(_bid.status);
		builder.store(amount_);			
		TvmCell cell = builder.toCell();
		ITokenWallet(_bidTip3Wallet).transfer{value: 0, flag: ALL_BALANCE_GAS, bounce: true}(
			amount_,
			_owner,
			_toValue(TRADE_CALL_FEE),
			_owner,
			true,
			cell
		);
	}	
	
	// ****************************************************************	
	// Modifiers
	// ****************************************************************	
	modifier onlyTIP3Root() {
		require(msg.sender == _rules.bidDest, NOT_MY_TIP3_ROOT);
        _;
    }	

}