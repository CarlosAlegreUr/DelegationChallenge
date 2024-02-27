// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title Interface for ERC-XXX Assets Delegation Without Ownership Transfer Standard
 * @author @CarlosAlegreUr
 */
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
