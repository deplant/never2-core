pragma ton-solidity >=0.58.2;

import "../common/AuctionBase.sol";

interface IAuction {
    function commit(uint256 priceHash_) external internalMsg responsible returns (address);
    function destroy() external internalMsg;
    function startReveal(uint128 quotingPrice_) external internalMsg;		
    function startTrade() external internalMsg;	
	function acceptReveal(AuctionBase.BidData bid_) external internalMsg responsible returns (AuctionBase.BidData);
	function acceptLoserTrade(AuctionBase.BidData bid_, uint128 amount_) external internalMsg responsible returns (uint16 winStatus, uint128 price, uint128 amount);	
	//getters 
	function getWinner() external view returns (address winner, uint128 winningPrice);	
	function getBidAddress(address bidder_) external view returns (address bidAddress);
	function getCommitHash(uint128 priceReveal_, uint128 amountReveal_, uint256 salt_) external pure returns (uint256 bidHash);	
}