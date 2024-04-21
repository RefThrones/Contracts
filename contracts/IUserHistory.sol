// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUserHistory {

    function setDepositActivity(address account, uint timestamp, uint256 tor_changes, uint256 tor_balance) external;

    function setWithdrawActivity(address account, uint timestamp, uint256 tor_changes, uint256 tor_balance) external;

    function setInviterActivity(address account, uint timestamp) external;

    function setInviteeActivity(address account, uint timestamp) external;

    function setGenCodeActivity(address account, uint timestamp) external;

    function setThroneActivity(address account, uint timestamp) external;

    function setUsurpActivity(address account, uint timestamp) external;

    function setAbandonActivity(address account, uint timestamp) external;
} 