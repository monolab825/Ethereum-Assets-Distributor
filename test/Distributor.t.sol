// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { Distributor, IERC20, IERC721 } from "../src/Distributor.sol";
import { Token } from "../src/ERC20.sol";
import { NFT } from "../src/ERC721.sol";
import { SimpleStorage } from "../src/SimpleStorage.sol";

contract DistributorTest is Test {
    Distributor public distributor;
    Token public usdt;
    Token public dai;
    NFT public nft;
    NFT public nft_2;
    SimpleStorage public simpleStorage;

    function setUp() external {
        distributor = new Distributor();
        usdt = new Token("Tether", "USDT", 6, 1000000 * 1e6);
        dai = new Token("Dai", "DAI", 6, 1000000 * 1e6);
        nft = new NFT("Test NFT", "TNF", "Test NFT collection");
        nft_2 = new NFT("Test-2 NFT", "TN2", "Test-2 NFT collection");
        simpleStorage = new SimpleStorage();
    }

    function testDistributeEther_And_Refud_Successfully() external {
        hoax(address(10), 10 * 1e18);

        address[] memory addrs = new address[](3);
        addrs[0] = address(11);
        addrs[1] = address(12);
        addrs[2] = address(13);

        uint[] memory amounts = new uint[](3);
        amounts[0] = 1 * 1e18;
        amounts[1] = 2 * 1e18;
        amounts[2] = 3 * 1e18;

        distributor.distributeEther{value: 7 ether}(
            addrs,
            amounts
        );
        
        assertEq(address(10).balance, 4 * 1e18, "Checking address(1) balance - sender");
        assertEq(address(11).balance, 1 * 1e18, "Checking address(2) balance");
        assertEq(address(12).balance, 2 * 1e18, "Checking address(3) balance");
        assertEq(address(13).balance, 3 * 1e18, "Checking address(4) balance");
    }

    function testDistributeEther_For_Insufficent_Fund_Error() external {
        vm.prank(address(10));

        address[] memory addrs = new address[](2);
        addrs[0] = address(11);
        addrs[1] = address(12);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2 * 1e18;
        amounts[1] = 3 * 1e18;

        vm.expectRevert(bytes("Invalid ether amuont"));

        distributor.distributeEther{value: 0 ether}(
            addrs,
            amounts
        );
    }

    function testDistributeEther_For_Array_Length_Mismatch_Error() external {
        hoax(address(10), 1 * 1e18);

        address[] memory addrs = new address[](1);
        addrs[0] = address(11);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2 * 1e18;
        amounts[1] = 3 * 1e18;

        vm.expectRevert(bytes("Arrays length mismatch"));

        distributor.distributeEther{value: 1 ether}(
            addrs,
            amounts
        );
    }

    function testDistributeEther_For_Invalid_Address_Error() external {
        hoax(address(10), 5 * 1e18);

        address[] memory addrs = new address[](2);
        addrs[0] = address(0);
        addrs[1] = address(11);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2 * 1e18;
        amounts[1] = 3 * 1e18;

        vm.expectRevert(bytes("Invalid address"));

        distributor.distributeEther{value: 5 ether}(
            addrs,
            amounts
        );
    }

    function testDistributeEther_For_Invalid_Amount_Error() external {
        hoax(address(10), 5 * 1e18);

        address[] memory addrs = new address[](2);
        addrs[0] = address(11);
        addrs[1] = address(12);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2 * 1e18;
        amounts[1] = 0 * 1e18;

        vm.expectRevert(bytes("Invalid amount"));

        distributor.distributeEther{value: 2 ether}(
            addrs,
            amounts
        );
    }

    function testDistributeEther_For_Invalid_SmartContract_Address_That_Does_Not_Have_Payable_Funtion_Error() external {
        hoax(address(10), 5 * 1e18);

        address[] memory addrs = new address[](2);
        addrs[0] = address(11);
        addrs[1] = address(simpleStorage);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2 * 1e18;
        amounts[1] = 1 * 1e18;

        vm.expectRevert(bytes("Failed to send ether"));

        distributor.distributeEther{value: 3 ether}(
            addrs,
            amounts
        );
    }

    function testDistributeSingleERC20Token() external {
        usdt.transfer(address(10), 100 * 1e6);

        address[] memory addrs = new address[](2);
        addrs[0] = address(11);
        addrs[1] = address(12);

        uint[] memory amounts = new uint[](2);
        amounts[0] = 20 * 1e6;
        amounts[1] = 30 * 1e6;

        vm.startPrank(address(10));
        
        usdt.approve(address(distributor), 50 * 1e6);

        distributor.distributeSingleERC20Token({
            _token: IERC20(address(usdt)),
            _recepients: addrs,
            _amounts: amounts
        });

        vm.stopPrank();

        uint balance_address_11 = usdt.balanceOf(address(11));
        uint balance_address_12 = usdt.balanceOf(address(12));
        uint balance_address_10 = usdt.balanceOf(address(10));

        assertEq(balance_address_11, 20e6, "checking balance address(11)");
        assertEq(balance_address_12, 30e6, "checking balance address(12)");
        assertEq(balance_address_10, 50e6, "checking balance address(10)");
    }

    function testDistributeSingleERC20Token_For_Array_Length_Mismath_Error() external {
        usdt.transfer(address(10), 100 * 1e6);

        address[] memory addrs = new address[](2);
        addrs[0] = address(11);
        addrs[1] = address(12);

        uint[] memory amounts = new uint[](1);
        amounts[0] = 50 * 1e6;

        vm.startPrank(address(10));

        usdt.approve(address(distributor), 50 * 1e6);

        vm.expectRevert(bytes("Arrays length mismatch"));

        distributor.distributeSingleERC20Token({
            _token: IERC20(address(usdt)),
            _amounts: amounts,
            _recepients: addrs
        });
    }

    function testDistributeMultipleERC20Tokens() external {
        usdt.transfer(address(10), 100 * 1e6);
        dai.transfer(address(10), 50 * 1e6);

        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = IERC20(address(usdt));
        tokens[1] = IERC20(address(dai));

        address[] memory addrs = new address[](2);
        addrs[0] = address(11);
        addrs[1] = address(12);

        uint[] memory amounts = new uint[](2);
        amounts[0] = 50 * 1e6;
        amounts[1] = 25 * 1e6;

        vm.startPrank(address(10));

        usdt.approve(address(distributor), 50 * 1e6);
        dai.approve(address(distributor), 25 * 1e6);

        distributor.distributeMultipleERC20Token({
            _tokens: tokens,
            _recepients: addrs,
            _amounts: amounts
        });

        vm.stopPrank();

        uint balance_address_10_usdt = usdt.balanceOf(address(10));
        uint balance_address_10_dai = dai.balanceOf(address(10));
        uint balance_address_11_usdt = usdt.balanceOf(address(11));
        uint balance_address_12_dai = dai.balanceOf(address(12));

        assertEq(balance_address_10_usdt, 50 * 1e6, "checking address(10) - sender, usdt balance");
        assertEq(balance_address_10_dai, 25 * 1e6, "checking address(10) - sender, dai balance");
        assertEq(balance_address_11_usdt, 50 * 1e6, "checking address(11) usdt balance");
        assertEq(balance_address_12_dai, 25 * 1e6, "checking address(12) dai balance");
    }

    function testDistributeSingleERC721Nft() external {
        nft.mint("token-1"); // id=1
        nft.mint("token-2"); // id=2
        nft.mint("token-3"); // id=3
        nft.transferFrom(address(this), address(10), 1);
        nft.transferFrom(address(this), address(10), 2);
        nft.transferFrom(address(this), address(10), 3);

        address[] memory addrs = new address[](3);
        addrs[0] = address(11);
        addrs[1] = address(12);
        addrs[2] = address(13);

        uint[] memory tokenIds = new uint[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        vm.startPrank(address(10));

        nft.setApprovalForAll(address(distributor), true);

        distributor.distributeSingleERC721NftCollection({
            _nftToken: IERC721(address(nft)),
            _recepients: addrs,
            _tokenIds: tokenIds
        });

        vm.stopPrank();

        assertEq(nft.ownerOf(1), address(11), "Checking owner of nft token id 1");
        assertEq(nft.ownerOf(2), address(12), "Checking owner of nft token id 2");
        assertEq(nft.ownerOf(3), address(13), "Checking owner of nft token id 3");
    }

    function testDistributeSingleERC721Nft_For_Array_length_Mismatch_Error() external {
        nft.mint("token-1"); // id=1
        nft.mint("token-2"); // id=2
        nft.transferFrom(address(this), address(10), 1);
        nft.transferFrom(address(this), address(10), 2);

        address[] memory addrs = new address[](3);
        addrs[0] = address(11);
        addrs[1] = address(12);
        addrs[2] = address(13);

        uint[] memory tokenIds = new uint[](32);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        vm.startPrank(address(10));

        nft.setApprovalForAll(address(distributor), true);
        
        vm.expectRevert(bytes("Array mismatch"));

        distributor.distributeSingleERC721NftCollection({
            _nftToken: IERC721(address(nft)),
            _recepients: addrs,
            _tokenIds: tokenIds
        });
    }

    function testDistributeMultipleERC721Nft() external {
        nft.mint("token-1"); // id:=1
        nft.mint("token-2"); // id:=2
        nft_2.mint("token-1"); // id:=1
        nft.transferFrom(address(this), address(10), 1);
        nft.transferFrom(address(this), address(10), 2);
        nft_2.transferFrom(address(this), address(10), 1);

        IERC721[] memory nfts = new IERC721[](3);
        nfts[0] = IERC721(address(nft));
        nfts[1] = IERC721(address(nft));
        nfts[2] = IERC721(address(nft_2));

        address[] memory addrs = new address[](3);
        addrs[0] = address(11);
        addrs[1] = address(12);
        addrs[2] = address(13);

        uint[] memory tokenIds = new uint[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 1;

        vm.startPrank(address(10));

        nft.setApprovalForAll(address(distributor), true);
        nft_2.setApprovalForAll(address(distributor), true);

        distributor.distributeMultipleERC721NftCollections({
            _nftTokens: nfts,
            _recepients: addrs,
            _tokenIds: tokenIds
        });

        vm.stopPrank();

        assertEq(nft.ownerOf(1), address(11), "Checking owner of nft token id 1 - nft");
        assertEq(nft.ownerOf(2), address(12), "Checking owner of nft token id 2 - nft");
        assertEq(nft_2.ownerOf(1), address(13), "Checking owner of nft token id 1 - nft_2");
    }
}