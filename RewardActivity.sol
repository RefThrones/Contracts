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
    uint8 private constant _decimal = 18;
    uint private constant _seconds_per_day = 24*60*60;
    uint private constant _history_per_page = 100;
    address private immutable _owner;

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

    mapping(address account => ActVals[]) public activity_history;


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

    modifier onlyOwner(){
        require(msg.sender == _owner, "You are not the owner");
        _;
    }

    function _updateHistory(address account, ActVals memory actvals) private {
        // ActVals(timestamp, act_type, tor_changes, tor_balance, activity_points, deposit_points, total_points)
        activity_history[account].push(actvals);
        // ActVals[] storage _my_activities = activity_history[account];
        // _my_activities.push(actvals);
        // activity_history[account] = _my_activities;
    }

    event DebugNum(address indexed account, uint256 a, uint256 b);
    event DebugMsg(address indexed account, string str);

    function _getLastAct(address account, uint timestamp) private view returns (ActVals memory) {
        ActVals[] memory _my_acts = activity_history[account];
        if (_my_acts.length > 0)
            return _my_acts[_my_acts.length-1];
        else
            return ActVals(timestamp,ActType.DEPOSIT,0,0,0,0,0);
    }

    function _holdTorPoint(uint timestamp1, uint timestamp2, uint tor_balance) private pure returns (uint) {
        return (timestamp1 - timestamp2) * tor_balance / 2000000; // * 0.0000005 // 216 point per tor,hour
    }

    function getRewardRates() public view onlyOwner returns (uint16[8] memory) {
        return [_deposit_rate, _withdraw_rate, _inviter_rate, _invitee_rate, _create_code_rate, _daily_rate, _throne_rate, _usurp_rate];
        // return reward_rates;
    }

    function setRewardRate(ActType act_type, uint16 rate_value) onlyOwner public {
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

    function checkDuplicateCheckIn(address account) public view returns (bool) {
        uint _today = block.timestamp / _seconds_per_day;
        uint _act_day;
        ActVals[] memory _my_activities = activity_history[account];
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

    function doDailyCheckIn() public{
        address account = msg.sender;
        require(!checkDuplicateCheckIn(account), "Already Checked-in");
        uint _timestamp = block.timestamp;
        ActVals memory _last_act = _getLastAct(account, _timestamp);
        uint deposit_points = _holdTorPoint(_timestamp, _last_act.timestamp, _last_act.tor_balance);
        uint total_points = _last_act.total_points + _daily_rate * (10 ** _decimal) + deposit_points;

        ActVals memory _new_act = ActVals(
            block.timestamp, 
            ActType.DAILY, 
            0, 
            _last_act.tor_balance, 
            _daily_rate, 
            deposit_points, 
            total_points);
        _updateHistory(account, _new_act);
    }

    function logActivity(
        address account,
        uint timestamp,
        ActType act_type,
        uint tor_changes,
        uint tor_balance,
        uint eth_changes
    ) public {
        uint activity_points;
        if (act_type == ActType.DEPOSIT)            activity_points = eth_changes * _deposit_rate;
        else if (act_type == ActType.WITHDRAW)      activity_points = (10 ** _decimal) * _withdraw_rate;
        else if (act_type == ActType.INVITER)       activity_points = (10 ** _decimal) * _inviter_rate;
        else if (act_type == ActType.INVITEE)       activity_points = (10 ** _decimal) * _invitee_rate;
        else if (act_type == ActType.CREATE_CODE)   activity_points = (10 ** _decimal) * _create_code_rate;
        else if (act_type == ActType.DAILY)         activity_points = (10 ** _decimal) * _daily_rate;
        else if (act_type == ActType.THRONE)        activity_points = (10 ** _decimal) * _throne_rate;
        else if (act_type == ActType.USURP)         activity_points = (10 ** _decimal) * _usurp_rate;

        ActVals memory _last_act = _getLastAct(account, timestamp);
        uint deposit_points = _holdTorPoint(timestamp, _last_act.timestamp, _last_act.tor_balance);
        uint total_points = _last_act.total_points + activity_points + deposit_points;

        activity_history[account].push(
            ActVals(
                timestamp, 
                act_type, 
                tor_changes, 
                tor_balance, 
                activity_points, 
                deposit_points, 
                total_points));
    }

    function getHistory(address account, uint page) public view returns (ActVals[] memory){

    }

    function getOwner() public view returns (address) {
        return _owner;
    }
}


