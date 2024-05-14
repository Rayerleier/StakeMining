pragma solidity ^0.8.0;

import "./RNTToken.sol";
import "./ESRNTToken.sol";
import "./interface/IStake.sol";
// import "../lib/openzeppelin-contracts/contracts/utils/Nonces.sol";

contract RNTStake is IStake {
    RNTToken immutable rnttoken;
    ESRNTToken immutable esrnttoken;
    mapping(address => Stake) StakeList; // 该用户的第几笔存款
    constructor(address rntCA, address esrntCA) {
        rnttoken = RNTToken(rntCA);
        esrnttoken = ESRNTToken(esrntCA);
    }

    modifier calculate() {
        // 每次有用户调用该函数，计算该用户的每一笔质押所收益的锁定ESRNTToken
        Stake memory stake_cal = StakeList[msg.sender];
        uint256 timeElapsed = (block.timestamp - stake_cal.stakeTime) /uint256(1 days);
        stake_cal.mintableToken += timeElapsed * stake_cal.amount;
        stake_cal.stakeTime = block.timestamp;
        StakeList[msg.sender] = stake_cal;
        _;
    }

    function stake(uint256 RNTAmount) external calculate {
        require(
            rnttoken.balanceOf(msg.sender) >= RNTAmount,
            "Not Enough Amount"
        );
        Stake memory stake1 = StakeList[msg.sender];
        stake1.amount += RNTAmount;
        stake1.stakeTime = block.timestamp;
        StakeList[msg.sender] = stake1;
        rnttoken.transferFrom(msg.sender, address(this), RNTAmount);
        emit EVENTStake(msg.sender, RNTAmount, block.timestamp);
    }

    function unstake(uint256 RNTAmount) external calculate {
        Stake memory stake1 = StakeList[msg.sender];
        require(stake1.amount >= RNTAmount, "Not Enough Stake Amount");
        stake1.amount -= RNTAmount;
        StakeList[msg.sender] = stake1;
        rnttoken.transfer(msg.sender, RNTAmount);
        emit EVENTUnstake(msg.sender, RNTAmount);
    }

    function claim() external calculate {
        require(
            StakeList[msg.sender].mintableToken > 0,
            "Not Any mintableToken"
        );
        uint256 mintableToken = StakeList[msg.sender].mintableToken;
        StakeList[msg.sender].mintableToken = 0;
        esrnttoken.mint(msg.sender, mintableToken);
        emit EVENClaim(msg.sender);
    }

    function exchange(address RNTowner,uint256 ESRNTAmount) external calculate {
        uint256 unlock;
        uint256 locked;
        (unlock, locked) = esrnttoken.balanceOfLockedAndUnlock(msg.sender);
        require(ESRNTAmount <= unlock + locked, "Not Enough esRNTToken.");
        if (ESRNTAmount <= unlock) {
            // 如果解禁的部分足够的话，就只提取解禁的部分
            rnttoken.transferFrom(RNTowner,msg.sender, unlock);
            esrnttoken.burn(msg.sender, false);
            emit EVENTExchange(msg.sender, unlock);
        } else {
            // 如果解禁的部分不够，就全部提取，并燃烧掉需要燃烧的部分
            rnttoken.transferFrom(RNTowner,msg.sender, unlock + locked);
            esrnttoken.burn(msg.sender, true);

            emit EVENTExchange(msg.sender, unlock + locked);
        }
    }

    function amountOfStake(address user)external view returns(uint256) {
        return StakeList[user].amount;
    }

    function mintableTokenOfStake(address user)external view returns(uint256) {
        return StakeList[user].mintableToken;
        
    }
}
