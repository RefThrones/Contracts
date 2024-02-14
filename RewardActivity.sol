// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RewardActivity {
    enum ActType {
        DEPOSIT,        // 100 * ETH
        WITHDRAW,       // 20
        INVITER,        // 250 // code owner
        INVITEE,        // 500 // code user
        CREATE_CODE,    // 50
        DAILY,          // 20
        THRONE,         // 100
        USURP           // 200
    }

    // uint[] public reward_rates;
    uint8 private _decimal=18;
    uint private _seconds_per_day=24*60*60;
    address private _owner;

    uint16 private _deposit_rate;
    uint16 private _withdraw_rate;
    uint16 private _inviter_rate;
    uint16 private _invitee_rate;
    uint16 private _create_code_rate;
    uint16 private _daily_rate;
    uint16 private _throne_rate;
    uint16 private _usurp_rate;

    struct ActVals {
        uint timestamp;
        ActType act_type;
        uint tor_changes;
        uint tor_balance;
        uint activity_points;
        uint deposit_points;
        uint total_points;
    } 

    mapping(address account => ActVals[]) private _activity_history;


    constructor() {
        // reward_rates[uint256(ActType.DEPOSIT)] = 100;
        // reward_rates[uint256(ActType.WITHDRAW)] = 20;
        // reward_rates[uint256(ActType.INVITER)] = 250;
        // reward_rates[uint256(ActType.INVITEE)] = 500;
        // reward_rates[uint256(ActType.CREATE_CODE)] = 50;
        // reward_rates[uint256(ActType.DAILY)] = 20;
        // reward_rates[uint256(ActType.THRONE)] = 100;
        // reward_rates[uint256(ActType.USURP)] = 200;

        // reward_rates[0] = 100;
        // reward_rates[1] = 20;
        // reward_rates[2] = 250;
        // reward_rates[3] = 500;
        // reward_rates[4] = 50;
        // reward_rates[5] = 20;
        // reward_rates[6] = 100;
        // reward_rates[7] = 200;
        _owner = msg.sender;

        _deposit_rate = 100;
        _withdraw_rate = 20;
        _inviter_rate = 250;
        _invitee_rate = 500;
        _create_code_rate = 50;
        _daily_rate = 20;
        _throne_rate = 100;
        _usurp_rate = 200;
    }

    function getRewardRates() public view returns (uint16[8] memory) {
        return [_deposit_rate, _withdraw_rate, _inviter_rate, _invitee_rate, _create_code_rate, _daily_rate, _throne_rate, _usurp_rate];
        // return reward_rates;
    }

    function setRewardRate(ActType act_type, uint16 rate_value) public {
        if (act_type == ActType.DEPOSIT) _deposit_rate = rate_value;
        else if (act_type == ActType.WITHDRAW) _withdraw_rate = rate_value;
        else if (act_type == ActType.INVITER) _inviter_rate = rate_value;
        else if (act_type == ActType.INVITEE) _invitee_rate = rate_value;
        else if (act_type == ActType.CREATE_CODE) _create_code_rate = rate_value;
        else if (act_type == ActType.DAILY) _daily_rate = rate_value;
        else if (act_type == ActType.THRONE) _throne_rate = rate_value;
        else if (act_type == ActType.USURP) _usurp_rate = rate_value;
        
        // reward_rates[act_type] = rate_value;

    }

    event DebugMsg(address indexed account, uint256 a, uint256 b);

    function debugCheckIn(address account) public view returns (uint) {
        ActVals[] memory _my_activities = _activity_history[account];
        uint activity_len = _my_activities.length;
        uint count = 0;
        for (uint i=activity_len; i > 0; --i) {
            ++count;
        }
        return count;
    }

    function isCheckIn(address account) public view returns (bool) {
        uint _today = block.timestamp / _seconds_per_day;
        uint _act_day;
        ActVals[] memory _my_activities = _activity_history[account];
        uint activity_len = _my_activities.length;
        
        for (uint i=activity_len; i > 0; --i) {
            _act_day = _my_activities[i-1].timestamp / _seconds_per_day;
            if (_act_day == _today) { // history is today
                if (_my_activities[i-1].act_type == ActType.DAILY) { // act_type is daily check in
                    return true;
                }
            } else {
                break; // no more history today, not check in today
            }
        }
        return false;
    }

    function dailyCheckIn() public {
        
    }

    function logActivity(
        address account,
        uint timestamp,
        ActType act_type,
        uint tor_changes,
        uint tor_balance
    ) public {
        uint activity_points;
        uint deposit_points;
        uint total_points;

        ActVals[] storage _my_activities = _activity_history[account];
        _my_activities.push(ActVals(timestamp, act_type, tor_changes, tor_balance, activity_points, deposit_points, total_points));
        _activity_history[account] = _my_activities;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

}


