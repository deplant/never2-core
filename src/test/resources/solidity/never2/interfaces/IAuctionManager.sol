pragma ton-solidity >=0.58.2;

pragma AbiHeader expire;
pragma AbiHeader time;

interface IAuctionManager {
	// elector requests
	function startAuctions(uint64 dtStart_) external internalMsg;
	function revealAuctions(uint128 minPrice_) view external internalMsg;
	function tradeAuctions() view external internalMsg ;
	// bid trade requests
    function acceptMintEVER(address owner_, uint128 amount_, TvmCell payload_) view external internalMsg;
    function acceptMintNEVER(address owner_, uint128 amount_, TvmCell payload_) view external internalMsg;
	function acceptBurnNEVER(address owner_, uint128 amount_, TvmCell payload_) view external internalMsg;
	// settings
	function setNEVERRoot(address neverRoot_) external ;
	function setEVERReserve(address everReserve_) external ;
	function setAuctionCode(TvmCell code_) external ;
	function setEVERBidCode(TvmCell code_) external ;
	function setNEVERBidCode(TvmCell code_) external ;
	function setMinBid(uint128 minBid_) external ;
	function setLoserFactor(uint128 loserFactor_) external ;
	function setGovernance(address governance_) external ;
	function setElector(address elector_) external ;
}