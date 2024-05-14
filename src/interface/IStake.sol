pragma solidity ^0.8.0;


interface IStake{
    
    struct Stake{
        uint256 amount;
        uint256 stakeTime;  // 用于计算收益
        uint256 mintableToken;   
    }

    event EVENTStake(address user,uint256 amount, uint256 stakeTime);
    event EVENClaim(address user);
    event EVENTUnstake(address user, uint256 amount);
    event EVENTExchange(address user, uint256 amount);
}