// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RewardActivity {
    enum ActType {
        DEPOSIT,    // 100 * ETH
        WITHDRAW,   // 20
        INVITER,    // 250 // code owner
        INVITEE,    // 500 // code user
        GEN_CODE,   // 50
        DAILY,      // 20
        THRONE,     // 100
        USURP       // 200
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
    uint16 private _gen_code_rate;
    uint16 private _daily_rate;
    uint16 private _throne_rate;
    uint16 private _usurp_rate;

    struct ActVals {
        uint timestamp;
        ActType act_type;
        int tor_changes;
        uint tor_balance;
        uint activity_points;
        uint deposit_points;
        uint total_points;
    } 

    mapping(address account => ActVals[]) private activity_history;


    constructor() {
        _owner = msg.sender;

        _deposit_rate = 100;
        _withdraw_rate = 20;
        _inviter_rate = 250;
        _invitee_rate = 500;
        _gen_code_rate = 50;
        _daily_rate = 20;
        _throne_rate = 100;
        _usurp_rate = 200;
    }

    modifier onlyOwner(){
        require(msg.sender == _owner, "You are not the owner");
        _;
    }

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
        return [_deposit_rate, _withdraw_rate, _inviter_rate, _invitee_rate, _gen_code_rate, _daily_rate, _throne_rate, _usurp_rate];
        // return reward_rates;
    }

    function setRewardRate(ActType act_type, uint16 rate_value) onlyOwner public {
        if (act_type == ActType.DEPOSIT)        _deposit_rate = rate_value;
        else if (act_type == ActType.WITHDRAW)  _withdraw_rate = rate_value;
        else if (act_type == ActType.INVITER)   _inviter_rate = rate_value;
        else if (act_type == ActType.INVITEE)   _invitee_rate = rate_value;
        else if (act_type == ActType.GEN_CODE)  _gen_code_rate = rate_value;
        else if (act_type == ActType.DAILY)     _daily_rate = rate_value;
        else if (act_type == ActType.THRONE)    _throne_rate = rate_value;
        else if (act_type == ActType.USURP)     _usurp_rate = rate_value;
        
        // reward_rates[act_type] = rate_value;
    }

    function checkDuplicateCheckIn(address account) public view returns (bool) {
        uint _today = block.timestamp / _seconds_per_day;
        uint _act_day;
        ActVals[] memory _my_acts = activity_history[account];
        uint activity_len = _my_acts.length;
        
        for (uint i=activity_len; i > 0; --i) {
            _act_day = _my_acts[i-1].timestamp / _seconds_per_day;
            if (_act_day == _today) { // history is today
                if (_my_acts[i-1].act_type == ActType.DAILY) { // act_type is daily check in
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
        uint activity_points = _daily_rate * (10 ** _decimal);
        uint deposit_points = _holdTorPoint(_timestamp, _last_act.timestamp, _last_act.tor_balance);
        uint total_points = _last_act.total_points + activity_points + deposit_points;

        activity_history[account].push(
            ActVals(
          block.timestamp, 
            ActType.DAILY, 
            0, 
            _last_act.tor_balance, 
            activity_points, 
            deposit_points, 
            total_points));
    }

    function _AllActivity(
        address account,
        uint timestamp,
        ActType act_type,
        int tor_changes,
        uint tor_balance
    ) private {
        ActVals memory _last_act = _getLastAct(account, timestamp);

        uint activity_points;
        if (act_type == ActType.DEPOSIT) { // for DEPOSIT, "tor_change" include 10**18 unit already
            activity_points = uint(tor_changes/5000) * _deposit_rate;
        } else { 
            activity_points = (10 ** _decimal); // except DEPOSIT, need 10**18 unit for rate calculate
            if (act_type == ActType.WITHDRAW) {
                activity_points *= _withdraw_rate;
            } else { // except DEPOSIT and WITHDRAW, tor is not change. keep balance
                tor_changes = 0;
                tor_balance = _last_act.tor_balance;
                if (act_type == ActType.INVITER)        activity_points *= _inviter_rate;
                else if (act_type == ActType.INVITEE)   activity_points *= _invitee_rate;
                else if (act_type == ActType.GEN_CODE)  activity_points *= _gen_code_rate;
                // else if (act_type == ActType.DAILY)     activity_points *= _daily_rate;
                else if (act_type == ActType.THRONE)    activity_points *= _throne_rate;
                else if (act_type == ActType.USURP)     activity_points *= _usurp_rate;
            }
        }

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

    function setDepositActivity(address account, uint timestamp, int tor_changes, uint tor_balance) public {
        _AllActivity(account, timestamp, ActType.DEPOSIT, tor_changes, tor_balance);
    }

    function setWithdrawActivity(address account, uint timestamp, int tor_changes, uint tor_balance) public {
        _AllActivity(account, timestamp, ActType.WITHDRAW, tor_changes, tor_balance);
    }

    function setInviterActivity(address account, uint timestamp) public {
        _AllActivity(account, timestamp, ActType.INVITER, 0, 0);
    }

    function setInviteeActivity(address account, uint timestamp) public {
        _AllActivity(account, timestamp, ActType.INVITEE, 0, 0);
    }

    function setGenCodeActivity(address account, uint timestamp) public {
        _AllActivity(account, timestamp, ActType.GEN_CODE, 0, 0);
    }

    function setThroneActivity(address account, uint timestamp) public {
        _AllActivity(account, timestamp, ActType.THRONE, 0, 0);
    }

    function setUsurpActivity(address account, uint timestamp) public {
        _AllActivity(account, timestamp, ActType.USURP, 0, 0);
    }

    function getHistoryLength(address account) public view returns (uint){
        return activity_history[account].length;
    }

    function getHistory(address account, uint page, uint count_per_page) public view returns (ActVals[] memory){
        ActVals[] memory _my_acts = activity_history[account];
        uint activity_len = _my_acts.length;
        require (activity_len > count_per_page * (page-1), "INVALID_PAGE : no Data in this page");

        if (page == 1 && activity_len <= count_per_page) {
            return _my_acts;
        }
        uint start_index = count_per_page * (page-1);
        uint end_index;
        if (activity_len < count_per_page * page)
            end_index = activity_len;
        else
            end_index = count_per_page * page;

        ActVals[] memory _inpage_acts = new ActVals[](end_index - start_index);
        for (uint i = start_index; i < end_index; ++i)
            _inpage_acts[i-start_index] = _my_acts[i];
        return _inpage_acts;
    }

    function getHistory(address account, uint page) public view returns (ActVals[] memory){
        return getHistory(account, page, 100);
    }

    function getHistory(address account) public view returns (ActVals[] memory){
        return getHistory(account, 1, 100);
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
}


