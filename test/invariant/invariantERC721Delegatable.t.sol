// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {BaseTestERC721Delegatable} from "../BaseTestERC721Delegatable.t.sol";
import {ActorManagerERC721DelegatableTest} from "./actorManagers/ActorManagerERC721Delegatable.t.sol";
import {
    EvilHanlderERC721DelegatableTest, HanlderERC721DelegatableTest
} from "./handlers/handlersERC721Delegatable.t.sol";
import {InvariantConstants} from "./InvariantConstants.sol";
import {DCollection} from "../../src/DCollection.sol";

import {console} from "forge-std/Test.sol";

/**
 * @dev Prohibited actions to guarantee integrity are:
 * - Can't delegate tokens not owned
 * - Can't undelegate tokens not owned
 * - Can't undelegate not delegated token
 * - Delegated token can't be transferred
 * - Delegated token can't be burned
 * - Burned token can't be delegated
 *
 * @notice The GOOD_HANDLERS will simulate random users creating all sort of
 * valid random actions. After each random action a round of illegal actions is
 * run (invariants) to see if something that shouldn't happen happens.
 *
 * On top of that there are EvilHanlders that appear sometimes to try some of thes
 * illegal actions. That is why there are some reverts even if the GOOD_HANDLERS
 * have just a 0.26% chance of revert.
 */
contract InvariantERC721DelegatableTest is InvariantConstants, BaseTestERC721Delegatable {
    /// @dev 2.5% of the time someone will send an invalid evil tx
    uint256 public constant GOOD_HANDLERS = 40;
    uint256 public constant EVIL_HANDLERS = 1;

    ActorManagerERC721DelegatableTest public AM;

    function setUp() public virtual override {
        // Initialize collection
        BaseTestERC721Delegatable.setUp();
        ActorManagerERC721DelegatableTest am = new ActorManagerERC721DelegatableTest(address(collection));
        AM = am;

        for (uint256 i = 0; i < GOOD_HANDLERS; i++) {
            HanlderERC721DelegatableTest h = new HanlderERC721DelegatableTest(address(collection), address(am));
            targetContract(address(h));
        }

        for (uint256 i = 0; i < EVIL_HANDLERS; i++) {
            EvilHanlderERC721DelegatableTest h = new EvilHanlderERC721DelegatableTest(address(collection), address(am));
            targetContract(address(h));
        }
    }

    function invariant_CantDelegateTokensNotOwned() public {
        uint256 tkn = AM.getNotDelegatedToken();
        if (tkn != 0) {
            vm.prank(OWNS_NO_TOKENS_ADDRESS);
            vm.expectRevert();
            collection.delegateTo(SOME_ADDRESS, tkn, MAX_AMOUNT_TOKENS_CAN_BE_DELEGATED);
        } else {
            // If all tokens are delegated, there is nothing to check.
            require(true);
        }
    }

    function invariant_CantUndelegateTokensNotOwned() public {
        (uint256 tkn, address delegatee) = AM.getDelegatedToken();
        if (tkn != 0 && delegatee != address(0)) {
            vm.prank(OWNS_NO_TOKENS_ADDRESS);
            vm.expectRevert();
            collection.undelegateFrom(delegatee, tkn, MAX_AMOUNT_TOKENS_CAN_BE_DELEGATED);
        } else {
            // If no token is delegated, there is nothing to check.
            require(true);
        }
    }

    function invariant_CantUndelegateNotDelegated() public {
        uint256 tkn = AM.getNotDelegatedToken();
        if (tkn != 0) {
            address owner = collection.ownerOf(tkn);
            vm.prank(owner);
            vm.expectRevert();
            collection.undelegateFrom(SOME_ADDRESS, tkn, MAX_AMOUNT_TOKENS_CAN_BE_DELEGATED);
        } else {
            // If all tokens are delegated, there is nothing to check.
            require(true);
        }
    }

    function invariant_DelegatedTokenCantBeTransferred() public {
        (uint256 tkn, address delegatee) = AM.getDelegatedToken();
        if (tkn != 0 && delegatee != address(0)) {
            address owner = collection.ownerOf(tkn);
            vm.startPrank(owner);
            vm.expectRevert();
            collection.transferFrom(owner, SOME_ADDRESS, tkn);
            vm.expectRevert();
            collection.transferFrom(owner, delegatee, tkn);
            vm.stopPrank();
        } else {
            // If no delegations have been made or there are
            // no delegated tokens, there is nothign to check.
            require(true);
        }
    }

    function invariant_DelegatedTokenCantBeBurned() public {
        (uint256 tkn, address delegatee) = AM.getDelegatedToken();
        if (tkn != 0 && delegatee != address(0)) {
            address owner = collection.ownerOf(tkn);
            vm.prank(owner);
            vm.expectRevert();
            collection.burn(tkn);
        } else {
            // If there are no delegated tokens, there is nothing to check.
            require(true);
        }
    }

    function invariant_BurnedTokenCantBeDelegated() public {
        uint256 tkn = AM.getBurnedToken();
        vm.prank(OWNS_NO_TOKENS_ADDRESS);
        vm.expectRevert();
        collection.delegateTo(SOME_ADDRESS, tkn, MAX_AMOUNT_TOKENS_CAN_BE_DELEGATED);
    }
}
