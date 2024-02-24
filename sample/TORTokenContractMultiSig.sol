// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TORTokenContractMultiSig  {

    mapping(address account => bool) private _owners;
    //TOR token balances
    mapping(address account => uint256) private _balances;
    //Delegate token
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    mapping(bytes32 => TransferRequest) public transferRequests;

    uint256 private _totalSupply;
    uint8 private _decimal=18;
    string public _name;
    string public _symbol;
    address[] private _owner;

    // Multisig transfer request structure
    struct TransferRequest {
        address to;
        uint256 amount;
        bool executed;
        uint256 confirmations;
        mapping(address => bool) confirmationsMap;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Event emitted when a transfer request is submitted
    event TransferRequested(bytes32 indexed requestId, address indexed to, uint256 amount);

    // Event emitted when a transfer request is confirmed
    event TransferConfirmed(bytes32 indexed requestId, address indexed owner);

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (_owners[msg.sender] != true) {
            revert("Msg.sender not owner!");
        }
    }


    constructor(address[] memory initialOwners)  {
        _name = "TOR Token";
        _symbol = "TOR";
        _totalSupply = 1_000_000_000 * (10**_decimal);

        for (uint256 i = 0; i < initialOwners.length; i++) {
            _owners[initialOwners[i]] = true;
        }
        // Mint some tokens to the initial owners
        for (uint256 i = 0; i < initialOwners.length; i++) {
            _mint(initialOwners[i], _totalSupply / initialOwners.length);
        }

    }

    function _mint(address to, uint256 amount) internal onlyOwner {
        _balances[to] += amount;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: insufficient balance");

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Submit a transfer request to be approved by multisig owners
    function submitTransferRequest(address to, uint256 amount) external onlyOwner {
        bytes32 requestId = keccak256(abi.encodePacked(to, amount, block.timestamp));
        require(!transferRequests[requestId].executed, "Transfer request already executed");

        TransferRequest storage request = transferRequests[requestId];
        require(!request.confirmationsMap[msg.sender], "Owner has already confirmed this request");

        request.to = to;
        request.amount = amount;
        request.executed = false;
        request.confirmations = 1;
        request.confirmationsMap[msg.sender] = true;

        emit TransferRequested(requestId, to, amount);
    }

    // Confirm a transfer request
    function confirmTransfer(bytes32 requestId) external onlyOwner {
        TransferRequest storage request = transferRequests[requestId];
        require(!request.executed, "Transfer request already executed");
        require(!request.confirmationsMap[msg.sender], "Owner has already confirmed this request");

        request.confirmationsMap[msg.sender] = true;
        request.confirmations++;

        emit TransferConfirmed(requestId, msg.sender);

        if (request.confirmations >= 2) {
            executeTransfer(requestId);
        }
    }

    // Execute a multisig-approved transfer
    function executeTransfer(bytes32 requestId) internal {
        TransferRequest storage request = transferRequests[requestId];
        require(!request.executed, "Transfer request already executed");
        require(request.confirmations >= 2, "Insufficient confirmations");

        address to = request.to;
        uint256 amount = request.amount;

        _transfer(msg.sender, to, amount);

        request.executed = true;
    }

}
