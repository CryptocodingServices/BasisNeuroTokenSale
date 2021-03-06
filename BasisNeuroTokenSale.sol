pragma solidity ^0.4.17;

contract Ownable{
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public{
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}


contract BasisNeuroTokenSale  is Ownable{

    uint256 public totalSupply;


    string public constant name = "Basis Neuro Token";
    string public constant symbol = "BNT";
    uint32 public constant decimals = 18;

    mapping (address => uint256) balances; //Addresses map
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public startTime; // ICO  start date
    uint256 public endTime; // ICO  finish date
    uint256 public period; //ICO period
    uint256 public teamTokenUseDate; // Date when team can use tokens
    
    address public constant ownerWallet=0x14723a09acff6d2a60dcdf7aa4aff308fddc160c; // Owner wallet address
    address public constant teamWallet=0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db; // Team wallet address
    address public constant bountyWallet= 0x583031d1113ad414f02576bd6afabfb302140225; // Team wallet address

    uint256 public constant ownerPercent= 10; // Owner percent token rate
    uint256 public constant teamPercent=20; // Team percent token rate
    uint256 public constant bountyPercent=10; // bounty percent token rate

    bool public transferAllowed;
    bool public refundToken;

    /**
     * Token constructor
     *
     **/
    function BasisNeuroTokenSale() public {

        transferAllowed = false;
        refundToken=false;

        startTime = 1515628800; // 11.01.2018 00:00
        period = 20 * 1 days; //CHANGE first number
        endTime =  startTime + period;
        teamTokenUseDate = endTime + 365 * 1 days; //teamTokenUseDate is 1 year after  ICO end

        owner = msg.sender;

        totalSupply = 10000000000 * 1 ether;
        balances[owner] = totalSupply;
    }

    /**
     *  Modifier for checking token transfer
     */
    modifier canTransferToken() {
        if(msg.sender != owner){
            require(transferAllowed);
        }

        if (msg.sender == teamWallet){
            require(now >= teamTokenUseDate);
        }
        _;
    }

    /**
     *  Modifier for checking transfer allownes
     */
    modifier notAllowed(){
        require(!transferAllowed);
        _;
    }

    /**
     *  Modifier for checking ICO period
     */
    modifier saleIsOn() {
        require(now > startTime && now < endTime);
        _;
    }

    /**
     *  Modifier for checking refund allownes
     */

    modifier canRefundToken() {
        require(refundToken);
        _;
    }

    /**
     *  function for finishing ICO and allowed token transfer
     */
    function finishICO() public onlyOwner {
        transferAllowed = true;
    }
    
    /**
     *  function for set startTime
     */
    function SetStartDate(uint newStart) public onlyOwner {
        require(now < startTime && now < newStart);
        startTime = newStart;
    }
    
   /**
     *  function for set Period
     */
    function SetPeriod(uint NewPeriod) public onlyOwner {
        require(now < startTime);
        period = NewPeriod;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        uint256 tokenValue = balances[owner];

        transfer(newOwner, tokenValue);
        owner = newOwner;

        OwnershipTransferred(owner, newOwner);

    }
    /**
     *  Allownes refund
     */
    function changeRefundToken() public onlyOwner {
        require(now >= endTime);
        refundToken = true;
    }

    /**
     *
     *   Adding bonus tokens for bounty, team and owner needs. Should be used by DAPPs
     */
    function dapsBonusCalc (address _to, uint256 _value) onlyOwner saleIsOn notAllowed public returns (bool) {

        require(_value != 0 );
        transfer(_to, _value);

        uint256 bountyTokenAmount=0;
        uint256 ownerTokenAmount=0;
        uint256 teamTokenAmount=0;

        //calc bounty bonuses
        bountyTokenAmount =  _value * bountyPercent / 60;

        //calc owner bonuses
        ownerTokenAmount = _value * ownerPercent / 60;

        //calc teamTokenAmount bonuses
        teamTokenAmount = _value * teamPercent / 60;

        assert(balances[owner] > ownerTokenAmount);
        transfer(ownerWallet, ownerTokenAmount);

        assert(balances[owner] > bountyTokenAmount);
        transfer(bountyWallet, bountyTokenAmount);

        assert(balances[owner] > teamTokenAmount);
        transfer(teamWallet, teamTokenAmount);

        return true;
    }


    /**
     *
     *   Return number of tokens for address
     */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


    function transfer(address _to, uint256 _value) canTransferToken  public returns (bool){
        require(_to != address(0));
        require(balances[msg.sender]>=_value);
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        Transfer(msg.sender, _to, _value);

        return true;
    }
    
    function () payable {
        
    }


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) canTransferToken public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * function for after ICO burning tokens which was not bought
     * @param _value uint256 Amount of burning tokens
     */
    function burn(uint256 _value) onlyOwner public returns (bool){
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner] - _value;
        totalSupply = totalSupply - _value;
        Burn(burner, _value);
        return true;
    }


    /**
     * return investor tokens and burning
     * @param _from address  The address which owns the funds.
     * @param _value uint256 Token amount for refunding.
     */
    function refund(address _from, uint256 _value) canRefundToken onlyOwner public  returns (bool){
        require(_value > 0);
        require(_from != address(0));
        require(_value <= balances[_from]);
        balances[_from] = balances[_from] - _value;
        totalSupply = totalSupply - _value;
        return true;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);

}
