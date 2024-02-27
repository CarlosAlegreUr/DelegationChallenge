// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/Test.sol";
import "../scenarios/nftsMinted-ERC721Delegatable.t.sol";
import {IERCXXX} from "../../src/interfaces/IERCXXX.sol";

contract ERC721DelegatableTest is MintedTokensScenario {
    // @dev MAX_AMOUNT_OF_TOKENS_DELEGATED
    uint256 public AMOUNT = 1;

    address public user1;
    address public user2;
    address public user3;

    function setUp() public virtual override {
        MintedTokensScenario.setUp();
        user1 = _getUser(1);
        user2 = _getUser(2);
        user3 = _getUser(3);
    }

    modifier tokenDelegated(address owner, address delegatee, uint256 tokenId) {
        vm.prank(owner);
        collection.delegateTo(delegatee, tokenId, AMOUNT);
        _;
    }

    //================================================================
    // TESTS
    //================================================================

    // =========== DELEGATE TESTS ===========

    function test_delegateTo_OwnsershipIsPreservedAndEventEmittedAndGettersWork() public {
        assertTrue(collection.ownerOf(1) == user1);
        assertTrue(!(collection.ownerOf(1) == user2));

        vm.expectEmit(true, true, true, true);
        emit Delegated(user1, user2, 721, 1, AMOUNT);

        // User 1 delegates to user 2
        vm.prank(user1);
        collection.delegateTo(user2, 1, AMOUNT);

        assertTrue(collection.ownerOf(1) == user1);
        assertTrue(!(collection.ownerOf(1) == user2));

        // Getters checks
        uint256 delegatorActiveNonce = collection.getDelegatorActiveNonce(user1, 1);
        assertTrue(delegatorActiveNonce == 0);
        assertTrue(collection.getDelegateeActiveNonceOfAsset(user1, 1, user2) == 0);
        assertTrue(collection.getDelegateeAmountOfAssetId(user1, 1, user2, delegatorActiveNonce) == 1);
        assertTrue(collection.getAssetIsDelegatedForDelegator(user1, 1, delegatorActiveNonce));
        assertTrue(collection.getDelegateeOfAssetId(1) == user2);
    }

    function test_delegateTo_OnlyOwnerCanDelegate() public {
        assertTrue(collection.ownerOf(1) == user1);
        assertTrue(!(collection.ownerOf(1) == user2));

        // User 2 delegates an nft which is not its own
        vm.prank(user2);
        vm.expectRevert(bytes("ERCXXX: delegate amount exceeds balance"));
        collection.delegateTo(user1, 1, AMOUNT);
    }

    function test_delegateTo_CantDelegateToYourself() public {
        assertTrue(collection.ownerOf(1) == user1);
        vm.prank(user1);
        vm.expectRevert(bytes("ERCXXX: cant delegate to yourself"));
        collection.delegateTo(user1, 1, AMOUNT);
    }

    function test_delegateTo_CantDelegateToZeroAddres() public {
        vm.prank(user1);
        vm.expectRevert(bytes("ERCXXX: delegate to the zero address"));
        collection.delegateTo(address(0), 1, AMOUNT);
    }

    function test_delegateTo_CantDelegateMoreThanOneOfTheSameNft() public {
        vm.prank(user1);
        vm.expectRevert(bytes("ERCXXX: delegate amount exceeds balance"));
        collection.delegateTo(user2, 1, 2);
    }

    function test_delegateTo_And_IsDelegatee_MarksDlegateeOnlyAfterDelegation() public {
        // Before delegation token 1 is not delegated to user 2
        assertTrue(!collection.isDelegatee(user1, user2, 1, AMOUNT));

        // User 1 delegates to user 2
        vm.prank(user1);
        collection.delegateTo(user2, 1, AMOUNT);

        assertTrue(collection.isDelegatee(user1, user2, 1, AMOUNT));

        // User 1 undelegates from user 2
        vm.prank(user1);
        collection.undelegateFrom(user2, 1, AMOUNT);

        // After undelegation token 1 is not delegated to user 2
        assertTrue(!collection.isDelegatee(user1, user2, 1, AMOUNT));
    }

    function test_isDelegatee_AmountOfZeroMustReturnFalse() public {
        assertTrue(!collection.isDelegatee(user1, user2, 1, 0));

        vm.prank(user1);
        collection.delegateTo(user2, 1, AMOUNT);

        // Even after delegation, amount of zero must return false
        assertTrue(!collection.isDelegatee(user1, user2, 1, 0));

        vm.prank(user1);
        collection.undelegateFrom(user2, 1, AMOUNT);

        assertTrue(!collection.isDelegatee(user1, user2, 1, 0));
        vm.startPrank(user1);
        collection.delegateTo(user2, 1, AMOUNT);
        collection.undelegateFromAll(69);
        vm.stopPrank();
        assertTrue(!collection.isDelegatee(user1, user2, 1, 0));
    }

    function test_delegateTo_YouCantDelegateAnNftMoreThanOnce() public tokenDelegated(user1, user2, 1) {
        // You can't delegate more than once an NFT
        vm.startPrank(user1);

        vm.expectRevert(bytes("ERCXXX: cant delegate to yourself"));
        collection.delegateTo(user1, 1, AMOUNT);

        vm.expectRevert(bytes("ERC721Delegatable: Asset is already delegated"));
        collection.delegateTo(user2, 1, AMOUNT);

        vm.expectRevert(bytes("ERC721Delegatable: Asset is already delegated"));
        collection.delegateTo(user3, 1, AMOUNT);

        vm.stopPrank();
    }

    // =========== UNDELEGATE TESTS ===========

    function test_undelegateFrom_OnlyAsetOwnerCanUndelegateAndGettersWork() public tokenDelegated(user1, user2, 1) {
        // Before undelegation token 1 is delegated to user 2
        assertTrue(collection.isDelegatee(user1, user2, 1, AMOUNT));

        // User 2 undelegates from user 2, user 2 is not owner, should revert
        vm.prank(user2);
        vm.expectRevert(bytes("ERCXXX: undelegate amount exceeds delegated amount"));
        collection.undelegateFrom(user2, 1, AMOUNT);

        // Another person undelegates from delegatee, random person is not owner, should revert
        vm.prank(user3);
        vm.expectRevert(bytes("ERCXXX: undelegate amount exceeds delegated amount"));
        collection.undelegateFrom(user3, 1, AMOUNT);

        // Getters checks
        vm.prank(user1);
        collection.undelegateFrom(user2, 1, AMOUNT);

        uint256 delegatorActiveNonce = collection.getDelegatorActiveNonce(user1, 1);
        assertTrue(delegatorActiveNonce == 0);
        assertTrue(collection.getDelegateeActiveNonceOfAsset(user1, 1, user2) == 0);
        assertTrue(collection.getDelegateeAmountOfAssetId(user1, 1, user2, delegatorActiveNonce) == 0);
        assertTrue(!collection.getAssetIsDelegatedForDelegator(user1, 1, delegatorActiveNonce));
        assertTrue(collection.getDelegateeOfAssetId(1) == address(0));
    }

    function test_undelegateFrom_TokenMarkedUndelegatedAfterCallAndEventEmitted()
        public
        tokenDelegated(user1, user2, 1)
    {
        // Before undelegation token 1 is delegated to user 2
        assertTrue(collection.isDelegatee(user1, user2, 1, AMOUNT));

        vm.expectEmit(true, true, true, true);
        emit Undelegated(user1, user2, 721, 1, AMOUNT);

        // User 1 undelegates from user 2
        vm.prank(user1);
        collection.undelegateFrom(user2, 1, AMOUNT);

        // After undelegation token 1 is not delegated to user 2
        assertTrue(!collection.isDelegatee(user1, user2, 1, AMOUNT));

        // Cant undelegate twice
        vm.prank(user1);
        vm.expectRevert(bytes("ERCXXX: undelegate amount exceeds delegated amount"));
        collection.undelegateFrom(user2, 1, AMOUNT);
    }

    function test_undelegateFrom_CantUndelegateNotDelegatedToken() public {
        // User 1 undelegates from user 2
        vm.prank(user1);
        vm.expectRevert(bytes("ERCXXX: undelegate amount exceeds delegated amount"));
        collection.undelegateFrom(user2, 1, AMOUNT);
    }

    function test_undelegateFrom_CantUnDelegateToZeroAddres() public tokenDelegated(user1, user2, 1) {
        vm.prank(user1);
        vm.expectRevert(bytes("ERCXXX: cant undelegate from the zero address"));
        collection.undelegateFrom(address(0), 1, AMOUNT);
    }

    function test_undelegateFromAll_AllTokensUndelegatedAndThenDelegateAgainAndEventEmittedAndGettersWork()
        public
        tokenDelegated(user1, user2, 1)
        tokenDelegated(user1, user3, 2)
    {
        // Before undelegation tokens are delegated
        assertTrue(collection.isDelegatee(user1, user2, 1, AMOUNT));
        assertTrue(collection.isDelegatee(user1, user3, 2, AMOUNT));

        vm.expectEmit(true, true, true, true);
        // Asset id is not used, emits 0 always
        emit UndelegatedAll(user1, 721, 0);

        // User 1 undelegates from all (doesnt matter parameter passed as we are using ERC721)
        vm.prank(user1);
        collection.undelegateFromAll(69);

        // After undelegation token are not delegated
        assertTrue(!collection.isDelegatee(user1, user2, 1, AMOUNT));
        assertTrue(!collection.isDelegatee(user1, user3, 2, AMOUNT));

        // Getters checks
        uint256 delegatorActiveNonce = collection.getDelegatorActiveNonce(user1, 69);
        assertTrue(delegatorActiveNonce == 1);
        assertTrue(collection.getDelegateeActiveNonceOfAsset(user1, 1, user2) == 0);
        assertTrue(collection.getDelegateeAmountOfAssetId(user1, 1, user2, delegatorActiveNonce) == 0);
        assertTrue(!collection.getAssetIsDelegatedForDelegator(user1, 1, delegatorActiveNonce));
        assertTrue(collection.getDelegateeOfAssetId(1) == address(0));

        // Tokens can be delegated again if desired
        vm.startPrank(user1);
        collection.delegateTo(user2, 1, AMOUNT);
        collection.delegateTo(user3, 2, AMOUNT);
        vm.stopPrank();

        assertTrue(collection.isDelegatee(user1, user2, 1, AMOUNT));
        assertTrue(collection.isDelegatee(user1, user3, 2, AMOUNT));

        // Getters check 2
        delegatorActiveNonce = collection.getDelegatorActiveNonce(user1, 69);
        assertTrue(delegatorActiveNonce == 1);
        assertTrue(collection.getDelegateeActiveNonceOfAsset(user1, 1, user2) == 1);
        assertTrue(collection.getDelegateeActiveNonceOfAsset(user1, 2, user3) == 1);
        assertTrue(collection.getDelegateeAmountOfAssetId(user1, 1, user2, delegatorActiveNonce) == 1);
        assertTrue(collection.getDelegateeAmountOfAssetId(user1, 2, user3, delegatorActiveNonce) == 1);
        assertTrue(collection.getAssetIsDelegatedForDelegator(user1, 1, delegatorActiveNonce));
        assertTrue(collection.getAssetIsDelegatedForDelegator(user1, 2, delegatorActiveNonce));
        assertTrue(collection.getDelegateeOfAssetId(1) == user2);
        assertTrue(collection.getDelegateeOfAssetId(2) == user3);
    }

    // =========== TOKEN TRANSFERS TESTS ===========

    function test_transferAbidesDelegations_UsingTransfer() public tokenDelegated(user1, user2, 1) {
        // User 1 transfers nft 1, should revert as is delegated
        vm.startPrank(user1);
        vm.expectRevert(bytes("ERC721Delegatable: Transfer violates delegation amounts"));
        collection.transferFrom(user1, user3, 1);

        // Ive only added this assert so coverage shows 100% funcs called
        // doesnt matter if not here as allt transfers internally call this function
        // but then forge coverage doesnt detect it and looks like coverage is incomplete
        assertTrue(collection.transferAbidesDelegations(user1, 2, 1));

        // User 1 transfers nft 2, shouldnt revert as is not delegated
        collection.transferFrom(user1, user3, 2);

        // Undelegates nft 1 and tries to transfer, should work
        collection.undelegateFrom(user2, 1, AMOUNT);
        collection.transferFrom(user1, user3, 1);

        vm.stopPrank();
    }

    function test_transferAbidesDelegations_UsingSafeTransfer() public tokenDelegated(user1, user2, 1) {
        // User 1 transfers nft 1, should revert as is delegated
        vm.startPrank(user1);
        vm.expectRevert(bytes("ERC721Delegatable: Transfer violates delegation amounts"));
        collection.safeTransferFrom(user1, user3, 1);

        // User 1 transfers nft 2, shouldnt revert as is not delegated
        collection.safeTransferFrom(user1, user3, 2);

        // Undelegates nft 1 and tries to transfer, should work
        collection.undelegateFrom(user2, 1, AMOUNT);
        collection.safeTransferFrom(user1, user3, 1);
        vm.stopPrank();
    }

    function test_transferAbidesDelegations_UsingTransferAndUndelegateForAll() public tokenDelegated(user1, user2, 1) {
        // User 1 transfers nft 1, should revert as is delegated
        vm.startPrank(user1);
        vm.expectRevert(bytes("ERC721Delegatable: Transfer violates delegation amounts"));
        collection.transferFrom(user1, user3, 1);

        // User 1 transfers nft 2, shouldnt revert as is not delegated
        collection.transferFrom(user1, user3, 2);

        // Undelegates nft 1 and tries to transfer, should work
        collection.undelegateFromAll(69);
        collection.transferFrom(user1, user3, 1);
        vm.stopPrank();
    }

    function test_transferAbidesDelegations_UsingSafeTransferAndUndelegateForAll()
        public
        tokenDelegated(user1, user2, 1)
    {
        // User 1 transfers nft 1, should revert as is delegated
        vm.startPrank(user1);
        vm.expectRevert(bytes("ERC721Delegatable: Transfer violates delegation amounts"));
        collection.safeTransferFrom(user1, user3, 1);

        // User 1 transfers nft 2, shouldnt revert as is not delegated
        collection.safeTransferFrom(user1, user3, 2);

        // Undelegates nft 1 and tries to transfer, should work
        collection.undelegateFromAll(69);
        collection.safeTransferFrom(user1, user3, 1);
        vm.stopPrank();
    }

    // =========== GETTERS TESTS ===========

    function test_getAmountDelegatedTo_MustAlwaysReturnOneOrZeroForERC721() public tokenDelegated(user1, user2, 1) {
        assertTrue(collection.getAmountDelegatedTo(user1, user2, 1) == 1);
        assertTrue(collection.getAmountDelegatedTo(user1, user2, 2) == 0);
        assertTrue(collection.getAmountDelegatedTo(user1, user3, 1) == 0);
        assertTrue(collection.getAmountDelegatedTo(user1, user3, 2) == 0);

        vm.prank(user1);
        collection.delegateTo(user3, 2, AMOUNT);

        assertTrue(collection.getAmountDelegatedTo(user1, user2, 2) == 0);
        assertTrue(collection.getAmountDelegatedTo(user1, user3, 2) == 1);
    }

    function test_getAssetType_Reuturns721() public {
        assertTrue(collection.getAssetType() == 721);
    }

    // =========== BURNED TOKEN TESTS ===========

    function test_MustUndelegateBeforeBurn() public tokenDelegated(user1, user2, 1) {
        vm.prank(user1);
        // A burn is a transfer to the 0 address
        vm.expectRevert(bytes("ERC721Delegatable: Transfer violates delegation amounts"));
        collection.burn(1);

        vm.prank(user1);
        collection.undelegateFrom(user2, 1, AMOUNT);

        vm.prank(user1);
        collection.burn(1);
    }

    function test_MustUndelegateBeforeBurnWithUndelegateForAll() public tokenDelegated(user1, user2, 1) {
        vm.prank(user1);
        vm.expectRevert();
        collection.burn(1);

        vm.prank(user1);
        collection.undelegateFromAll(69);

        vm.prank(user1);
        collection.burn(1);
    }

    function test_CantDelegateBurnedToken() public {
        vm.prank(user1);
        collection.burn(1);

        vm.prank(user1);
        // Now "owner" is address 0
        vm.expectRevert(bytes("ERCXXX: delegate amount exceeds balance"));
        collection.delegateTo(user2, 1, AMOUNT);
    }
}
