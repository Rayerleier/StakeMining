pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract ESRNTToken is ERC20Permit {
    string private _name = "ESRNTToken";
    string private _symbol = "ESRNT";

    struct LockAmount {
        uint256 amount;
        uint256 lockTime;
    }
    constructor() ERC20Permit(_name) ERC20(_name, _symbol) {}

    mapping(address => LockAmount[]) public LockAmountOf;

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
        LockAmount memory lockamount = LockAmount(
            _amount,
            block.timestamp + 30 days
        );
        LockAmountOf[_to].push(lockamount);
    }

    function transfer(
        address to,
        uint256 value
    ) public pure override returns (bool) {
        return false;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public pure override returns (bool) {
        return false;
    }

    function balanceOfLockedAndUnlock(
        address user
    ) public returns (uint256, uint256) {
        uint256 unlock;
        uint256 locked;
        for (uint256 i = 0; i < LockAmountOf[user].length; i++) {
            LockAmount memory lockamount = LockAmountOf[user][i];
            if (lockamount.lockTime <= block.timestamp) {
                unlock += lockamount.amount;
            } else {
                uint256 remainDay = ((lockamount.lockTime - block.timestamp) /
                    uint256(1 days));

                locked += (lockamount.amount * (30 - remainDay)) / 30; // 30天才可以全取出，剩下的得burn掉
            }
        }

        return (unlock, locked);
    }

    function burn(address user, bool burnAll) external {
        if (!burnAll) {
            for (uint256 i = 0; i < LockAmountOf[user].length; i++) {
                LockAmount memory lockamount = LockAmountOf[user][i];
                if (lockamount.lockTime > block.timestamp) {
                    deleteArray(user, i);
                }
            }
        } else {
            delete LockAmountOf[user];
        }
    }

    function deleteArray(address user, uint256 index) internal {
        uint256 lastElement = LockAmountOf[user].length - 1;
        LockAmountOf[user][index] = LockAmountOf[user][lastElement];
        delete LockAmountOf[user][lastElement];
    }
}
