// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/Test.sol";
import "../scenarios/nftsMinted-ERC721Delegatable.t.sol";

contract FuzzERC721DelegatableTest is MintedTokensScenario {
    // @dev MAX_AMOUNT_OF_TOKENS_DELEGATED
    uint256 public AMOUNT = 1;

    function setUp() public virtual override {
        MintedTokensScenario.setUp();
    }

    // =========== UTILS FUNCTIONS ===========

    function tokenDelegate(address owner, address delegatee, uint256 tokenId) internal {
        vm.prank(owner);
        collection.delegateTo(delegatee, tokenId, AMOUNT);
    }

    /// @dev _delegator and _delegatee will be distinct and will be on the range of addresses AMOUNT_OF_USERS
    function getValidDelegatorAndDelegateeAndDelegatorNFT(address delegator, address delegatee, uint256 rndmNftId)
        public
        view
        returns (address, address, uint256)
    {
        (address _delegator, address _delegatee) = get2DistinctRandomUsersFromFuzz(delegator, delegatee);
        uint256 validNftId = rndmNftId % AMOUNT_OF_TOKENS_TO_MINT_EACH_USER + 1;
        uint256 _delegatorNft = getNftFromUser(validNftId, _delegator);
        return (_delegator, _delegatee, _delegatorNft);
    }

    function getValidDelegatorAndDelegateex2AndDelegatorNFTx2(
        address delegator,
        address delegatee,
        uint256 rndmNftId,
        uint256 rndmNftId2
    ) public view returns (address, address, address, uint256, uint256) {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);

        address _secondDelegatee = get3rdDistinctAddresFrom(_delegator, _delegatee);

        uint256 _delegatorNft2 = getValidDelegatorVlaidNftN2(_delegator, rndmNftId, rndmNftId2);
        return (_delegator, _delegatee, _secondDelegatee, _delegatorNft, _delegatorNft2);
    }

    function getValidDelegatorVlaidNftN2(address _delegator, uint256 rndmNftId, uint256 rndmNftId2)
        public
        view
        returns (uint256)
    {
        (uint256 _rndm1, uint256 _rndm2) = makeSureNumbersAreDifferent(rndmNftId, rndmNftId2, type(uint256).max);
        uint256 validNftIdUsedBefore = _rndm1 % AMOUNT_OF_TOKENS_TO_MINT_EACH_USER + 1;
        uint256 validNftId = _rndm2 % AMOUNT_OF_TOKENS_TO_MINT_EACH_USER + 1;
        (validNftIdUsedBefore, validNftId) =
            makeSureNumbersAreDifferent(validNftIdUsedBefore, validNftId, AMOUNT_OF_TOKENS_TO_MINT_EACH_USER);
        uint256 _delegatorNft2 = getNftFromUser(validNftId, _delegator);
        return (_delegatorNft2);
    }

    //================================================================
    // TESTS
    //================================================================

    // =========== DELEGATE TESTS ===========

    function testFuzz_delegateTo_OwnsershipIsPreservedAndEventEmittedAndGettersWork(
        address delegator,
        address delegatee,
        uint256 rndmNftId
    ) public {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);

        assertTrue(collection.ownerOf(_delegatorNft) == _delegator);
        assertTrue(!(collection.ownerOf(_delegatorNft) == _delegatee));

        vm.expectEmit(true, true, true, true);
        emit Delegated(_delegator, _delegatee, 721, _delegatorNft, AMOUNT);

        vm.prank(_delegator);
        collection.delegateTo(_delegatee, _delegatorNft, AMOUNT);

        assertTrue(collection.ownerOf(_delegatorNft) == _delegator);
        assertTrue(!(collection.ownerOf(_delegatorNft) == _delegatee));

        // Getters checks
        uint256 delegatorActiveNonce = collection.getDelegatorActiveNonce(_delegator, rndmNftId);
        assertTrue(delegatorActiveNonce == 0);
        assertTrue(collection.getDelegateeActiveNonceOfAsset(_delegator, _delegatorNft, _delegatee) == 0);
        assertTrue(
            collection.getDelegateeAmountOfAssetId(_delegator, _delegatorNft, _delegatee, delegatorActiveNonce) == 1
        );
        assertTrue(collection.getAssetIsDelegatedForDelegator(_delegator, _delegatorNft, delegatorActiveNonce));
        assertTrue(collection.getDelegateeOfAssetId(_delegatorNft) == _delegatee);
    }

    function testFuzz_delegateTo_OnlyOwnerCanDelegate(address delegator, address delegatee, uint256 rndmNftId) public {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);
        assertTrue(collection.ownerOf(_delegatorNft) == _delegator);
        assertTrue(!(collection.ownerOf(_delegatorNft) == _delegatee));

        // Delegatee delegates an nft which is not its own
        vm.prank(_delegatee);
        vm.expectRevert(bytes("ERCXXX: delegate amount exceeds balance"));
        collection.delegateTo(_delegator, _delegatorNft, AMOUNT);
    }

    function testFuzz_delegateTo_CantDelegateToYourself(address delegator, uint256 rndmNftId) public {
        (address _delegator, /* address _delegatee */, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegator, rndmNftId);
        assertTrue(collection.ownerOf(_delegatorNft) == _delegator);
        vm.prank(_delegator);
        vm.expectRevert(bytes("ERCXXX: cant delegate to yourself"));
        collection.delegateTo(_delegator, _delegatorNft, AMOUNT);
    }

    function testFuzz_delegateTo_CantDelegateToZeroAddres(address delegator, uint256 rndmNftId) public {
        (address _delegator, /* address _delegatee */, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegator, rndmNftId);
        vm.prank(_delegator);
        vm.expectRevert(bytes("ERCXXX: delegate to the zero address"));
        collection.delegateTo(address(0), _delegatorNft, AMOUNT);
    }

    function testFuzz_delegateTo_CantDelegateMoreThanOneOfTheSameNft(
        uint256 amount,
        address delegator,
        address delegatee,
        uint256 rndmNftId
    ) public {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);
        amount = amount % type(uint256).max + 1;
        amount = (amount == 1) ? 0 : amount;
        vm.prank(_delegator);
        // Cant expect a specific revert as different inputs will trigger different reverts
        vm.expectRevert();
        collection.delegateTo(_delegatee, _delegatorNft, amount);
    }

    function testFuzz_delegateTo_And_IsDelegatee_MarksDlegateeOnlyAfterDelegation(
        address delegator,
        address delegatee,
        uint256 rndmNftId
    ) public {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);

        // Before delegation token is not delegated to delegatee
        assertTrue(!collection.isDelegatee(_delegator, _delegatee, _delegatorNft, AMOUNT));

        // Delegator delegates to delegatee
        vm.prank(_delegator);
        collection.delegateTo(_delegatee, _delegatorNft, AMOUNT);

        // Delegator undelegates from delegatee
        vm.prank(_delegator);
        collection.undelegateFrom(_delegatee, _delegatorNft, AMOUNT);

        // After undelegation token is not delegated to delegatee
        assertTrue(!collection.isDelegatee(_delegator, _delegatee, _delegatorNft, AMOUNT));
    }

    function testFuzz_isDelegatee_AmountOfZeroMustReturnFalse(address delegator, address delegatee, uint256 rndmNftId)
        public
    {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);
        assertTrue(!collection.isDelegatee(_delegator, _delegatee, _delegatorNft, 0));

        vm.prank(_delegator);
        collection.delegateTo(_delegatee, _delegatorNft, AMOUNT);

        // Even after delegation, amount of zero must return false
        assertTrue(!collection.isDelegatee(_delegator, _delegatee, _delegatorNft, 0));

        vm.prank(_delegator);
        collection.undelegateFrom(_delegatee, _delegatorNft, AMOUNT);

        assertTrue(!collection.isDelegatee(_delegator, _delegatee, _delegatorNft, 0));

        // Even with undelegate from all, amount of zero returns false
        vm.startPrank(_delegator);
        collection.delegateTo(_delegatee, _delegatorNft, AMOUNT);
        collection.undelegateFromAll(rndmNftId);
        vm.stopPrank();
        assertTrue(!collection.isDelegatee(_delegator, _delegatee, _delegatorNft, 0));
    }

    function testFuzz_delegateTo_YouCantDelegateAnNftMoreThanOnce(
        address delegator,
        address delegatee,
        uint256 rndmNftId
    ) public {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);
        address _secondDelegatee = get3rdDistinctAddresFrom(_delegator, _delegatee);

        tokenDelegate(_delegator, _delegatee, _delegatorNft);

        // You can't delegate more than once an NFT
        vm.prank(_delegator);

        vm.expectRevert(bytes("ERCXXX: cant delegate to yourself"));
        collection.delegateTo(_delegator, _delegatorNft, AMOUNT);

        vm.expectRevert(bytes("ERCXXX: delegate amount exceeds balance"));
        collection.delegateTo(_delegatee, _delegatorNft, AMOUNT);

        vm.expectRevert(bytes("ERCXXX: delegate amount exceeds balance"));
        collection.delegateTo(_secondDelegatee, _delegatorNft, AMOUNT);
    }

    // =========== UNDELEGATE TESTS ===========

    function testFuzz_undelegateFrom_OnlyAsetOwnerCanUndelegateAndGettersWork(
        address delegator,
        address delegatee,
        uint256 rndmNftId
    ) public {
        (
            address _delegator,
            address _delegatee,
            address _secondDelegatee,
            uint256 _delegatorNft,
            /*uint256 _delegatorNft2*/
        ) = getValidDelegatorAndDelegateex2AndDelegatorNFTx2(delegator, delegatee, rndmNftId, rndmNftId);

        tokenDelegate(_delegator, _delegatee, _delegatorNft);

        // Before undelegation token is delegated to delegatee
        assertTrue(collection.isDelegatee(_delegator, _delegatee, _delegatorNft, AMOUNT));

        // Delegatee undelegates from itself, itself is not owner, should revert
        vm.prank(_delegatee);
        vm.expectRevert(bytes("ERCXXX: undelegate amount exceeds delegated amount"));
        collection.undelegateFrom(_delegatee, _delegatorNft, AMOUNT);

        // Random person undelegates from delegatee, random person is not owner, should revert
        vm.prank(_secondDelegatee);
        vm.expectRevert(bytes("ERCXXX: undelegate amount exceeds delegated amount"));
        collection.undelegateFrom(_delegatee, _delegatorNft, AMOUNT);

        // Getters checks
        vm.prank(_delegator);
        collection.undelegateFrom(_delegatee, _delegatorNft, AMOUNT);

        uint256 delegatorActiveNonce = collection.getDelegatorActiveNonce(_delegator, rndmNftId);
        assertTrue(delegatorActiveNonce == 0);
        assertTrue(collection.getDelegateeActiveNonceOfAsset(_delegator, _delegatorNft, _delegatee) == 0);
        assertTrue(
            collection.getDelegateeAmountOfAssetId(_delegator, _delegatorNft, _delegatee, delegatorActiveNonce) == 0
        );
        assertTrue(!collection.getAssetIsDelegatedForDelegator(_delegator, _delegatorNft, delegatorActiveNonce));
        assertTrue(collection.getDelegateeOfAssetId(_delegatorNft) == address(0));
    }

    function testFuzz_undelegateFrom_TokenMarkedUndelegatedAfterCallAndEventEmitted(
        address delegator,
        address delegatee,
        uint256 rndmNftId
    ) public {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);

        tokenDelegate(_delegator, _delegatee, _delegatorNft);

        // Before undelegation token is delegated to delegatee
        assertTrue(collection.isDelegatee(_delegator, _delegatee, _delegatorNft, AMOUNT));

        vm.expectEmit(true, true, true, true);
        emit Undelegated(_delegator, _delegatee, 721, _delegatorNft, AMOUNT);

        // Delegator undelegates from delegatee
        vm.prank(_delegator);
        collection.undelegateFrom(_delegatee, _delegatorNft, AMOUNT);

        // After undelegation token is not delegated to delegatee
        assertTrue(!collection.isDelegatee(_delegator, _delegatee, _delegatorNft, AMOUNT));

        // Cant undelegate twice
        vm.prank(_delegator);
        vm.expectRevert(bytes("ERCXXX: undelegate amount exceeds delegated amount"));
        collection.undelegateFrom(_delegatee, _delegatorNft, AMOUNT);
    }

    function testFuzz_undelegateFrom_CantUndelegateNotDelegatedToken(
        address delegator,
        address delegatee,
        uint256 rndmNftId
    ) public {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);

        vm.prank(_delegator);
        vm.expectRevert(bytes("ERCXXX: undelegate amount exceeds delegated amount"));
        collection.undelegateFrom(_delegatee, _delegatorNft, AMOUNT);
    }

    function testFuzz_undelegateFrom_CantUnDelegateToZeroAddres(address delegator, uint256 rndmNftId) public {
        (address _delegator, /*address _delegatee*/, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegator, rndmNftId);
        vm.prank(_delegator);
        vm.expectRevert(bytes("ERCXXX: cant undelegate from the zero address"));
        collection.undelegateFrom(address(0), _delegatorNft, AMOUNT);
    }

    function testFuzz_undelegateFromAll_AllTokensUndelegatedAndThenDelegateAgainAndEventEmittedAndChecksWork(
        address delegator,
        address delegatee,
        uint256 rndmNftId,
        uint256 rndmNftId2,
        uint256 rndmNftId3
    ) public {
        (
            address _delegator,
            address _delegatee,
            address _secondDelegatee,
            uint256 _delegatorNft,
            uint256 _delegatorNft2
        ) = getValidDelegatorAndDelegateex2AndDelegatorNFTx2(delegator, delegatee, rndmNftId, rndmNftId2);

        tokenDelegate(_delegator, _delegatee, _delegatorNft);
        tokenDelegate(_delegator, _secondDelegatee, _delegatorNft2);

        // Before undelegation tokens are delegated
        assertTrue(collection.isDelegatee(_delegator, _delegatee, _delegatorNft, AMOUNT));
        assertTrue(collection.isDelegatee(_delegator, _secondDelegatee, _delegatorNft2, AMOUNT));

        vm.expectEmit(true, true, true, true);
        emit UndelegatedAll(_delegator, 721, 0);

        // Delegator undelegates from all (doesnt matter parameter passed as we are using ERC721)
        vm.prank(_delegator);
        collection.undelegateFromAll(rndmNftId3);

        // After undelegation token are not delegated
        assertTrue(!collection.isDelegatee(_delegator, _delegatee, _delegatorNft, AMOUNT));
        assertTrue(!collection.isDelegatee(_delegator, _secondDelegatee, _delegatorNft2, AMOUNT));

        // Getters checks
        uint256 delegatorActiveNonce = collection.getDelegatorActiveNonce(_delegator, rndmNftId);
        assertTrue(delegatorActiveNonce == 1);
        assertTrue(collection.getDelegateeActiveNonceOfAsset(_delegator, _delegatorNft, _delegatee) == 0);
        assertTrue(
            collection.getDelegateeAmountOfAssetId(_delegator, _delegatorNft, _delegatee, delegatorActiveNonce) == 0
        );
        assertTrue(!collection.getAssetIsDelegatedForDelegator(_delegator, _delegatorNft, delegatorActiveNonce));
        assertTrue(collection.getDelegateeOfAssetId(_delegatorNft) == address(0));

        // Tokens can be delegated again if desired
        vm.startPrank(_delegator);
        collection.delegateTo(_delegatee, _delegatorNft, AMOUNT);
        collection.delegateTo(_secondDelegatee, _delegatorNft2, AMOUNT);
        vm.stopPrank();

        assertTrue(collection.isDelegatee(_delegator, _delegatee, _delegatorNft, AMOUNT));
        assertTrue(collection.isDelegatee(_delegator, _secondDelegatee, _delegatorNft2, AMOUNT));

        // Getters check 2
        delegatorActiveNonce = collection.getDelegatorActiveNonce(_delegator, rndmNftId);
        assertTrue(delegatorActiveNonce == 1);
        assertTrue(collection.getDelegateeActiveNonceOfAsset(_delegator, _delegatorNft, _delegatee) == 1);
        assertTrue(collection.getDelegateeActiveNonceOfAsset(_delegator, _delegatorNft2, _secondDelegatee) == 1);
        assertTrue(
            collection.getDelegateeAmountOfAssetId(_delegator, _delegatorNft, _delegatee, delegatorActiveNonce) == 1
        );
        assertTrue(
            collection.getDelegateeAmountOfAssetId(_delegator, _delegatorNft2, _secondDelegatee, delegatorActiveNonce)
                == 1
        );
        assertTrue(collection.getAssetIsDelegatedForDelegator(_delegator, _delegatorNft, delegatorActiveNonce));
        assertTrue(collection.getAssetIsDelegatedForDelegator(_delegator, _delegatorNft2, delegatorActiveNonce));
        assertTrue(collection.getDelegateeOfAssetId(_delegatorNft) == _delegatee);
        assertTrue(collection.getDelegateeOfAssetId(_delegatorNft2) == _secondDelegatee);
    }

    // =========== TOKEN TRANSFERS TESTS ===========

    function testFuzz_transferAbidesDelegations_UsingTransfer(
        address delegator,
        address delegatee,
        uint256 rndmNftId,
        uint256 rndmNftId2
    ) public {
        // Preparing data
        (
            address _delegator,
            address _delegatee,
            address _secondDelegatee,
            uint256 _delegatorNft,
            uint256 _delegatorNft2
        ) = getValidDelegatorAndDelegateex2AndDelegatorNFTx2(delegator, delegatee, rndmNftId, rndmNftId2);
        tokenDelegate(_delegator, _delegatee, _delegatorNft);

        // Delegator transfers nft, should revert as is delegated
        vm.startPrank(_delegator);
        vm.expectRevert(bytes("ERC721Delegatable: Transfer violates delegation amounts"));
        collection.transferFrom(_delegator, _delegatee, _delegatorNft);

        // Delegator transfers nft2, shouldnt revert as is not delegated
        collection.transferFrom(_delegator, _secondDelegatee, _delegatorNft2);

        // Undelegates nft and tries to transfer, should work
        collection.undelegateFrom(_delegatee, _delegatorNft, AMOUNT);
        collection.transferFrom(_delegator, _delegatee, _delegatorNft);

        vm.stopPrank();
    }

    function testFuzz_transferAbidesDelegations_UsingSafeTransfer(
        address delegator,
        address delegatee,
        uint256 rndmNftId,
        uint256 rndmNftId2
    ) public {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);

        uint256 _delegatorNft2 = getValidDelegatorVlaidNftN2(_delegator, rndmNftId, rndmNftId2);

        tokenDelegate(_delegator, _delegatee, _delegatorNft);

        // Delegator transfers nft, should revert as is delegated
        vm.startPrank(_delegator);
        vm.expectRevert(bytes("ERC721Delegatable: Transfer violates delegation amounts"));
        collection.safeTransferFrom(_delegator, _delegatee, _delegatorNft);

        // Delegator transfers nft2, shouldnt revert as is not delegated
        collection.safeTransferFrom(_delegator, _delegatee, _delegatorNft2);

        // Undelegates nft and tries to transfer, should work
        collection.undelegateFrom(_delegatee, _delegatorNft, AMOUNT);

        collection.safeTransferFrom(_delegator, _delegatee, _delegatorNft);
        vm.stopPrank();
    }

    function testFuzz_transferAbidesDelegations_UsingTransferAndUndelegateForAll(
        address delegator,
        address delegatee,
        uint256 rndmNftId,
        uint256 rndmNftId2,
        uint256 rndmNftId3
    ) public {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);

        uint256 _delegatorNft2 = getValidDelegatorVlaidNftN2(_delegator, rndmNftId, rndmNftId2);

        tokenDelegate(_delegator, _delegatee, _delegatorNft);

        // Delegator transfers nft, should revert as is delegated
        vm.startPrank(_delegator);
        vm.expectRevert(bytes("ERC721Delegatable: Transfer violates delegation amounts"));
        collection.transferFrom(_delegator, _delegatee, _delegatorNft);

        // Delegator transfers nft2, shouldnt revert as is not delegated
        collection.transferFrom(_delegator, _delegatee, _delegatorNft2);

        // Undelegates nft and tries to transfer, should work
        collection.undelegateFromAll(rndmNftId3);
        collection.transferFrom(_delegator, _delegatee, _delegatorNft);
        vm.stopPrank();
    }

    function testFuzz_transferAbidesDelegations_UsingSafeTransferAndUndelegateForAll(
        address delegator,
        address delegatee,
        uint256 rndmNftId,
        uint256 rndmNftId2,
        uint256 rndmNftId3
    ) public {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);

        uint256 _delegatorNft2 = getValidDelegatorVlaidNftN2(_delegator, rndmNftId, rndmNftId2);

        tokenDelegate(_delegator, _delegatee, _delegatorNft);

        // Delegator transfers nft, should revert as is delegated
        vm.startPrank(_delegator);
        vm.expectRevert(bytes("ERC721Delegatable: Transfer violates delegation amounts"));
        collection.safeTransferFrom(_delegator, _delegatee, _delegatorNft);

        // Delegator transfers nft2, shouldnt revert as is not delegated
        collection.safeTransferFrom(_delegator, _delegatee, _delegatorNft2);

        // Undelegates nft and tries to transfer, should work
        collection.undelegateFromAll(rndmNftId3);
        collection.safeTransferFrom(_delegator, _delegatee, _delegatorNft);
        vm.stopPrank();
    }

    // =========== GETTERS TESTS ===========

    function testFuzz_getAmountDelegatedTo_MustAlwaysReturnOneOrZeroForERC721(
        address delegator,
        address delegatee,
        uint256 rndmNftId,
        uint256 rndmNftId2
    ) public {
        (
            address _delegator,
            address _delegatee,
            address _secondDelegatee,
            uint256 _delegatorNft,
            uint256 _delegatorNft2
        ) = getValidDelegatorAndDelegateex2AndDelegatorNFTx2(delegator, delegatee, rndmNftId, rndmNftId2);

        tokenDelegate(_delegator, _delegatee, _delegatorNft);

        assertTrue(collection.getAmountDelegatedTo(_delegator, _delegatee, _delegatorNft) == 1);
        assertTrue(collection.getAmountDelegatedTo(_delegator, _delegatee, _delegatorNft2) == 0);
        assertTrue(collection.getAmountDelegatedTo(_delegator, _secondDelegatee, _delegatorNft) == 0);
        assertTrue(collection.getAmountDelegatedTo(_delegator, _secondDelegatee, _delegatorNft2) == 0);

        vm.prank(_delegator);
        collection.delegateTo(_secondDelegatee, _delegatorNft2, AMOUNT);

        assertTrue(collection.getAmountDelegatedTo(_delegator, _delegatee, _delegatorNft2) == 0);
        assertTrue(collection.getAmountDelegatedTo(_delegator, _secondDelegatee, _delegatorNft2) == 1);
    }

    // =========== BURNED TOKEN TESTS ===========

    function testFuzz_MustUndelegateBeforeBurn(address delegator, address delegatee, uint256 rndmNftId) public {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);

        tokenDelegate(_delegator, _delegatee, _delegatorNft);

        vm.prank(_delegator);
        vm.expectRevert(bytes("ERC721Delegatable: Transfer violates delegation amounts"));
        collection.burn(_delegatorNft);

        vm.prank(_delegator);
        collection.undelegateFrom(_delegatee, _delegatorNft, AMOUNT);

        vm.prank(_delegator);
        collection.burn(_delegatorNft);
    }

    function testFuzz_MustUndelegateBeforeBurnWithUndelegateForAll(
        address delegator,
        address delegatee,
        uint256 rndmNftId
    ) public {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);

        tokenDelegate(_delegator, _delegatee, _delegatorNft);

        vm.prank(_delegator);
        vm.expectRevert(bytes("ERC721Delegatable: Transfer violates delegation amounts"));
        collection.burn(_delegatorNft);

        vm.prank(_delegator);
        collection.undelegateFromAll(rndmNftId);

        vm.prank(_delegator);
        collection.burn(_delegatorNft);
    }

    function testFuzz_CantDelegateBurnedToken(address delegator, address delegatee, uint256 rndmNftId) public {
        (address _delegator, address _delegatee, uint256 _delegatorNft) =
            getValidDelegatorAndDelegateeAndDelegatorNFT(delegator, delegatee, rndmNftId);

        vm.prank(_delegator);
        collection.burn(_delegatorNft);

        vm.prank(_delegator);
        vm.expectRevert(bytes("ERCXXX: delegate amount exceeds balance"));
        collection.delegateTo(_delegatee, _delegatorNft, AMOUNT);
    }
}
