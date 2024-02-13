// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract UserContract {

    address private _owner;
    uint256 private _invitationSize=0;

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

    event BlacklistUpdated(address indexed _address, bool _isBlacklisted);
    event UserCreated(address indexed _address, string nickName, string xUrl, string uTubeUrl, string telegramUrl, string discordUrl);
    event GenInvitaionCode(address indexed _address, string code);

    modifier onlyOwner(){
        require(msg.sender == _owner, "You are not the owner");
        _;
    }

    modifier notBlacklisted() {
        require(!blacklist[msg.sender], "You are blacklisted");
        _;
    }

    modifier isUserCreated() {
        require(bytes(_users[msg.sender].xUrl).length <= 0, "Invitation code already generated.");
        _;

    }

    function concatenateStrings(string memory str1, string memory str2) internal pure returns (string memory) {
        return string(abi.encodePacked(str1, str2));
    }

    function addInvitee(string memory code, address invitee) external returns (bool) {

        uint256 length = _invitationAddresses.length;
        for (uint256 i=0; i<length; i++){

            if(keccak256(abi.encodePacked(_invitationCode[_invitationAddresses[i]])) == keccak256(abi.encodePacked(code)))
            {
                _invitees[_invitationAddresses[i]].push(invitee);
                return true;
            }
        }

        return false;
    }

    function getInvitees() external view returns (address[] memory) {
        return _invitees[msg.sender];
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function generateInvitationCode() external notBlacklisted returns (string memory) {

        require(bytes(_invitationCode[msg.sender]).length <= 0, "Invitation code already generated.");

        _invitationSize++;
        bytes32 hashValue = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        string memory hashString  = concatenateStrings(toString(_invitationSize), string(abi.encodePacked(hashValue)));

        _invitationCode[msg.sender] = hashString;
        _invitationAddresses.push(msg.sender);

        emit GenInvitaionCode(msg.sender, _invitationCode[msg.sender]);

        return _invitationCode[msg.sender];
    }

    function getInvitaionCode() external view returns (string memory){
        return _invitationCode[msg.sender];
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

    function setUserInfo(string memory nickName, string memory xUrl, string memory uTubeUrl, string memory telegramUrl, string memory discordUrl) external returns (bool) {

        _users[msg.sender].nickName = nickName;
        _users[msg.sender].xUrl = xUrl;
        _users[msg.sender].uTubeUrl = uTubeUrl;
        _users[msg.sender].telegramUrl = telegramUrl;
        _users[msg.sender].discordUrl = discordUrl;

        emit UserCreated(msg.sender, nickName, xUrl, uTubeUrl, telegramUrl, discordUrl);

        return true;
    }

    function getUserInfo() external view notBlacklisted returns (User memory) {
        return _users[msg.sender];
    }

    function setXurl(string memory url) external notBlacklisted {
        _users[msg.sender].xUrl = url;
    }

    function setTelegramUrl(string memory url) external notBlacklisted {
        _users[msg.sender].telegramUrl = url;
    }

    function setUtubeUrl(string memory url) external notBlacklisted {
        _users[msg.sender].uTubeUrl = url;
    }

    function setDiscordUrl(string memory url) external notBlacklisted {
        _users[msg.sender].discordUrl = url;
    }


}
