// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBlast.sol";

contract RefThrone is Ownable {
    event ThroneStatus(uint256 throneId, Status status);

    enum Status {
        InReview,
        Owned,
        Rejected,
        Lost
    }

    struct Throne {
        uint256 id;
        string name;
        string serviceType;
        string benefitType;
        uint256 benefitAmount;
        address referrer;
        string referralCode;
        uint256 torAmount;
        string linkUrl;
        Status status;
        uint256 timestamp;
    }

    IERC20 private _torToken;

    string[] private _serviceTypes;
    string[] private _benefitTypes;

    uint256 private _lastThroneId = 0;

    mapping(uint256 throneId => Throne) private _thrones;
    uint256[] private _throneIds;

    uint256 private _totalTorDeposited = 0;
    mapping(address => uint256 torAmount) private _torDepositedByAddress;

    // uint256 private _depositeFeeRate = 1;
    // uint256 private _withdrawFeeRate = 2;

    constructor(address torTokenAddress) Ownable(msg.sender) {
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableGas();

        _torToken = IERC20(torTokenAddress);

        _addServiceType("CEX");
        _addServiceType("DEX");
        _addServiceType("MISC");

        _addBenefitType("Fee Discount");
        _addBenefitType("USDT");
        _addBenefitType("USDC");
        _addBenefitType("BTC");
        _addBenefitType("ETH");
    }

    function claimAllGas() external onlyOwner {
        // This function is public meaning anyone can claim the gas
        IBlast(0x4300000000000000000000000000000000000002).claimAllGas(address(this), msg.sender);
    }

    function addServiceType(string memory serviceType) public onlyOwner {
        _addServiceType(serviceType);
    }

    function getServiceTypes() public view returns (string[] memory) {
        return _serviceTypes;
    }

    function addBenefitType(string memory benefitType) public onlyOwner {
        _addBenefitType(benefitType);
    }

    function getBenefitTypes() public view returns (string[] memory) {
        return _benefitTypes;
    }

    function getTotalTorDeposited() public view returns (uint256 torAmount) {
        return _totalTorDeposited;
    }

    function getTorDepositedByAddress(address address_) public view returns (uint256 torAmount) {
        return _torDepositedByAddress[address_];
    }

    function requestDepositForThrone(
        string memory name,
        string memory serviceType,
        string memory benefitType,
        uint256 benefitAmount,
        string memory referralCode,
        uint256 torAmount,
        string memory linkUrl
    ) external returns (uint256 throneId) {
        require(torAmount > 0, "At least 1 TOR is required");
        require(_torToken.balanceOf(msg.sender) > torAmount, "Not enough TOR balance.");
        require(_torToken.allowance(msg.sender, address(this)) >= torAmount, "Insufficient allowance");
        require(!_isThroneInReview(msg.sender, name, benefitType), "Already in review");

        uint256 ownedThroneId = _findThroneId(Status.Owned, name, benefitType);
        if (ownedThroneId > 0) {
            require(
                benefitAmount > _thrones[ownedThroneId].benefitAmount ||
                torAmount > _thrones[ownedThroneId].torAmount,
                "Either benefit or TOR amount should be greater than current throne"
            );
        }

        _torToken.transferFrom(msg.sender, address(this), torAmount);
        _totalTorDeposited += torAmount;
        _torDepositedByAddress[msg.sender] += torAmount;

        uint256 newThroneId = _getNewThroneId();

        _thrones[newThroneId] = Throne({
            name: name,
            id: newThroneId,
            serviceType: serviceType,
            benefitType: benefitType,
            benefitAmount: benefitAmount,
            referrer: msg.sender,
            referralCode: referralCode,
            torAmount: torAmount,
            linkUrl: linkUrl,
            status: Status.InReview,
            timestamp: block.timestamp
        });

        _throneIds.push(newThroneId);

        _deleteLostOrRejectedThrone(msg.sender, name, benefitType);

        emit ThroneStatus(throneId, Status.InReview);

        return newThroneId;
    }

    function withdrawFromThrone(uint256 throneId) external returns (bool success) {
        require(_thrones[throneId].referrer == msg.sender);
        require(_thrones[throneId].status == Status.Owned || _thrones[throneId].status == Status.InReview);

        uint256 torAmount = _thrones[throneId].torAmount;

        require(_torDepositedByAddress[msg.sender] >= torAmount);
        require(_torToken.balanceOf(address(this)) >= torAmount, "Not enough TOR balance.");

        _torToken.transfer(msg.sender, torAmount);
        _totalTorDeposited -= torAmount;
        _torDepositedByAddress[msg.sender] -= torAmount;

        _deleteThrone(throneId);

        return true;
    }

    function modifyThroneInReview(
        uint256 throneId,
        string memory name,
        string memory serviceType,
        string memory benefitType,
        string memory linkUrl
    ) external onlyOwner {
        require(
            _thrones[throneId].status == Status.InReview,
            "Only the throne in review can be modified"
        );

        _thrones[throneId].name = name;
        _thrones[throneId].serviceType = serviceType;
        _thrones[throneId].benefitType = benefitType;
        _thrones[throneId].linkUrl = linkUrl;
    }

    function approveThrone(uint256 throneId) external onlyOwner {
        string memory name = _thrones[throneId].name;
        string memory benefitType = _thrones[throneId].benefitType;

        uint256 currentThroneId = _findThroneId(Status.Owned, name, benefitType);
        if (currentThroneId > 0) {
            _lostThrone(currentThroneId);
        }

        _thrones[throneId].status = Status.Owned;

        emit ThroneStatus(throneId, Status.Owned);
    }

    function rejectThrone(uint256 throneId) external onlyOwner {
        address referrer = _thrones[throneId].referrer;

        require(referrer != address(0));
        require(_thrones[throneId].status == Status.InReview);

        uint256 torAmount = _thrones[throneId].torAmount;

        require(_torDepositedByAddress[referrer] >= torAmount);
        require(_torToken.balanceOf(address(this)) >= torAmount, "Not enough TOR balance.");

        _torToken.transfer(referrer, torAmount);
        _totalTorDeposited -= torAmount;

        _thrones[throneId].status = Status.Rejected;

        emit ThroneStatus(throneId, Status.Rejected);
    }

    function _lostThrone(uint256 throneId) private onlyOwner {
        require(_thrones[throneId].id > 0);
        require(_thrones[throneId].status == Status.Owned);

        address referrer = _thrones[throneId].referrer;

        require(_torDepositedByAddress[referrer] >= _thrones[throneId].torAmount);

        _torToken.transferFrom(address(this), referrer, _thrones[throneId].torAmount);
        _totalTorDeposited -= _thrones[throneId].torAmount;
        _torDepositedByAddress[referrer] -= _thrones[throneId].torAmount;

        _thrones[throneId].status = Status.Lost;

        emit ThroneStatus(throneId, Status.Lost);
    }

    function getAllOwnedThrones() public view returns (Throne[] memory) {
        uint ownedThroneCount = _getThroneCountInStatus(Status.Owned);

        Throne[] memory ownedThrones = new Throne[](ownedThroneCount);

        uint256 ownedThroneIndex = 0;
        for (uint256 i = 0; i < _throneIds.length; i++) {
            if (_isThroneInStatus(_throneIds[i], Status.Owned)) {
                ownedThrones[ownedThroneIndex++] = _thrones[_throneIds[i]];
            }
        }

        return ownedThrones;
    }

    function getAllThronesInReview() public view onlyOwner returns (Throne[] memory) {
        uint throneInReviewCount = _getThroneCountInStatus(Status.InReview);

        Throne[] memory thronesInReview = new Throne[](throneInReviewCount);

        uint256 throneInReviewIndex = 0;
        for (uint256 i = 0; i < _throneIds.length; i++) {
            if (_isThroneInStatus(_throneIds[i], Status.InReview)) {
                thronesInReview[throneInReviewIndex++] = _thrones[_throneIds[i]];
            }
        }

        return thronesInReview;
    }

    function getThronesByAddress(address address_) public view returns (Throne[] memory) {
        uint throneCount = _getThroneCountOfAddress(address_);

        Throne[] memory thrones = new Throne[](throneCount);

        uint throneIndex = 0;
        for (uint256 i = 0; i < _throneIds.length; i++) {
            if (_thrones[_throneIds[i]].referrer == address_) {
                thrones[throneIndex++] = _thrones[_throneIds[i]];
            }
        }

        return thrones;
    }

    function getThroneById(uint256 throneId) public view returns (Throne memory) {
        require(_thrones[throneId].id > 0);
        return _thrones[throneId];
    }

    function _addServiceType(string memory serviceType) private {
        _serviceTypes.push(serviceType);
    }

    function _addBenefitType(string memory benefitType) private {
        _benefitTypes.push(benefitType);
    }

    function _getNewThroneId() private returns (uint256) {
        return ++_lastThroneId;
    }

    function _findThroneId(
        Status status,
        string memory name,
        string memory benefitType
    ) private view returns (uint256) {
        for (uint i = 0; i < _throneIds.length; i++) {
            uint256 throneId = _throneIds[i];

            if (_thrones[throneId].status == status &&
                _compareStrings(_thrones[throneId].name, name) &&
                _compareStrings(_thrones[throneId].benefitType, benefitType)) {
                return throneId;
            }
        }

        return 0;
    }

    function _deleteLostOrRejectedThrone(
        address address_,
        string memory name,
        string memory benefitType
    ) private {
        uint length = _throneIds.length;
        for (uint i = 0; i < length; i++) {
            uint256 throneId = _throneIds[i];
            if ((_thrones[throneId].status == Status.Lost || _thrones[throneId].status == Status.Rejected) &&
                _thrones[throneId].referrer == address_ &&
                _compareStrings(_thrones[throneId].name, name) &&
                _compareStrings(_thrones[throneId].benefitType, benefitType)
            ) {
                _throneIds[i] = _throneIds[length - 1];
                _throneIds.pop();
                delete _thrones[throneId];
                break;
            }
        }
    }

    function _deleteThrone(uint256 throneId) private {
        uint length = _throneIds.length;
        for (uint i = 0; i < length; i++) {
            if (_thrones[_throneIds[i]].id == throneId) {
                _throneIds[i] = _throneIds[length - 1];
                _throneIds.pop();
                delete _thrones[throneId];
                break;
            }
        }
    }

    function _isThroneInReview(
        address address_,
        string memory name,
        string memory benefitType
    ) private view returns (bool) {
        for (uint i = 0; i < _throneIds.length; i++) {
            uint256 throneId = _throneIds[i];

            if (_thrones[throneId].referrer == address_ &&
                _compareStrings(_thrones[throneId].name, name) &&
                _compareStrings(_thrones[throneId].benefitType, benefitType)) {
                return true;
            }
        }

        return false;
    }

    function _getThroneCountInStatus(Status status) private view returns (uint count) {
        uint throneCount = 0;
        for (uint256 i = 0; i < _throneIds.length; i++) {
            if (_isThroneInStatus(_throneIds[i], status)) {
                throneCount++;
            }
        }
        return throneCount;
    }

    function _getThroneCountOfAddress(address address_) private view returns (uint count) {
        uint throneCount = 0;
        for (uint256 i = 0; i < _throneIds.length; i++) {
            if (_thrones[_throneIds[i]].referrer == address_) {
                throneCount++;
            }
        }
        return throneCount;
    }

    function _isThroneInStatus(uint256 throneId, Status status) private view returns (bool) {
        return _thrones[throneId].status == status;
    }

    function _compareStrings(string memory a, string memory b) private pure returns (bool) {
        bytes32 hashA = keccak256(bytes(a));
        bytes32 hashB = keccak256(bytes(b));

        return hashA == hashB;
    }
}