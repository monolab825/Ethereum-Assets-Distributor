//SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.21;

interface IERC20 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns(bool);

    function transfer(
        address _to,
        uint256 _value
    ) external returns(bool);
}