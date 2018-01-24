pragma solidity ^0.4.17;

contract PolicyInvestable {
  function invest() payable returns (bool success);

  event Invested(uint value);
}