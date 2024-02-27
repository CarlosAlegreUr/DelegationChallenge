// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./interfaces/IERCXXX.sol";
import {Context} from "@openzeppelin/utils/Context.sol";

/**
 * @title ERC-XXX Implementation
 * @author @CarlosAlegreUr
 * @notice This is the ERC-XXX implementation abstracted away from any other
 * asset standard it is extending. It is meant to be used as a base contract to inherit from
 * when using other ERC asset standards that wish to implement the delegation extension. And
 * then modify its functons accordingly if needed to guarantee proper functioning.
 */
abstract contract ERCXXX is IERCXXX, Context {
    uint256 immutable ASSET_STANDARD;

    /// @dev owner => assetId => totalAmountDelegated
    mapping(address => mapping(uint256 => uint256)) public s_totalAssetDelegatedOf;

    /// @notice This ERCXXX implementation uses the ActiveNonce concept to manage revokal of delegations
    /// in a cheap scalable way. Basically each owner has a nonce that when delegating is assigned to
    /// the delegatee. Then when the latter wants to use the delegated assets there is a check to that nonce.
    /// If an owner wants to undelegate all users from its assets it just increments the nonce and the equal
    /// nonce check holds no more. Making users will required to be granted delegation again.
    mapping(address => mapping(uint256 => uint256)) internal s_delegatorActiveNonceOfAsset;

    /// @dev The amount a delegatee has been delegated for a specific assetId by a specific owner in a specific nonce.
    // key is => keccack256(abi.encode(owner, assetId, delegatee, activeNonce))
    mapping(bytes32 => uint256) internal s_delegateeAmountOfAssetId;

    /// @dev The last active nonce a delegatee was assinged for an assetId by a specific owner.
    // key is => keccack256(abi.encode(owner, assetId, delegatee))
    mapping(bytes32 => uint256) internal s_delegateeActiveNonceOfAsset;

    /**
     * @notice Emits when an owner undelegates all its assets with the same `assetId`.
     * In case of non-fungible assets, when all assets are undelegated even if they don't share the same id.
     */
    event NewActiveNonceFor(
        address indexed assetOwner, uint256 indexed assetType, uint256 indexed assetId, uint256 newActiveNonce
    );

    constructor(uint256 _assetStandard) {
        ASSET_STANDARD = _assetStandard;
    }

    // ========== PUBLIC FUNCTIONS ==========

    /**
     * See docs at {IERCXXX-delegateTo}
     */
    function delegateTo(address _to, uint256 _assetId, uint256 _amount) public virtual {
        require(_to != address(0), "ERCXXX: delegate to the zero address");
        require(_to != _msgSender(), "ERCXXX: cant delegate to yourself");
        require(_amount <= _balanceOf(_msgSender(), _assetId), "ERCXXX: delegate amount exceeds balance");

        /// @dev notice that the active nonce is the activeNonceOfOwnerForAssetId
        uint256 activeNonce = _getActiveNonce(_msgSender(), _assetId);
        bytes32 key = _keyForDelegatorToDelegateeAmountOfAsset(_msgSender(), _assetId, _to, activeNonce);

        // Update amount delegated to delegatee
        s_delegateeAmountOfAssetId[key] += _amount;

        // Set active nonce of delegatee
        bytes32 key2 = _keyForDelegateeActiveNonceWithDelegatorAndAsset(_msgSender(), _assetId, _to);
        s_delegateeActiveNonceOfAsset[key2] = activeNonce;

        // Update total amount of asset delegated
        s_totalAssetDelegatedOf[_msgSender()][_assetId] += _amount;

        _ercSpecificValidateDelegation(_to, _assetId, _amount);

        emit Delegated(_msgSender(), _to, getAssetType(), _assetId, _amount);
    }

    /**
     * See docs at {IERCXXX-undelegateFrom}
     */
    function undelegateFrom(address _delegatee, uint256 _assetId, uint256 _amount) public virtual {
        require(_delegatee != address(0), "ERCXXX: cant undelegate from the zero address");

        uint256 activeNonce = _getActiveNonce(_msgSender(), _assetId);
        bytes32 key = _keyForDelegatorToDelegateeAmountOfAsset(_msgSender(), _assetId, _delegatee, activeNonce);
        require(_amount <= s_delegateeAmountOfAssetId[key], "ERCXXX: undelegate amount exceeds delegated amount");

        // Update amount delegated to delegatee
        s_delegateeAmountOfAssetId[key] -= _amount;

        // Update total amount of asset delegated
        s_totalAssetDelegatedOf[_msgSender()][_assetId] -= _amount;

        _ercSpecificValidateUndelegation(_delegatee, _assetId, _amount);

        emit Undelegated(_msgSender(), _delegatee, getAssetType(), _assetId, _amount);
    }

    /**
     * See docs at {IERCXXX-undelegateFromAll}
     */
    function undelegateFromAll(uint256 _assetId) public virtual {
        s_delegatorActiveNonceOfAsset[_msgSender()][_assetId]++;
        delete s_totalAssetDelegatedOf[_msgSender()][_assetId];

        emit NewActiveNonceFor(
            _msgSender(), getAssetType(), _assetId, s_delegatorActiveNonceOfAsset[_msgSender()][_assetId]
        );
        emit UndelegatedAll(_msgSender(), getAssetType(), _assetId);
    }

    // ========== INTERNAL FUNCTIONS ==========

    /**
     * @notice This function exists to be overriden in some assets standards.
     * For example in ERC721 this `delegateTo()` function implementation would allow
     * for delegating to multiple people the same NFT or to delegate it twice or more to the
     * same address which must not be done.
     */
    function _ercSpecificValidateDelegation(address _to, uint256 _assetId, uint256 _amount) internal virtual;

    /**
     * @notice This function exists to be overriden in some assets standards. For example in the ones who have
     * only non-fungible tokens like ERC721.
     *
     * In those cases the `undelegateFrom()` function implementation, as every `_assetId` is a unique asset,
     * it can only be delegated to 1 address at a time. Thus, following the general active nonce concept implemented
     * here with mappings where each `assetId` can map to more than 1 amount of asset thus can be delegated to more
     * than 1 addresses can lead to unconsistent state.
     *
     * To easily get around this, the only-fungible standards using this ERCXXX implementation might require extra state to
     * manage properly and cheaply that an `assetId` is delegated only to 1 address during undelegations. As here, the keys
     * of the mappings of general nonces, can't be cleared in a cheap way.
     */
    function _ercSpecificValidateUndelegation(address _to, uint256 _assetId, uint256 _amount) internal virtual;

    // ========== VIEW && PURE FUNCTIONS ==========

    /**
     * See docs at {IERCXXX-isDelegatee}
     */
    function isDelegatee(address _assetOwner, address _delegatee, uint256 _assetId, uint256 _amount)
        public
        view
        virtual
        returns (bool)
    {
        bool ercSpecificChecks = _ercSpeficicDelegateeChecks(_assetOwner, _delegatee, _assetId, _amount);
        //@dev notice here active nonce is activeNonceOfOwnerForAssetId
        uint256 activeNonce = _getActiveNonce(_assetOwner, _assetId);
        bytes32 key = _keyForDelegatorToDelegateeAmountOfAsset(_assetOwner, _assetId, _delegatee, activeNonce);
        bytes32 key2 = _keyForDelegateeActiveNonceWithDelegatorAndAsset(_assetOwner, _assetId, _delegatee);

        return s_delegateeAmountOfAssetId[key] >= _amount && s_delegateeActiveNonceOfAsset[key2] == activeNonce
            && _amount > 0 && ercSpecificChecks;
    }

    /**
     * See docs at {IERCXXX-transferAbidesDelegations}
     *
     * @notice In only fungible assets standards like ERC721, this function msut be overwritten
     * because the total assets delegated is not required.
     */
    function transferAbidesDelegations(address _from, uint256 _assetId, uint256 _amount)
        public
        view
        virtual
        returns (bool)
    {
        return _amount <= _balanceOf(_from, _assetId) - s_totalAssetDelegatedOf[_from][_assetId];
    }

    /**
     * See docs at {IERCXXX-getAmountDelegatedTo}
     */
    function getAmountDelegatedTo(address _assetOwner, address _delegatee, uint256 _assetId)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 activeNonce = _getActiveNonce(_assetOwner, _assetId);
        bytes32 key = _keyForDelegatorToDelegateeAmountOfAsset(_assetOwner, _assetId, _delegatee, activeNonce);
        return s_delegateeAmountOfAssetId[key];
    }

    function getAssetType() public view returns (uint256) {
        return ASSET_STANDARD;
    }

    /**
     * @notice In standards where `_assetId` is the same or the general nonce of owners
     * needs to be overwritten the active nonce will represent the nonce of all assets.
     * @return The active nonce of the delegator (`owner`) for an `_assetId`.
     */
    function getDelegatorActiveNonce(address _owner, uint256 _assetId) external view returns (uint256) {
        return _getActiveNonce(_owner, _assetId);
    }

    /**
     * @return The amount a `delegatee` has been delegated for a specific `assetId` by a specific `owner` in a specific `nonce`.
     */
    function getDelegateeAmountOfAssetId(address _owner, uint256 _assetId, address _delegatee, uint256 _activeNonce)
        external
        view
        returns (uint256)
    {
        bytes32 key = _keyForDelegatorToDelegateeAmountOfAsset(_owner, _assetId, _delegatee, _activeNonce);
        return s_delegateeAmountOfAssetId[key];
    }

    /**
     * @return The last active nonce a `delegatee` was assinged for an `assetId` by a specific `owner`.
     */
    function getDelegateeActiveNonceOfAsset(address _owner, uint256 _assetId, address _delegatee)
        external
        view
        returns (uint256)
    {
        bytes32 key = _keyForDelegateeActiveNonceWithDelegatorAndAsset(_owner, _assetId, _delegatee);
        return s_delegateeActiveNonceOfAsset[key];
    }

    /**
     * @return The active nonce of `_owner` for `_assetId`.
     */
    function _getActiveNonce(address _owner, uint256 _assetId) internal view virtual returns (uint256) {
        return s_delegatorActiveNonceOfAsset[_owner][_assetId];
    }

    /**
     * @notice This function exists to be overriden in some assets standards. Like in only non-fungible
     * assets standards like ERC721 where there is an extra general active nonce that must be checked.
     * @return true if the delegatee is valid, false otherwise.
     */
    function _ercSpeficicDelegateeChecks(
        address, /*_assetOwner*/
        address, /*_delegatee*/
        uint256, /*_assetId*/
        uint256 /*_amount*/
    ) internal view virtual returns (bool) {
        return true;
    }

    /**
     * @notice Not all ERCs asset standards have the same way of checking balances.
     * For example in the default ERC721 there is no `balanceOf()` function, but a `ownerOf()`
     * that can be used if the `_assetId` is part of the balance of `_owner`.
     * @return Amount of assets with `_assetId` that `_owner` owns.
     */
    function _balanceOf(address _owner, uint256 _assetId) internal view virtual returns (uint256);

    /**
     * @return The key for the mapping `s_delegatorToDelegateeAmountOfAsset`.
     */
    function _keyForDelegatorToDelegateeAmountOfAsset(
        address _owner,
        uint256 _assetId,
        address _delegatee,
        uint256 _activeNonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_owner, _assetId, _delegatee, _activeNonce));
    }

    /**
     * @return The key for the mapping `s_delegateeActiveNonceOfAsset`.
     */
    function _keyForDelegateeActiveNonceWithDelegatorAndAsset(address _owner, uint256 _assetId, address _delegatee)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_owner, _assetId, _delegatee));
    }
}
