pragma ton-solidity >=0.58.2;

pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IEVERReserve.sol";
import "./common/DeplantBase.sol";

contract EVERReserve is IEVERReserve, DeplantBase {

	// ****************************************************************
	// Init data
	// ****************************************************************	
	address static _owner;
	
	// ****************************************************************	
	// Constructor
	// ****************************************************************	
    constructor() public onlyAuction {
		require(_owner.value != 0 && tvm.pubkey() == msg.pubkey(), WRONG_CONSTRUCTOR_VALUES);
    }
	
    function mint(address to_, uint128 amount_) external internalMsg override onlyOwner {
		tvm.rawReserve(amount_, 12); // reserve = original_balance - value(amount) nanotons
		to_.transfer(0, true, ALL_BALANCE_GAS);
    }	
	
	// ****************************************************************	
	// Modifiers
	// ****************************************************************		
    modifier onlyOwner() {
        require(msg.sender == _owner, NOT_MY_OWNER);
        _;
    }		

}