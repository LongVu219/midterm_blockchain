pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Token is IERC20{
    string public constant name = "ERC20WithFee";
    string public constant symbol = "FERC";
    uint8 public constant decimals = 18;

    // Fee parameters
    uint256 public FEE_PERCENTAGE = 500; // 50% (500/1000)
    address public feeCollector;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => uint256) public lastUpdateTime;

    uint256 totalSupply_ = 100000 ether;
    uint256 public constant HOURLY_INCREASE_RATE = 1; // 0.1%
    uint256 public constant HOUR_IN_SECONDS = 3600;

    event DebugTransfer(
        address indexed sender, 
        address indexed receiver, 
        address indexed feeCollector,
        uint256 totalAmount, 
        uint256 feeAmount, 
        uint256 amountAfterFee
    );

    event BalanceIncreased(address indexed account, uint256 amount);
    constructor(address _feeCollector) {
        balances[msg.sender] = totalSupply_;
        owner = msg.sender;
        feeCollector = _feeCollector;
        lastUpdateTime[msg.sender] = block.timestamp;
    }

    modifier updateBalance(address account) {
        _updateAccountBalance(account);
        _;
    }

    // Internal function to calculate and apply hourly balance increase
    function _updateAccountBalance(address account) internal {
        if (block.timestamp > lastUpdateTime[account]) {
            uint256 hoursPassed = (block.timestamp - lastUpdateTime[account]) / HOUR_IN_SECONDS;
            
            if (hoursPassed > 0) {
                uint256 currentBalance = balances[account];
                uint256 increaseAmount = (currentBalance * HOURLY_INCREASE_RATE) / 1000 * hoursPassed;
                
                balances[account] += increaseAmount;
                totalSupply_ += increaseAmount;
                
                emit BalanceIncreased(account, increaseAmount);
                lastUpdateTime[account] = block.timestamp;
            }
        }
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        uint256 currentBalance = balances[tokenOwner];
        
        if (block.timestamp > lastUpdateTime[tokenOwner]) {
            uint256 hoursPassed = (block.timestamp - lastUpdateTime[tokenOwner]) / HOUR_IN_SECONDS;
            
            if (hoursPassed > 0) {
                currentBalance += (currentBalance * HOURLY_INCREASE_RATE) / 1000 * hoursPassed;
            }
        }
        
        return currentBalance;
    }

    function transfer(address receiver, uint256 numTokens) public override updateBalance(msg.sender) updateBalance(receiver) returns (bool) {
        // Rest of the transfer logic remains the same as in the original contract
        // Calculate fee
        uint256 fee = (numTokens * FEE_PERCENTAGE) / 1000;
        uint256 amountAfterFee = numTokens - fee;

        // Check if sender has enough balance
        require(numTokens <= balances[msg.sender], "Insufficient balance");

        // Deduct tokens from sender
        balances[msg.sender] -= numTokens;
        
        // Send tokens to receiver (minus fee)
        balances[receiver] += amountAfterFee;
        
        // Send fee to fee collector
        balances[feeCollector] += fee;
        
        emit DebugTransfer(
            msg.sender, 
            receiver, 
            feeCollector, 
            numTokens, 
            fee, 
            amountAfterFee
        );

        emit Transfer(msg.sender, receiver, amountAfterFee);
        emit Transfer(msg.sender, feeCollector, fee);

        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override 
        updateBalance(owner) 
        updateBalance(buyer) 
        returns (bool) {
        // Calculate fee
        uint256 fee = (numTokens * FEE_PERCENTAGE) / 1000;
        uint256 amountAfterFee = numTokens - fee;

        // Check conditions
        require(numTokens <= balances[owner], "Insufficient balance");
        require(numTokens <= allowed[owner][msg.sender], "Insufficient allowance");

        // Deduct tokens from owner
        balances[owner] -= numTokens;
        
        // Reduce allowance
        allowed[owner][msg.sender] -= numTokens;

        // Send tokens to buyer (minus fee)
        balances[buyer] += amountAfterFee;
        
        // Send fee to fee collector
        balances[feeCollector] += fee;

        emit Transfer(owner, buyer, amountAfterFee);
        emit Transfer(owner, feeCollector, fee);

        return true;
    }

    function setFeeCollector(address _newFeeCollector) public {
        feeCollector = _newFeeCollector;
    }

    function setFee(uint256 _newFee) public return(bool){
        if (msg.sender == _feeCollector) {
            FEE_PERCENTAGE = _newFee;
            return true
        }
        return false;            
    }

}