//SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.21;

import { IERC20 } from "./IERC20.sol";
import { IERC721 } from "./IERC721.sol";
import { IERC1155 } from "./IERC1155.sol";

/// @title EVM assets distributor (Ether, ERC20, ERC721 & ERC1155)
/// @author https://github.com/pooriagg
contract Distributor {
    bool isLock;
    modifier lock() {
        require(isLock == false, "Locked");
        isLock = true;
        _;
        isLock = false;
    }

    function _notZeroRecepients(address[] calldata _recepients) internal virtual view {
        require(_recepients.length > 0, "Invalid array length");
    }
    modifier notZeroRecepients(address[] calldata _recepients) {
        _notZeroRecepients(_recepients);
        _;
    }

    /// @notice disperse ether to any address and even call other smart-contracts funtions.
    /// @dev not only users can send ether to any address but also they can only pass data and call multiple smart-contracts with/without sending ether.
    /// @param _recepients all addresses to send ether.
    /// @param _amounts ether to send to each address.
    /// note "address(0)" is invalid.
    function distributeEther(
        address[] calldata _recepients,
        uint256[] calldata _amounts
    ) external payable lock notZeroRecepients(_recepients) {
        require(_recepients.length == _amounts.length, "Arrays length mismatch");

        uint256 receivedEther = msg.value;

        uint256 totalEther;
        uint length = _recepients.length; 

        for (uint i; i < length; ++i) {
            uint amount = _amounts[i];
            require(amount != 0, "Zero amount");
            
            totalEther += amount;
        }
        require(receivedEther >= totalEther, "Invalid amuont");

        for (uint i; i < length; ++i) {
            address recepient = _recepients[i];
            uint256 amount = _amounts[i];

            require(recepient != address(0), "Invalid address");

            (bool result, ) = recepient.call{value: amount}("");
            require(result == true, "Failed to send");            
        }

        if (receivedEther > totalEther) {
            uint256 refund = receivedEther - totalEther;
            payable(msg.sender).transfer(refund);
        }
    }

    /// @notice distribute erc20 tokens to other addresses from a single erc20 smart-contract
    /// @param _token erc20 smart-contract address
    /// @param _recepients addresses to send the token
    /// @param _amounts amounts to send to each of recepient
    function distributeSingleERC20Token(
        IERC20 _token,
        address[] calldata _recepients,
        uint256[] calldata _amounts
    ) external lock notZeroRecepients(_recepients) {
        require(_recepients.length == _amounts.length, "Arrays length mismatch");

        uint256 totalTokens;
        uint length = _recepients.length;

        for (uint i; i < length; ++i) {
            totalTokens += _amounts[i];
        }

        _token.transferFrom(msg.sender, address(this), totalTokens);

        for (uint i; i < length; ++i) {
            address recepient = _recepients[i];
            uint256 amount = _amounts[i];

            _token.transfer(recepient, amount);
        }
    }

    /// @notice distribute erc20 tokens to other addresses from multiple erc20 smart-contracts
    /// @param _tokens erc20 smart-contracts addresses
    /// @param _recepients addresses to send the token
    /// @param _amounts amounts to send to each of recepient
    function distributeMultipleERC20Token(
        IERC20[] calldata _tokens,
        address[] calldata _recepients,
        uint256[] calldata _amounts
    ) external lock notZeroRecepients(_recepients) {
        require(_recepients.length == _amounts.length, "Arrays length mismatch - 1");
        require(_amounts.length == _tokens.length, "Arrays length mismatch - 2");

        address caller = msg.sender;
        
        uint length = _recepients.length;

        for (uint i; i < length; ++i) {
            address recepient = _recepients[i];
            uint256 amount = _amounts[i];
            IERC20 token = _tokens[i];

            token.transferFrom(caller, address(this), amount);

            token.transfer(recepient, amount);
        }
    }

    /// @notice distribute nfts from single erc721 smart-contract to the other recepients
    /// @param _nftToken address of the specific erc721 nft's smart-contract
    /// @param _recepients addresses to send the nfts
    /// @param _tokenIds ids of nfts to send to the specific of recepient
    function distributeSingleERC721NftCollection(
        IERC721 _nftToken,
        address[] calldata _recepients,
        uint256[] calldata _tokenIds
    ) external lock notZeroRecepients(_recepients) {
        require(_recepients.length == _tokenIds.length, "Array length mismatch");

        uint length = _recepients.length;

        for (uint i; i < length; ++i) {
            address recepient = _recepients[i];
            uint256 tokenId = _tokenIds[i];
            
            _nftToken.safeTransferFrom(msg.sender, recepient, tokenId);
        }
    }

    /// @notice distribute nfts from single erc721 smart-contracts to the other recepients
    /// @param _nftTokens addresses of the specific erc721 nft's smart-contracts
    /// @param _recepients addresses to send the nfts
    /// @param _tokenIds ids of nfts to send to the specific of recepient
    function distributeMultipleERC721NftCollections(
        IERC721[] calldata _nftTokens,
        address[] calldata _recepients,
        uint256[] calldata _tokenIds
    ) external lock notZeroRecepients(_recepients) {
        require(_recepients.length == _tokenIds.length, "Array length mismatch - 1");
        require(_tokenIds.length == _nftTokens.length, "Array length mismatch - 2");

        uint length = _recepients.length;

        for (uint i; i < length; ++i) {
            address recepient = _recepients[i];
            uint256 tokenId = _tokenIds[i];
            IERC721 nftToken = _nftTokens[i];
            
            nftToken.safeTransferFrom(msg.sender, recepient, tokenId);
        }
    }

    /// @notice send multiple erc1155 nfts from a single erc1155 smart-contract to other recepients
    /// @param _nftToken address of the erc1155 smart-contract
    /// @param _recepients addresses to distribute the nfts
    /// @param _tokensData data of each nft token to sent to the each recepient address
    /// note example for '_tokensData' parameter => [[1, 25], [5, 3], ...] --meaning-> `[tokenId, tokenAmount]` - [1, 25], send '25' amount of nft with token-id '1' 
    /// @param _data arbitrary data to sent to the nft smart-contract in each token transfer
    function distributeSingleERC1155NFTCollection(
        IERC1155 _nftToken,
        address[] calldata _recepients,
        uint256[2][] calldata _tokensData,
        bytes[] calldata _data
    ) external lock notZeroRecepients(_recepients) {
        require(_recepients.length == _tokensData.length, "Array length mismatch - 1");
        require(_tokensData.length == _data.length, "Array length mismatch - 2");

        uint length = _recepients.length;

        for (uint i; i < length; ++i) {
            address recepient = _recepients[i];
            uint256 tokenId = _tokensData[i][0];
            uint256 tokenAmount = _tokensData[i][1];
            bytes memory data = _data[i];

            _nftToken.safeTransferFrom({
                _from: msg.sender,
                _to: recepient,
                _id: tokenId,
                _value: tokenAmount,
                _data: data
            });
        }
    }
}
