// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️
 * @dev @dev @dev @dev
 *
 * THIS CONTRACT HAS NOT BEEN DEVELOPERD, IT IS A
 * PLAYGROUND TO SHOWCASE THE IDEA BEHIND THE DELWRAP
 * SOLUTION
 * 
 * all the comments in this file are just thoughts during design process
 *
 * @dev @dev @dev @dev
 * ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️
 */
import {delWrap} from "./delWrap.sol";

// -TO-DO-: ponder about implementing with Context from OZ

contract delWrapERC721 is delWrap {
    mapping(uint256 => uint256) public s_delTokenIdToUndelyingTokenId;

    constructor(address _wrappedContract) delWrap(_wrappedContract) {
        // -TO-DO-: initialize in the constructor s_ercSelectorToExtraLogic
    }

    // ============ Delegation functionality funcs ============

    function delegateTo(address _to, bytes memory _data) external override {
        // filter ID from calldata
        s_delTokenIdToUndelyingTokenId[0] = 3;
        // mint delegation token to `_to`
    }

    // ============ PROXY call functions ============

    // it depends on the 3rd party, if they wanna allow delegatees to access
    // their funcs they should not change the implementation address, if yes they
    // just change it. Thus this is a valid thing, collections and services can chose freely
    // wheter to provide the delegeate func or not (collections) and whether to accept delegatees as
    // features consumers (3rd party services)
    // No matter the decison they make, this is compatible with both actors.

    // 3rd party, only if you own 3 of out NFTs, but you want to delegate ones to be considered as
    // owners for this feature (access an event). Thus override.
    function _delBalanceOf() public onlyInternalCall returns (uint256) {}

    // 3rd party is asking, you owner? then pass.
    // If we do this, delegatee can use NFT wherever it is as long as there is not transfer.
    function _delOwnerOf() public onlyInternalCall returns (address) {}
    function _delGetApproved() public onlyInternalCall returns (address) {}
    function _delIsApprovedForAll() public onlyInternalCall returns (bool) {}

    // METADATA EXTENSION COMPATIBLE

    // ENUMERATION EXTENSION NOT COMPATIBLE POSSIBLY

    // needs to add because what if some feature is, we use your 3rd nft, and then you cant cause msg.sender
    // is the delegatee, so now "override" and check if that token is delegated and if so to whom and if so
    // if msg.sender is than whom.
    function _delTokenOfOwnerByIndex(address _owner, uint256 _index) public view onlyInternalCall returns (uint256) {}

    function _delTransferFrom(address _from, address _to, uint256 _tokenId) public onlyInternalCall {}
}

// ## in delwrap
// map id -> delegator -> in owner return yours this can be a problematic as you are saying
// to third parties you are the owner, nono, you should be saying Ima delegatee.


// switch cases with funcs? or mapping like now? what is more gas efficient? should check before, 
// dont have time so but this should be done. Mapping init is more confortable for devs than if else
//  nested or assembly switch case, but is it cheaper? Also mapping allows for simpler abstract delWrap sc.