// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOwnerGroupContract {

    function isOwner(address ownerAddress) external view returns (bool);
    function isAdmin(address adminAddress) external view returns (bool);
    function getOwnerCount() external view returns (uint);
    function getAdminCount() external view returns (uint);
    function isTrustedContract(address contractAddress) external view returns (bool);
    function registerTrustedContract(address contractAddress) external view;
    function unRegisterContract(address contractAddress) external view;

}