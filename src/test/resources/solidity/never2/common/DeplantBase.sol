pragma ton-solidity >=0.58.2;

pragma AbiHeader expire;
pragma AbiHeader time;

contract DeplantBase {

	// ****************************************************************	
	// Contants
	// ****************************************************************		
	address constant ADDRESS_ZERO = address.makeAddrStd(0, 0);
	uint128 constant GAS_FLOOR = 500_000; // IMPORTANT! this is Gas amount, not EVER amount!!! Amount of minimum gas to reserve on balance at all functions that return change
	uint64 constant SECOND = 1;
	uint64 constant MINUTE = 60;	
	
	// ****************************************************************	
	// Errors
	// ****************************************************************	
	// Security
	uint16 constant WRONG_CONSTRUCTOR_VALUES = 200;	
	uint16 constant NOT_MY_OWNER = 201;		
	// Gas
	uint16 constant NOT_ENOUGH_VALUE = 666;	
	
	// ****************************************************************	
	// Value Flags
	// ****************************************************************		
	uint8 constant FEE_FROM_VALUE = 0; // Forward fee is subtracted from value sent
	uint8 constant FEE_EXTRA = 1; // Forward fee is subtracted sender's balance
    uint8 constant IGNORE_ERRORS = 2;  // Any errors arising during the action phase should be ignored.
    uint8 constant SELF_DESTROY = 32; // Destroys sender contract (if balance is 0)
    uint8 constant ALL_MESSAGE_GAS = 64; // Sends all remaining gas of message
    uint8 constant ALL_BALANCE_GAS = 128; // Sends all remaining gas of balance (except reserved)
	
	// ****************************************************************	
	// Internal Functions
	// ****************************************************************			
	// Calculating real amount for paying needed gas
	function _toValue(uint128 gasAmount) internal inline pure returns (uint128 gasValue) {
		return gasToValue(gasAmount, address(this).wid);
	}
	
	// Reserving constant amount of gas, so change return will pay correct sums
    function _reserve() internal inline view {
		tvm.rawReserve(_toValue(GAS_FLOOR), 0);
	}
	
	// Sending all change to address
	function _sendChange(address to) internal inline pure {
		to.transfer(0, true, ALL_BALANCE_GAS);
	}

	// Calculating reverse price for any EVER price
    function _reversePrice(uint128 forwardPrice_) internal pure returns (uint128)
    {
		return math.muldivc(
							10**9,
							10**9, 
							forwardPrice_
		);
    }		
	
	// Calculating currency exchange for any EVER price
    function _exchange(uint128 amount_, uint128 price_) internal pure returns (uint128)
    {
		return math.muldiv(
							amount_,
							price_, 
							10**9
		);
    }	
    
	// ****************************************************************	
	// Modifiers
	// ****************************************************************		
	modifier reserveGas {
		_reserve();
		_;
	}
	
	modifier checkValue(uint128 gasAmount) {
		require(msg.value >= _toValue(gasAmount), NOT_ENOUGH_VALUE);
		_;
	}
    
	modifier returnChange {    
		_;
		_sendChange(msg.sender);
	}
    
	modifier sendChangeTo(address to) {
		_;
		_sendChange(to);
	}	
}