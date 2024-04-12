// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IBlast.sol";
import "./IBlastPoints.sol";
import "./IOwnerGroupContract.sol";

contract RefThroneTypes {

    IBlast private _blast;
    IBlastPoints private _blastPoints;

    address private _blastContractAddress;
    address private _blastPointsContractAddress;
    address private _blastPointsOperatorAddress;
    address private _ownerGroupContractAddress;

    string[] private _serviceTypes;
    string[] private _benefitTypes;

    modifier onlyOwner (){
        require(IOwnerGroupContract(_ownerGroupContractAddress).isOwner(msg.sender), "Only Owner have a permission.");
        _;
    }

    modifier onlyAdmin (){
        require(IOwnerGroupContract(_ownerGroupContractAddress).isAdmin(msg.sender), "Only Admin have a permission.");
        _;
    }

    constructor(
        address ownerGroupContractAddress,
        address blastPointsContractAddress,
        address blastPointsOperatorAddress
    ) {
        _ownerGroupContractAddress = ownerGroupContractAddress;

        _blastContractAddress = 0x4300000000000000000000000000000000000002;
        _blast = IBlast(_blastContractAddress);
        _blast.configureClaimableGas();

        // BlastPoints Testnet address: 0x2fc95838c71e76ec69ff817983BFf17c710F34E0
        // BlastPoints Mainnet address: 0x2536FE9ab3F511540F2f9e2eC2A805005C3Dd800
        _blastPointsContractAddress = blastPointsContractAddress;
        _blastPointsOperatorAddress = blastPointsOperatorAddress;
        _blastPoints = IBlastPoints(_blastPointsContractAddress);
        _blastPoints.configurePointsOperator(_blastPointsOperatorAddress);

        _addServiceType("CEX");
        _addServiceType("DEX");
        _addServiceType("MISC");

        _addBenefitType("None");
        _addBenefitType("Fee Discount");
        _addBenefitType("USDT");
        _addBenefitType("USDC");
        _addBenefitType("BTC");
        _addBenefitType("ETH");
    }

    function getBlastPointsContractAddress() external view returns (address) {
        return _blastPointsContractAddress;
    }

    function getBlastPointsOperatorAddress() external view returns (address) {
        return _blastPointsOperatorAddress;
    }

    function claimAllGas() external onlyOwner {
        _blast.claimAllGas(address(this), _ownerGroupContractAddress);
    }

    function readGasParams() external view onlyOwner returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode) {
        return _blast.readGasParams(address(this));
    }

    function addServiceType(string memory serviceType) external onlyAdmin {
        _addServiceType(serviceType);
    }

    function _addServiceType(string memory serviceType) private {
        _serviceTypes.push(serviceType);
    }

    function deleteServiceType(string memory serviceType) public onlyAdmin {
        _deleteServiceType(serviceType);
    }

    function _deleteServiceType(string memory serviceType) private {
        for (uint i = 0; i < _serviceTypes.length; i++) {
            if (_compareStrings(_serviceTypes[i], serviceType)) {
                _serviceTypes[i] = _serviceTypes[_serviceTypes.length - 1];
                _serviceTypes.pop();
                break;
            }
        }
    }

    function getServiceTypes() external view returns (string[] memory) {
        return _serviceTypes;
    }

    function addBenefitType(string memory benefitType) external onlyAdmin {
        _addBenefitType(benefitType);
    }

    function _addBenefitType(string memory benefitType) private {
        _benefitTypes.push(benefitType);
    }

    function deleteBenefitType(string memory benefitType) external onlyAdmin {
        _deleteBenefitType(benefitType);
    }

    function _deleteBenefitType(string memory benefitType) private {
        for (uint i = 0; i < _benefitTypes.length; i++) {
            if (_compareStrings(_benefitTypes[i], benefitType)) {
                _benefitTypes[i] = _benefitTypes[_benefitTypes.length - 1];
                _benefitTypes.pop();
                break;
            }
        }
    }

    function getBenefitTypes() external view returns (string[] memory) {
        return _benefitTypes;
    }

    function _compareStrings(string memory a, string memory b) private pure returns (bool) {
        bytes32 hashA = keccak256(bytes(a));
        bytes32 hashB = keccak256(bytes(b));

        return hashA == hashB;
    }
}