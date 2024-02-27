// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console} from "forge-std/Test.sol";
import {DCollection} from "../../../src/DCollection.sol";
import {ActorManagerERC721DelegatableTest} from "../actorManagers/ActorManagerERC721Delegatable.t.sol";
import {BaseTestERC721Delegatable} from "../../BaseTestERC721Delegatable.t.sol";

import {InvariantConstants} from "../invariantERC721Delegatable.t.sol";

/**
 * @dev Takes a random user and executes some possible valid non-malcious actions:
 *     - mint token
 *     - burn token
 *     - delegate tokens => delegateTo
 *     - undelegate tokens => undelegateFrom || undelegateFromAll
 *     - transfer tokens => transferFrom || safeTransferFrom
 *
 * note This handler is not perfect, some actions revert, very little ones though, around 0.26%,
 * in the future it should be reduced it to 0 to have an 100% mega-splendid testbase.
 */
contract HanlderERC721DelegatableTest is InvariantConstants {
    DCollection public immutable COLLECTION;
    ActorManagerERC721DelegatableTest public immutable AM;

    uint256 public WASTED_CALLS;

    constructor(address _COLLECTION, address _actorManager) {
        COLLECTION = DCollection(_COLLECTION);
        AM = ActorManagerERC721DelegatableTest(_actorManager);
    }

    // ======= HANDLER ACTIONS =======

    /// @dev controllers sanitizes the input so the action (service) never receives unexpeced input
    function h_mintAsset(address user) public {
        AM.controller_mintAction(user, COLLECTION.s_nextId());
        _mintAssetTo(user);
    }

    /// @dev Twice so there is more chance of minting than burning and waste less burning calls
    function h_mintAsset2(address user) public {
        h_mintAsset(user);
    }

    function h_burnAsset(uint256 rndmUser) public {
        (address _user, uint256 _assetId, bool _canProceedNoRevert) = AM.controller_burnActionBefore(rndmUser);
        if (_canProceedNoRevert) {
            _burnAsset(_user, _assetId);
            AM.controller_burnActionAfter(_user, _assetId);
        } else {
            WASTED_CALLS++;
        }
    }

    function h_delegatesTo(uint256 rndmUser, address rndnmDelegatee) public {
        (address owner, uint256 nft, bool _canProceedNoRevert) = AM.controller_delegateToActionBefore(rndmUser);
        if (_canProceedNoRevert) {
            _delegatesTo(owner, rndnmDelegatee, nft);
            AM.controller_delegateToActionAfter(owner, nft);
        } else {
            WASTED_CALLS++;
        }
    }

    function h_undelegatesTo(uint256 rndmUser) public {
        (address owner, address delegatee, uint256 nft, bool _canProceedNoRevert) =
            AM.controller_undelegateFromActionBefore(rndmUser);
        if (_canProceedNoRevert) {
            _undelegatesTo(owner, delegatee, nft);
            AM.controller_undelegateFromActionAfter(owner, nft);
        } else {
            WASTED_CALLS++;
        }
    }

    function h_undelegatesFromAll(uint256 rndmUser) public {
        (address owner, bool _canProceedNoRevert) = AM.controller_undelegateFromAllActionBefore(rndmUser);
        if (_canProceedNoRevert) {
            _undelegatesFromAll(owner, rndmUser);
            AM.controller_undelegateFromAllActionAfter(owner);
        } else {
            WASTED_CALLS++;
        }
    }

    function h_transfer(uint256 rndmUser) public {
        (address from, address to, uint256 nft, bool _canProceedNoRevert) = AM.controller_transferActionBefore(rndmUser);
        if (_canProceedNoRevert) {
            _transfer(from, to, nft);
            AM.controller_transferActionAfter(from, to, nft);
        } else {
            WASTED_CALLS++;
        }
    }

    // ======= PRIVATE SERVICES =======

    function _mintAssetTo(address _user) private {
        vm.prank(_user);
        COLLECTION.mint(_user);
    }

    function _burnAsset(address user, uint256 _assetId) private {
        vm.prank(user);
        COLLECTION.burn(_assetId);
    }

    function _delegatesTo(address owner, address delegatee, uint256 nft) private {
        vm.prank(owner);
        COLLECTION.delegateTo(delegatee, nft, MAX_AMOUNT_TOKENS_CAN_BE_DELEGATED);
    }

    function _undelegatesTo(address owner, address delegatee, uint256 nft) private {
        vm.prank(owner);
        COLLECTION.undelegateFrom(delegatee, nft, MAX_AMOUNT_TOKENS_CAN_BE_DELEGATED);
    }

    function _undelegatesFromAll(address owner, uint256 rndmNum) private {
        vm.prank(owner);
        COLLECTION.undelegateFromAll(rndmNum);
    }

    function _transfer(address from, address to, uint256 tokenId) private {
        vm.prank(from);
        COLLECTION.transferFrom(from, to, tokenId);
    }
}

