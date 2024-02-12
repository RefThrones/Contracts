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

    modifier onlyOwner(){
        require(msg.sender == _owner, "You are not the owner");
        _;
    }

    modifier notBlacklisted() {
        require(!blacklist[msg.sender], "You are blacklisted");
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

    function getInvitees(address inviter) external view returns (address[] memory) {
        return _invitees[inviter];
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

   function generateInvitationCode(address account) external notBlacklisted returns (string memory) {
                
        require(bytes(_invitationCode[account]).length <= 0, "Invitation code already generated.");

        _invitationSize++;
        bytes32 hashValue = keccak256(abi.encodePacked(account, block.timestamp));
        string memory hashString  = concatenateStrings(toString(_invitationSize), string(abi.encodePacked(hashValue)));

        _invitationCode[account] = hashString;
        _invitationAddresses.push(account);

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

    function setXurl(address account, string memory url) external {
        _users[account].xUrl = url;    
    }

    function setTelegramUrl(address account, string memory url) external {
        _users[account].telegramUrl = url;    
    }

    function setUtubeUrl(address account, string memory url) external {
        _users[account].uTubeUrl = url;    
    }

    function setDiscordUrl(address account, string memory url) external {
        _users[account].discordUrl = url;    
    }

    function getUserInfo(address account) external view returns (User memory){
        return _users[account];
    }

    
}

