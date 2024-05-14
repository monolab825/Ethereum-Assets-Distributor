//SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.21;

interface IERC721 {
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}