/**
 * @dev Executes malicious actions from random users that must revert:
 *      - delegate not owned tokens
 *      - undelegate not owned tokens
 *      - transfer delegated tokens
 *
 * note This test can be made more specific and efficient,
 * as they are now they are good though
 */
contract EvilHanlderERC721DelegatableTest is InvariantConstants {
    DCollection public immutable COLLECTION;
    ActorManagerERC721DelegatableTest public immutable AM;

    constructor(address _COLLECTION, address _actorManager) {
        COLLECTION = DCollection(_COLLECTION);
        AM = ActorManagerERC721DelegatableTest(_actorManager);
    }

    function evilh_delegateNotOwned(uint256 rndmUser, uint256 rndmUser2) public {
        address user = address(uint160(rndmUser) % type(uint160).max + 1);
        address user2 = address(uint160(rndmUser2) % type(uint160).max + 1);
        uint256 notOwned = _getRandomNftNotOwned(user, rndmUser);
        vm.prank(user);
        vm.expectRevert();
        COLLECTION.delegateTo(user2, notOwned, MAX_AMOUNT_TOKENS_CAN_BE_DELEGATED);
    }

    function evilh_undelegateNotOwned(uint256 rndmUser) public {
        address user = address(uint160(rndmUser) % type(uint160).max + 1);
        (uint256 notOwned, address delegatee) = _getRandomDelegatedNft();
        vm.prank(user);
        vm.expectRevert();
        COLLECTION.undelegateFrom(delegatee, notOwned, MAX_AMOUNT_TOKENS_CAN_BE_DELEGATED);
    }

    function evilh_transferDelegated(uint256 rndmUser) public {
        address user = address(uint160(rndmUser) % type(uint160).max + 1);
        (uint256 notOwned, /*address delegatee*/ ) = _getRandomDelegatedNft();
        address _from = COLLECTION.ownerOf(notOwned);
        vm.prank(user);
        vm.expectRevert();
        COLLECTION.transferFrom(_from, user, notOwned);
    }

    function _getRandomNftNotOwned(address _user, uint256 _rndmNum) private view returns (uint256 notOwnedNft) {
        notOwnedNft = _rndmNum % (COLLECTION.s_nextId()) + 1;
        uint256 i = 1;
        while (COLLECTION.ownerOf(notOwnedNft) == _user) {
            notOwnedNft = _rndmNum % i % (COLLECTION.s_nextId()) + 1;
            i++;
        }
    }

    function _getRandomDelegatedNft() private view returns (uint256 delegatedNft, address delegatee) {
        for (uint256 i = 1; i < COLLECTION.s_nextId(); i++) {
            if (AM.tknCanUndelegate(i)) {
                delegatedNft = i;
                delegatee = COLLECTION.getDelegateeOfAssetId(i);
                break;
            }
        }
        delegatedNft = 1;
        delegatee = address(1);
    }
}
