pragma solidity ^0.8.0;


import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract RNTToken is ERC20Permit, Ownable{

    string private _name = "RNTToken";
    string private _symbol = "RNT";
    uint256 private _totalSupply = 2000_000_000 * 1e18;

    constructor()ERC20Permit(_name)ERC20(_name,_symbol)Ownable(msg.sender){
        _mint(msg.sender, _totalSupply);
    }

    function mint(address to, uint256 amount)external onlyOwner {
        _mint(to, amount);
    }

    
}