# ERC-XXX: Assets Delegation Without Ownership Transfer Standard

## Table of Contents

- [ERC-XXX: Assets Delegation Without Ownership Transfer Standard](#erc-xxx-assets-delegation-without-ownership-transfer-standard)
  - [Table of Contents](#table-of-contents)
  - [Simple Summary](#simple-summary)
  - [Abstract](#abstract)
  - [Motivation](#motivation)
  - [Specification](#specification)
  - [Implementation Caveats](#implementation-caveats)
  - [Rationale](#rationale)
  - [Usage \&\& Implementations](#usage--implementations)
  - [Backwards Compatibility](#backwards-compatibility)

## Simple Summary

A new standard that defines delegation functionality abstracted away from the asset standard used.

## Abstract

This standard defines a general API to delegate the use of an asset without having to transfer the ownership of the asset. This is useful for applications like renting assets or assets management and delegation of votes. 

## Motivation

A standard API for delegating assets would allow for simpler dev experience as they would not have to worry about function names or mechanics in systems that require delegation of multiple kinds of assets.

This is specially useful in gaming where you might have different kinds of assets that you want to delegate in some sort of renting or lending mechanic: lend/rent a whole player as an NFT, or some semi-fungible tokens like weapons or even votes inside an internal democracy system.

In general this ERC can streamline the development of applications that have features only available to holders of specific assets and users with rentals of specific assets in specific amounts.

## Specification

**Smart Contracts implementing ERCXXX MUST implement all functions and events defined in the following interface.**

```solidity
interface IERCXXX {
    /**
     * @notice Event MUST be emitted when an asset is delegated on `delegateTo()`.
     * @param from  Owner of the asset.
     * @param to Address the asset is being delegated to (delegatee).
     * @param assetType ERC's number that defines the standard the asset follows (if asset is ERC20 => assetType == 20).
     * @param assetId The id of the token being delegated for non-fungible or semi-fungible assets. `assetId`
     * in only-fungible assets standards it can be whatever you want but MUST be the same id number in all calls to ERCXXX functions.
     * @param amount The amount of assets being delegated to `to`. For non-fungible assets this value MUST always be 1.
     */
    event Delegated(
        address indexed from, address indexed to, uint256 indexed assetType, uint256 assetId, uint256 amount
    );

    /**
     * @notice Event MUST be emitted when an asset is undelegated on `undelegateFrom()`.
     * @param from  Owner of the asset.
     * @param to Address the asset is being undelegated from (delegatee).
     * @param assetType See assetType param description in `Delegated()` event.
     * @param assetId See assetId param description in `Delegated()` event.
     * @param amount The amount of assets being undelegated from `to`. For non-fungible assets this value MUST always be 1.
     */
    event Undelegated(
        address indexed from, address indexed to, uint256 indexed assetType, uint256 assetId, uint256 amount
    );

    /**
     * @notice Event MUST be emitted when all assets with the same `assetId` are undelegated on `undelegateFromAll(assetId)`.
     * For non-fungible assets this event MUST also be emitted even though the assets might have different ids.
     * @param owner Owner of the asset(s).
     * @param assetType See assetType param description in `Delegated()` event.
     * @param assetId See assetId param description in `Delegated()` event. On top of that, for this event and non-fungible
     * assets this parameter MUST be ignored and CAN be set to anything.
     */
    event UndelegatedAll(address indexed owner, uint256 indexed assetType, uint256 indexed assetId);

    /**
     * @notice Delegates `amount` of assets with `assetId` to `to` address.
     * @dev msg.sender MUST be the owner of the asset(s) and have enuough `amount` of asset(s).
     * @dev If `to` is the zero address it MUST revert.
     * @dev You MUST NOT be able to delegate to yourself.
     * @param to Addres the asset(s) will be delegated to (delegatee).
     * @param assetId See assetId param description in `Delegated()` event.
     * @param amount See amount param description in `Delegated()` event.
     */
    function delegateTo(address to, uint256 assetId, uint256 amount) external;

    /**
     * @notice Undelegates `amount` of assets with `assetId` from `delegatee` address.
     * @dev msg.sender MUST be the owner of the asset(s) and have enuough delegated `amount` to undelegate.
     * @dev If `delegatee` is the zero address it MUST revert. 
     * @param delegatee Address from which the asset(s) will be undelegated from.
     * @param assetId See assetId param description in `Delegated()` event.
     * @param amount See amount param description in `Undelegated()` event.
     */
    function undelegateFrom(address delegatee, uint256 assetId, uint256 amount) external;

    /**
     * @notice Undelegates all assets with the same `assetId` from all delegatees that msg.sender delegated to.
     * For non-fungibe assets, the `assetId` MUST be ignored and just undeleagte from all delegatees all non-fungible asets
     * delegated.
     * @param assetId See assetId param description in `Delegated()` event.
     */
    function undelegateFromAll(uint256 assetId) external;

    /**
     * @notice This function MUST be called before any transfer of assets or balances change to check if the transfer is safe.
     * Safe means checking for not transfering any asset that has been delegated. Transfer of delegated tokens
     * MUST be avoided to avoid unexpected allowed delegations for the new owner and outdated delegations states
     * for old owners.
     * @param assetId See assetId param description in `Delegated()` event.
     * @param amount Amount to be transferred.
     * @return true if the transfer is safe, false otherwise.
     */
    function transferAbidesDelegations(address from, uint256 assetId, uint256 amount) external returns (bool);

    /**
     * @notice Checks if `delegatee` is a valid delegatee of `assetOwner` for an `assetId` and `amount`.
     * @dev For a `delegatee` to be valid it MUST have AT LEAST `amount` or MORE of `assetId` delegated by `assetOwner`.
     * @dev For non-fungible tokens an `amount` > 1 MUST always return false.
     * @dev Any `amount` of 0 MUST return false.
     * @param assetOwner Owner of the asset(s).
     * @param delegatee Address to check if it is a delegatee of `assetOwner`.
     * @param assetId See assetId param description in `Delegated()` event.
     * @param amount Amount to check if it has been delegated to `delegatee`.
     * @return true if `delegatee` is a valid, false otherwise or on 0 `amount`.
     */
    function isDelegatee(address assetOwner, address delegatee, uint256 assetId, uint256 amount)
        external
        view
        returns (bool);

    /**
     * @notice Returns the amount of assets delegated to `delegatee` by `assetOwner` for `assetId`.
     * @dev For non-fungible tokens this function MUST always return 1 or 0.
     * @param assetOwner See assetOwner param description in `isDelegatee()` function.
     * @param delegatee See delegatee param description in `isDelegatee()` function.
     * @param assetId See assetId param description in `Delegated()` event.
     * @return The amount of assets delegated to `delegatee` by `assetOwner` for `assetId`.
     */
    function getAmountDelegatedTo(address assetOwner, address delegatee, uint256 assetId)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the asset type of the contract. For example, if the contract is an ERC20, it MUST return 20.
     * If the contract extends an ERC1155, it MUST return 1155 and so on.
     * @return The asset type of the contract.
     */
    function getAssetType() external view returns (uint256);
}
```

## Implementation Caveats

- **Compatibility considerations**: All functions in the above interface are marked as `external` because solidity forces you to mark them as so when defining interfaces. Notice that implementaion-wise they can be changed to public anytime if future asset standards require it so.

Also for starndards that support batch transfers (like ERC1155), ERCXXX does not enforce a way of handling them, it is recommended to sum the amounts of all assets being transferred and call `transferAbidesDelegations()` with the total amount for each asset.

- **Security considerations** when interacting on top of an ERCXXX assets contract:

    - Safe transfers on the state management of delegated assets: When transferring ERCXXX assets the owner MUST NOT have more delegated assets than the ones being transferred. This is to avoid unexpected inconsitent delegation states with the new owner and outdated delegation states with the old owner. However, a bad implementation of this ERC might not use the `transferAbidesDelegations()` function properly. Its the responsibility of the protocol or user interacting with ERCXXX tokens to check its code and verify that the transfer is safe with delegations' state.

    - ERCXXX can be build on top of other ERCs asset standards that allow for reentrancy risks like ERC777 for example. In general any inherent risks some asset standards have are also inherited by ERCXXX.

- **Implementation choices**: They are left to the user as there is no straight right answer to solve the scenarios.
  
  - Suppose that you have 50 tokens and you delegate 10 to `user1` and 10 to `user2`. Then you transfer 31 tokens. You are transfering 31 tokens that means that at least 1 of those tokens is a delegated one. So, who do you undelegate from to keep the state consistent?

    You can opt to just `undelegateFromAll()` and then transfer, or maybe opt to let the user
    decide which address to undelegate 1 token from with `undelegateFrom()`. This leads to implementation specific choices but you MUST never transfer any amount of delegated token(s).

  - You can decide if to allow or not delegation or undelegation of 0 amounts. It is recommended to allow it to avoid DOS potential but depending on the implementation it might be better to not allow it if it consumes unnecessary storage. On the implementations linked in the **Usage && Implementations** section, it is allowed as
    it does not cosume unnecessary storage, if something a user would just be wasting gas to execute the functions.

## Rationale

Rational behind non-obvious MUSTs and MUST NOTSs:

- Events must be emitted so the contracts' state are easily auditable and trackable.
- For only-fungible token standards the `assetId` can be whatever you want but it MUST be the same id number in all calls to ERCXXX functions. This is to make sure developers dont have to worry about contract state assigned to more than 1 assetId when its not needed.
- In only-non-fungible token standards (like ERC721) amounts of assetIds being operated on must always be 1 as they are by definition unique. This should avoid prolems with double counting or not counting at all.
- You MUST NOT be able to delegate to yourself. The operation itself makes no sense and if allowed could create more complex undesired scenatios to handle.
- isDelegatee MUST return false on 0 amount. This is to avoid possible DOS potential if it was forced to revert, and thus allow users to implement their own error handling.
- delegateTo() and undelegateFrom(): The `to` and `delegatee` addresses MUST not be the zero address to avoid unnecessary events and contract state usage.



## Usage && Implementations

See a scalable and efficient examples of:
 - ERCXXX [here](../src/ERCXXX.sol).
 - ERCXXX extending ERC721 [here](../src/ERC721Delegatable.sol).

See a draft and prototype of how ERCXXX could be implemented on top of other asset standards:
 - Extending ERC20 [here](../src/ERC20Delegatable.sol).
 - Extending ERC1155 [here](../src/ERC1155Delegatable.sol).

## Backwards Compatibility

ERCXXX can only be added to assets of any standard deployed behind upgradeable contracts.

If your contract is not deployed in an upgradeable manner you will have to rewrite and
redeploy your contract to be able to use ERCXXX on it.
