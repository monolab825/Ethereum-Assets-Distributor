//SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.21;

interface IERC1155 {
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;
}