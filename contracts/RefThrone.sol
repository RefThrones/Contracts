// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBlast.sol";
import "./IBlastPoints.sol";
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
    IBlastPoints private _blastPoints;
    IERC20 private _torToken;
    IUserHistory private _userHistory;
    IOwnerGroupContract private _ownerGroupContract;

    address private _blastContractAddress;
    address private _blastPointsContractAddress;
    address private _blastPointsOperatorAddress;
    address private _torTokenContractAddress;
    address private _userHistoryContractAddress;
    address private _ownerGroupContractAddress;

    uint256 private _lastThroneId = 0;

    mapping(uint256 throneId => Throne) private _thrones;
    uint256[] private _throneIds;

    uint256 private _totalTorDeposited = 0;
    mapping(address => uint256 torAmount) private _torDepositedByAddress;

    modifier onlyOwner () {
        require(_ownerGroupContract.isOwner(msg.sender), "Only Owner have a permission.");
        _;
    }

    modifier onlyAdmin () {
        require(_ownerGroupContract.isAdmin(msg.sender), "Only Admin have a permission.");
        _;
    }

    constructor(
        address torTokenContractAddress,
        address userHistoryContractAddress,
        address ownerGroupContractAddress,
        address blastPointsContractAddress,
        address blastPointsOperatorAddress
    ) {
        _ownerGroupContractAddress = ownerGroupContractAddress;
        _ownerGroupContract = IOwnerGroupContract(ownerGroupContractAddress);

        _blastContractAddress = 0x4300000000000000000000000000000000000002;
        _blast = IBlast(_blastContractAddress);
        _blast.configureClaimableGas();

        // BlastPoints Testnet address: 0x2fc95838c71e76ec69ff817983BFf17c710F34E0
        // BlastPoints Mainnet address: 0x2536FE9ab3F511540F2f9e2eC2A805005C3Dd800
        _blastPointsContractAddress = blastPointsContractAddress;
        _blastPointsOperatorAddress = blastPointsOperatorAddress;
        _blastPoints = IBlastPoints(_blastPointsContractAddress);
        _blastPoints.configurePointsOperator(_blastPointsOperatorAddress);

        _setTorTokenContractAddress(torTokenContractAddress);

        _setUserHistoryContractAddress(userHistoryContractAddress);
    }

    function getBlastPointsContractAddress() external view returns (address) {
        return _blastPointsContractAddress;
    }

    function getBlastPointsOperatorAddress() external view returns (address) {
        return _blastPointsOperatorAddress;
    }

    function setTorTokenContractAddress(address torTokenContractAddress) external onlyOwner {
        _setTorTokenContractAddress(torTokenContractAddress);
    }

    function _setTorTokenContractAddress(address torTokenContractAddress) private {
        _torTokenContractAddress = torTokenContractAddress;
        _torToken = IERC20(_torTokenContractAddress);
    }

    function getTorTokenContractAddress() external view returns (address) {
        return _torTokenContractAddress;
    }

    function setUserHistoryContractAddress(address userHistoryContractAddress) external onlyOwner {
        _setUserHistoryContractAddress(userHistoryContractAddress);
    }

    function _setUserHistoryContractAddress(address userHistoryContractAddress) private {
        _userHistoryContractAddress = userHistoryContractAddress;
        _userHistory = IUserHistory(_userHistoryContractAddress);
    }

    function getUserHistoryContractAddress() external view returns (address) {
        return _userHistoryContractAddress;
    }

    function claimAllGas() external onlyOwner {
        // This function is public meaning anyone can claim the gas
        _blast.claimAllGas(address(this), _ownerGroupContractAddress);
    }

    function readGasParams() external view onlyOwner returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode) {
        return _blast.readGasParams(address(this));
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
        require(_torToken.balanceOf(msg.sender) >= torAmount, "Not enough TOR balance.");
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
            "Benefit or TOR amount should be greater than current throne"
        );
    }

    function withdrawFromThrone(uint256 throneId) external returns (bool success) {
        require(_thrones[throneId].referrer == msg.sender, "addresses are not match");
        require(_thrones[throneId].id > 0, "Invalid id");
        require(
            _thrones[throneId].status == Status.Owned || _thrones[throneId].status == Status.InReview,
            "Not in Owned or InReview state"
        );

        _withdraw(msg.sender, _thrones[throneId].torAmount);

        _deleteThrone(throneId);

        _userHistory.setAbandonActivity(msg.sender, block.timestamp);

        return true;
    }

    function cancelThrone(uint256 throneId) external onlyAdmin {
        require(_thrones[throneId].id > 0, "Invalid id");
        require(
            _thrones[throneId].status == Status.Owned,
            "Not in Owned state"
        );

        _withdraw(msg.sender, _thrones[throneId].torAmount);

        _deleteThrone(throneId);
    }

    function _withdraw(address address_, uint256 torAmountToWithdraw) private {
        require(address_ != address(0), "Invalid address");
        require(torAmountToWithdraw > 0, "Invalid TOR amount to withdraw");
        require(_totalTorDeposited >= torAmountToWithdraw, "Not enough total TOR amount");
        require(_torDepositedByAddress[address_] >= torAmountToWithdraw, "Not enough TOR deposited");
        require(_torToken.balanceOf(address(this)) >= torAmountToWithdraw, "Not enough TOR balance");

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
    ) external onlyAdmin {
        require(
            _thrones[throneId].status == Status.InReview,
            "Not in InReview state"
        );

        _thrones[throneId].name = name;
        _thrones[throneId].serviceType = serviceType;
        _thrones[throneId].benefitType = benefitType;
        _thrones[throneId].linkUrl = linkUrl;
    }

    function approveThrone(uint256 throneId) external onlyAdmin {
        address referrer = _thrones[throneId].referrer;

        require(referrer != address(0), "Invalid referrer address");
        require(
            _thrones[throneId].status == Status.InReview,
            "Not in InReview state"
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

    function rejectThrone(uint256 throneId) external onlyAdmin {
        require(_thrones[throneId].id > 0, "Invalid id");
        require(_thrones[throneId].status == Status.InReview, "Not in InReview state");

        _withdraw(_thrones[throneId].referrer, _thrones[throneId].torAmount);

        _thrones[throneId].status = Status.Rejected;

        emit ThroneStatus(throneId, Status.Rejected);
    }

    function _lostThrone(uint256 throneId) private onlyAdmin {
        require(_thrones[throneId].id > 0, "Invalid id");
        require(_thrones[throneId].status == Status.Owned, "Not in Owned state");

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

    function getAllThronesInReview() external view onlyAdmin returns (Throne[] memory) {
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
        require(_thrones[throneId].id > 0, "Invalid id");
        return _thrones[throneId];
    }

    function getOwnedThroneCount() external view returns (uint256) {
        return _getThroneCountInStatus(Status.Owned);
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