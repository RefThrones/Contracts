// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBlast.sol";
import "./IUserHistory.sol";
import "./IOwnerGroupContract.sol";

contract RefThrone {
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

    IBlast private _blast;
    IERC20 private _torToken;
    IUserHistory private _userHistory;
    IOwnerGroupContract private _ownerGroupContract;

    address private _blastContractAddress;
    address private _torTokenContractAddress;
    address private _userHistoryContractAddress;

    string[] private _serviceTypes;
    string[] private _benefitTypes;

    uint256 private _lastThroneId = 0;

    mapping(uint256 throneId => Throne) private _thrones;
    uint256[] private _throneIds;

    uint256 private _totalTorDeposited = 0;
    mapping(address => uint256 torAmount) private _torDepositedByAddress;

    // uint256 private _depositeFeeRate = 1;
    // uint256 private _withdrawFeeRate = 2;

    modifier onlyOwner (){
        require(_ownerGroupContract.isOwner(msg.sender), "Only Owner have a permission.");
        _;
    }

    constructor(
        address torTokenContractAddress,
        address userHistoryContractAddress,
        address ownerGroupContractAddress
    ) {
        setBlastContractAddress(0x4300000000000000000000000000000000000002);
        setTorTokenContractAddress(torTokenContractAddress);
        setUserHistoryContractAddress(userHistoryContractAddress);
        _ownerGroupContract = IOwnerGroupContract(ownerGroupContractAddress);

        _addServiceType("CEX");
        _addServiceType("DEX");
        _addServiceType("MISC");

        _addBenefitType("Fee Discount");
        _addBenefitType("USDT");
        _addBenefitType("USDC");
        _addBenefitType("BTC");
        _addBenefitType("ETH");
    }

    function setBlastContractAddress(address blastContractAddress) public onlyOwner {
        _blastContractAddress = blastContractAddress;
        _blast = IBlast(_blastContractAddress);
        _blast.configureClaimableGas();
    }

    function getBlastContractAddress() external view returns (address) {
        return _blastContractAddress;
    }

    function setTorTokenContractAddress(address torTokenContractAddress) public onlyOwner {
        _torTokenContractAddress = torTokenContractAddress;
        _torToken = IERC20(_torTokenContractAddress);
    }

    function getTorTokenContractAddress() external view returns (address) {
        return _torTokenContractAddress;
    }

    function setUserHistoryContractAddress(address userHistoryContractAddress) public onlyOwner {
        _userHistoryContractAddress = userHistoryContractAddress;
        _userHistory = IUserHistory(_userHistoryContractAddress);
    }

    function getUserHistoryContractAddress() external view returns (address) {
        return _userHistoryContractAddress;
    }

    function claimAllGas() external onlyOwner {
        // This function is public meaning anyone can claim the gas
        _blast.claimAllGas(address(this), msg.sender);
    }

    function readGasParams() external view onlyOwner returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode) {
        return _blast.readGasParams(address(this));
    }

    function addServiceType(string memory serviceType) external onlyOwner {
        _addServiceType(serviceType);
    }

    function getServiceTypes() external view returns (string[] memory) {
        return _serviceTypes;
    }

    function addBenefitType(string memory benefitType) external onlyOwner {
        _addBenefitType(benefitType);
    }

    function getBenefitTypes() external view returns (string[] memory) {
        return _benefitTypes;
    }

    function getTotalTorDeposited() external view returns (uint256 torAmount) {
        return _totalTorDeposited;
    }

    function getTorDepositedByAddress(address address_) external view returns (uint256 torAmount) {
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
        require(_torToken.balanceOf(msg.sender) > torAmount, "Not enough TOR balance.");
        require(_torToken.allowance(msg.sender, address(this)) >= torAmount, "Insufficient allowance");
        require(!_isThroneInReview(msg.sender, name, benefitType), "Already in review");

        uint256 ownedThroneId = _findThroneId(Status.Owned, name, benefitType);
        if (ownedThroneId > 0) {
            _checkUsurpCondition(
                _thrones[ownedThroneId].benefitAmount, _thrones[ownedThroneId].torAmount,
                benefitAmount, torAmount
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

    function _checkUsurpCondition(
        uint256 ownedBenefitAmount, uint256 ownedTorAmount,
        uint256 challengerBenefitAmount, uint256 challengerTorAmount
    ) private pure {
        require(challengerTorAmount > 0, "At least 1 TOR is required");
        require(
            (challengerBenefitAmount > ownedBenefitAmount) ||
            ((challengerBenefitAmount == ownedBenefitAmount) && (challengerTorAmount > ownedTorAmount)),
            "Either benefit or TOR amount should be greater than current throne"
        );
    }

    function withdrawFromThrone(uint256 throneId) external returns (bool success) {
        require(_thrones[throneId].referrer == msg.sender, "addresses are not match between referrer and the sender");
        require(_thrones[throneId].id > 0, "Invalid throne id");
        require(
            _thrones[throneId].status == Status.Owned || _thrones[throneId].status == Status.InReview,
            "The throne is not in the state of Owned or InReview"
        );

        _withdraw(msg.sender, _thrones[throneId].torAmount);

        _deleteThrone(throneId);

        return true;
    }

    function cancelThrone(uint256 throneId) external onlyOwner {
        require(_thrones[throneId].id > 0, "Invalid throne id");
        require(
            _thrones[throneId].status == Status.Owned,
            "The throne is not in the state of Owned"
        );

        _withdraw(msg.sender, _thrones[throneId].torAmount);

        _deleteThrone(throneId);
    }

    function _withdraw(address address_, uint256 torAmountToWithdraw) private {
        require(address_ != address(0), "Invalid address");
        require(torAmountToWithdraw > 0, "Invalid TOR amount to withdraw");
        require(_totalTorDeposited >= torAmountToWithdraw, "Not enough total TOR amount");
        require(_torDepositedByAddress[address_] >= torAmountToWithdraw, "Not enough TOR deposited");
        require(_torToken.balanceOf(address(this)) >= torAmountToWithdraw, "Not enough TOR balance.");

        _torToken.transfer(address_, torAmountToWithdraw);
        _totalTorDeposited -= torAmountToWithdraw;
        _torDepositedByAddress[address_] -= torAmountToWithdraw;
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
        address referrer = _thrones[throneId].referrer;

        require(referrer != address(0), "Invalid referrer address");
        require(
            _thrones[throneId].status == Status.InReview,
            "The throne is not in the state of InReview"
        );

        string memory name = _thrones[throneId].name;
        string memory benefitType = _thrones[throneId].benefitType;

        uint256 currentThroneId = _findThroneId(Status.Owned, name, benefitType);
        if (currentThroneId > 0) {
            _checkUsurpCondition(
                _thrones[currentThroneId].benefitAmount, _thrones[currentThroneId].torAmount,
                _thrones[throneId].benefitAmount, _thrones[throneId].torAmount
            );

            _lostThrone(currentThroneId);
            _userHistory.setUsurpActivity(referrer, block.timestamp);
        } else {
            _userHistory.setThroneActivity(referrer, block.timestamp);
        }

        _thrones[throneId].status = Status.Owned;

        emit ThroneStatus(throneId, Status.Owned);
    }

    function rejectThrone(uint256 throneId) external onlyOwner {
        require(_thrones[throneId].id > 0, "Invalid throne id");
        require(_thrones[throneId].status == Status.InReview, "The throne is not in the state of InReview");

        _withdraw(_thrones[throneId].referrer, _thrones[throneId].torAmount);

        _thrones[throneId].status = Status.Rejected;

        emit ThroneStatus(throneId, Status.Rejected);
    }

    function _lostThrone(uint256 throneId) private onlyOwner {
        require(_thrones[throneId].id > 0, "Invalid throne id");
        require(_thrones[throneId].status == Status.Owned, "The throne is not in the state of Owned");

        _withdraw(_thrones[throneId].referrer, _thrones[throneId].torAmount);

        _thrones[throneId].status = Status.Lost;

        emit ThroneStatus(throneId, Status.Lost);
    }

    function getAllOwnedThrones() external view returns (Throne[] memory) {
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

    function getAllThronesInReview() external view onlyOwner returns (Throne[] memory) {
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

    function getThronesByAddress(address address_) external view returns (Throne[] memory) {
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

    function getThroneById(uint256 throneId) external view returns (Throne memory) {
        require(_thrones[throneId].id > 0, "Invalid throne id");
        return _thrones[throneId];
    }

    function getOwnedThroneCount() external view returns (uint256) {
        return _getThroneCountInStatus(Status.Owned);
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
                _thrones[throneId].status == Status.InReview &&
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