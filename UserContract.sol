// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IUserHistory.sol";
import "./InvitationCodeGenerator.sol";
import "./IOwnerGroupContract.sol";
import "./IBlast.sol";

contract UserContract is InvitationCodeGenerator{

    address private _owner;
    uint256 private _invitationSize=0;
    IUserHistory private _historyToken;
    IOwnerGroupContract private _ownerGroupContract;

    struct User {
        string nickName;
        string xUrl;
        string uTubeUrl;
        string telegramUrl;
        string discordUrl;
    }

    mapping(address account => User) private _users;
    mapping(address => bool) public blacklist;
    mapping(address => string) private _invitationCode;
    address[] private _invitationAddresses;

    mapping(address => address[]) private _invitees;
    address private _ownerGroupContractAddress;


    event BlacklistUpdated(address indexed _address, bool _isBlacklisted);
    event UserCreated(address indexed _address, string nickName, string xUrl, string uTubeUrl, string telegramUrl, string discordUrl);
    event GenerateInvitaionCode(address indexed _address, string code);
    event AddInvitee(address indexed inviter, address indexed invitee, string code);

    modifier onlyOwner (){
        require(_ownerGroupContract.isOwner(msg.sender), "Only Owner have a permission.");
        _;
    }

    modifier notBlacklisted() {
        require(!blacklist[msg.sender], "You are blacklisted");
        _;
    }

    constructor(address historyToken, address ownerGroupContractAddress) {
        _owner = msg.sender;
        _historyToken = IUserHistory(historyToken);
        _ownerGroupContract = IOwnerGroupContract(ownerGroupContractAddress);
        _ownerGroupContractAddress = ownerGroupContractAddress;
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableYield();
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableGas();
    }

    function claimYield(uint256 amount) external onlyOwner returns (uint256){
        //This function is public meaning anyone can claim the yield
        return IBlast(0x4300000000000000000000000000000000000002).claimYield(address(this), _ownerGroupContractAddress, amount);
    }

    function readClaimableYield() external view onlyOwner returns (uint256){
        //This function is public meaning anyone can claim the yield
        return IBlast(0x4300000000000000000000000000000000000002).readClaimableYield(address(this));
    }

    function claimAllYield() external onlyOwner returns (uint256){
        //This function is public meaning anyone can claim the yield
        return IBlast(0x4300000000000000000000000000000000000002).claimAllYield(address(this), _ownerGroupContractAddress);
    }

    function claimAllGas() external onlyOwner {
        // This function is public meaning anyone can claim the gas
        IBlast(0x4300000000000000000000000000000000000002).claimAllGas(address(this), _ownerGroupContractAddress);
    }

    function readGasParams() external view onlyOwner returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode) {
        return IBlast(0x4300000000000000000000000000000000000002).readGasParams(address(this));
    }

    function updateUserHistoryContractAddress(address historyToken) external onlyOwner returns (bool){
        _historyToken = IUserHistory(historyToken);
        return true;
    }

    function getUserHistoryContractAddress() external onlyOwner view returns (address){
        return address(_historyToken);
    }

    function addInvitee(string memory code) external notBlacklisted returns (bool) {

        uint256 length = _invitationAddresses.length;
        for (uint256 i=0; i<length; i++){

            if(keccak256(abi.encodePacked(_invitationCode[_invitationAddresses[i]])) == keccak256(abi.encodePacked(code)))
            {
                _invitees[_invitationAddresses[i]].push(msg.sender);
                _historyToken.setInviteeActivity(msg.sender, block.timestamp);
                _historyToken.setInviterActivity(_invitationAddresses[i], block.timestamp);
                emit AddInvitee(_invitationAddresses[i], msg.sender, code);
                return true;
            }
        }

        return false;
    }

    function getInvitees() external view notBlacklisted returns (address[] memory) {
        return _invitees[msg.sender];
    }


    function generateInvitationCode() external notBlacklisted returns (string memory) {

        require(bytes(_invitationCode[msg.sender]).length <= 0, "Invitation code already generated.");

        _invitationSize++;

        _invitationCode[msg.sender] = generateCode();
        _invitationAddresses.push(msg.sender);

        _historyToken.setGenCodeActivity(msg.sender, block.timestamp);
        emit GenerateInvitaionCode(msg.sender, _invitationCode[msg.sender]);

        return _invitationCode[msg.sender];
    }

    function getInvitaionCode(address account) external view notBlacklisted returns (string memory){
        return _invitationCode[account];
    }

    function isUserInBlackList(address account) external view returns (bool) {
        return blacklist[account];
    }

    function updateBlackList(address account) external onlyOwner returns (bool){
        bool value = !blacklist[account];
        blacklist[account] = value;
        emit BlacklistUpdated(account, value);

        return true;
    }

    function setUserInfo(string memory nickName, string memory xUrl, string memory uTubeUrl, string memory telegramUrl, string memory discordUrl) external notBlacklisted returns (bool) {

        _users[msg.sender].nickName = nickName;
        _users[msg.sender].xUrl = xUrl;
        _users[msg.sender].uTubeUrl = uTubeUrl;
        _users[msg.sender].telegramUrl = telegramUrl;
        _users[msg.sender].discordUrl = discordUrl;

        _historyToken.setUsurpActivity(msg.sender, block.timestamp);
        emit UserCreated(msg.sender, nickName, xUrl, uTubeUrl, telegramUrl, discordUrl);

        return true;
    }

    function getUserInfo() external view notBlacklisted returns (User memory) {
        return _users[msg.sender];
    }


}
