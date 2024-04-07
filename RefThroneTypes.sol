// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IBlast.sol";
import "./IOwnerGroupContract.sol";

contract RefThroneTypes {
    address private _ownerGroupContractAddress;

    string[] private _serviceTypes;
    string[] private _benefitTypes;

    modifier onlyOwner (){
        require(IOwnerGroupContract(_ownerGroupContractAddress).isOwner(msg.sender), "Only Owner have a permission.");
        _;
    }

    constructor(address ownerGroupContractAddress) {
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableGas();

        _ownerGroupContractAddress = ownerGroupContractAddress;

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
        IBlast(0x4300000000000000000000000000000000000002).claimAllGas(address(this), _ownerGroupContractAddress);
    }

    function readGasParams() external view onlyOwner returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode) {
        return IBlast(0x4300000000000000000000000000000000000002).readGasParams(address(this));
    }

    function addServiceType(string memory serviceType) external onlyOwner {
        _addServiceType(serviceType);
    }

    function _addServiceType(string memory serviceType) private {
        _serviceTypes.push(serviceType);
    }

    function deleteServiceType(string memory serviceType) public onlyOwner {
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

    function addBenefitType(string memory benefitType) external onlyOwner {
        _addBenefitType(benefitType);
    }

    function _addBenefitType(string memory benefitType) private {
        _benefitTypes.push(benefitType);
    }

    function deleteBenefitType(string memory benefitType) external onlyOwner {
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