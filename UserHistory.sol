// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IUserHistory.sol";

contract UserHistory is IUserHistory, Ownable {
    uint8 private constant _decimal = 18;
    uint private constant _seconds_per_day = 24*60*60;
    uint private constant _history_per_page = 100;

    mapping(address whitelist => bool) private whitelist_mapping;
    address[] private whitelist_list;

    uint16 private _deposit_rate;
    uint16 private _withdraw_rate;
    uint16 private _inviter_rate;
    uint16 private _invitee_rate;
    uint16 private _gen_code_rate;
    uint16 private _daily_rate;
    uint16 private _throne_rate;
    uint16 private _usurp_rate;

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

    struct ActVals {
        uint timestamp;
        ActType act_type;
        uint256 tor_changes;
        uint256 tor_balance;
        uint256 count_invitee;
        uint256 activity_points;
        uint256 deposit_points;
        uint256 total_points;
    } 

    struct RankVals {
        address account;
        uint timestamp;
        uint256 point;
    } 

    mapping(address => ActVals[]) private activity_history;
    mapping(address => ActVals)   private activity_lastval;
    RankVals[] private _rank;
    mapping(address => uint)      private _my_rank;

    constructor() Ownable(msg.sender)  {
        _deposit_rate = 100;
        _withdraw_rate = 20;
        _inviter_rate = 250;
        _invitee_rate = 500;
        _gen_code_rate = 50;
        _daily_rate = 20;
        _throne_rate = 100;
        _usurp_rate = 200;
    }

    modifier onlyTorContract(){
        // tx.origin != msg.sender
        // require(whitelist_mapping[msg.sender], "You are not the RefThrone Contract.");
        _;
    }

    function _getLastAct(address account, uint timestamp) private view returns (ActVals memory) {
        ActVals memory _my_acts = activity_lastval[account];
        if (_my_acts.timestamp != 0)
            return _my_acts;
        else
            return ActVals(timestamp,ActType.DEPOSIT,0,0,0,0,0,0);
    }

    function _holdTorPoint(uint timestamp1, uint timestamp2, uint tor_balance) private pure returns (uint) {
        return (timestamp1 - timestamp2) * tor_balance / 2000000; // * 0.0000005 // 216 point per tor,hour
    }

    function _calcRank(address account) private {
        ActVals memory _my_acts = activity_lastval[account];
        RankVals memory _temp_val;
        uint last_rank = _my_rank[account]; // if I have ranking, start from my rank.
        if (last_rank == 0) {// if not, start last rank
            if (_rank.length < 200) {
                _my_rank[account] = _rank.length+1;
                _rank.push(RankVals(account, _my_acts.timestamp, _my_acts.total_points));
            }
            last_rank = _rank.length;
        }
        else {
            _rank[last_rank-1] = RankVals(account, _my_acts.timestamp, _my_acts.total_points);
        }

        for (uint i = last_rank - 1; i > 0; --i) {
            if (_rank[i-1].point < _rank[i].point) {
                _temp_val = _rank[i];
                _rank[i] = _rank[i-1];
                _rank[i-1] = _temp_val;
                _my_rank[_rank[i-1].account] = i;
                _my_rank[_rank[i].account] = i+1;
            } else {
                break;
            }
        }
    }

    function getRank() public view returns (RankVals[] memory) {
        return _rank;
    }

    function getMyRank(address account) public view returns (uint) {
        return _my_rank[account];
    }

    function getMyRank() public view returns (uint) {
        return _my_rank[msg.sender];
    }

    function getLastHistory(address account) public view returns (ActVals memory) {
        return activity_lastval[account];
    }

    function getRewardRates() public view onlyOwner returns (uint16[8] memory) {
        return [_deposit_rate, _withdraw_rate, _inviter_rate, _invitee_rate, _gen_code_rate, _daily_rate, _throne_rate, _usurp_rate];
        // return reward_rates;
    }

    function setRewardRate(ActType act_type, uint16 rate_value) public onlyOwner {
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

    function setWhiteListContract(address ref_contract) public onlyOwner {
        whitelist_mapping[ref_contract] = true;
        whitelist_list.push(ref_contract);
    }

    function getWhiteListContract() public view onlyOwner returns(address[] memory) {
        return whitelist_list;
    }

    function checkDuplicateCheckIn(address account) public view returns (bool) {
        uint _today = block.timestamp / _seconds_per_day;
        uint _act_day;
        ActVals[] memory _arr_my_acts = activity_history[account];
        uint activity_len = _arr_my_acts.length;
        
        for (uint i=activity_len; i > 0; --i) {
            _act_day = _arr_my_acts[i-1].timestamp / _seconds_per_day;
            if (_act_day == _today) { // history is today
                if (_arr_my_acts[i-1].act_type == ActType.DAILY) { // act_type is daily check in
                    return true;
                }
            } else {
                break; // no more history today, not check in today
            }
        }
        return false;
    }

    function doDailyCheckIn() public {
        address account = msg.sender;
        require(!checkDuplicateCheckIn(account), "Already Checked-in");
        uint _timestamp = block.timestamp;
        ActVals memory _last_act = _getLastAct(account, _timestamp);
        uint activity_points = _daily_rate * (10 ** _decimal);
        uint deposit_points = _holdTorPoint(_timestamp, _last_act.timestamp, _last_act.tor_balance);
        uint total_points = _last_act.total_points + activity_points + deposit_points;

        ActVals memory _act = ActVals(
            block.timestamp, 
            ActType.DAILY, 
            0, 
            _last_act.tor_balance, 
            _last_act.count_invitee, 
            activity_points, 
            deposit_points, 
            total_points);
        activity_history[account].push(_act);
        activity_lastval[account] = _act;
        _calcRank(account);
    }

    function _AllActivity (
        address account,
        uint timestamp,
        ActType act_type,
        uint256 tor_changes,
        uint256 tor_balance
    ) private {
        ActVals memory _last_act = _getLastAct(account, timestamp);

        uint count_invitee = _last_act.count_invitee;

        uint activity_points;
        if (act_type == ActType.DEPOSIT) { // for DEPOSIT, "tor_change" include 10**18 unit already
            activity_points = (tor_changes/5000) * _deposit_rate;
        } else { 
            activity_points = (10 ** _decimal); // except DEPOSIT, need 10**18 unit for rate calculate
            if (act_type == ActType.WITHDRAW) {
                activity_points *= _withdraw_rate;
            } else { // except DEPOSIT and WITHDRAW, tor is not change. keep balance
                tor_changes = 0;
                tor_balance = _last_act.tor_balance;
                if (act_type == ActType.INVITER)       { activity_points *= _inviter_rate; count_invitee++; }
                else if (act_type == ActType.INVITEE)  { activity_points *= _invitee_rate; }
                else if (act_type == ActType.GEN_CODE) { activity_points *= _gen_code_rate; }
                // else if (act_type == ActType.DAILY)    { activity_points *= _daily_rate; }
                else if (act_type == ActType.THRONE)   { activity_points *= _throne_rate; }
                else if (act_type == ActType.USURP)    { activity_points *= _usurp_rate; }
            }
        }

        uint deposit_points = _holdTorPoint(timestamp, _last_act.timestamp, _last_act.tor_balance);
        uint total_points = _last_act.total_points + activity_points + deposit_points;

        ActVals memory _act = ActVals(
            timestamp, 
            act_type, 
            tor_changes, 
            tor_balance, 
            count_invitee, 
            activity_points, 
            deposit_points, 
            total_points);
        activity_history[account].push(_act);
        activity_lastval[account] = _act;
        _calcRank(account);
    }

    function setDepositActivity(address account, uint timestamp, uint256 tor_changes, uint256 tor_balance) external onlyTorContract {
        _AllActivity(account, timestamp, ActType.DEPOSIT, tor_changes, tor_balance);
    }

    function setWithdrawActivity(address account, uint timestamp, uint256 tor_changes, uint256 tor_balance) external onlyTorContract {
        _AllActivity(account, timestamp, ActType.WITHDRAW, tor_changes, tor_balance);
    }

    function setInviterActivity(address account, uint timestamp) external onlyTorContract {
        _AllActivity(account, timestamp, ActType.INVITER, 0, 0);
    }

    function setInviteeActivity(address account, uint timestamp) external onlyTorContract {
        _AllActivity(account, timestamp, ActType.INVITEE, 0, 0);
    }

    function setGenCodeActivity(address account, uint timestamp) external onlyTorContract {
        _AllActivity(account, timestamp, ActType.GEN_CODE, 0, 0);
    }

    function setThroneActivity(address account, uint timestamp) external onlyTorContract {
        _AllActivity(account, timestamp, ActType.THRONE, 0, 0);
    }

    function setUsurpActivity(address account, uint timestamp) external onlyTorContract {
        _AllActivity(account, timestamp, ActType.USURP, 0, 0);
    }

    function getHistoryLength(address account) public view returns (uint){
        return activity_history[account].length;
    }

    function getHistory(address account, uint page, uint count_per_page) public view returns (ActVals[] memory){
        ActVals[] memory _arr_my_acts = activity_history[account];
        uint activity_len = _arr_my_acts.length;
        require (activity_len > 0, "NO_DATA");
        require (activity_len > count_per_page * (page-1), "INVALID_PAGE : no Data in this page");

        uint start_index;
        uint end_index;

        start_index = activity_len - (count_per_page * (page - 1));
        if (start_index <= count_per_page)
            end_index = 0;
        else
            end_index = start_index - count_per_page;

        ActVals[] memory _inpage_acts = new ActVals[](start_index - end_index);
        for (uint i = start_index; i > end_index; --i)
            _inpage_acts[start_index-i] = _arr_my_acts[i-1];
        return _inpage_acts;
    }

    function getHistory(address account, uint page) public view returns (ActVals[] memory){
        return getHistory(account, page, 100);
    }

    function getHistory(address account) public view returns (ActVals[] memory){
        return getHistory(account, 1, 100);
    }
}


