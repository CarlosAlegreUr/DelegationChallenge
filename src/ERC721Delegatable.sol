// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERCXXX} from "./ERCXXX.sol";
import {ERC721} from "@openzeppelin/token/ERC721/ERC721.sol";

/**
 * @title ERC721Delegatable
 * @author @CarlosAlegreUr
 * @notice In this implementation, if transfering more assets than the amount delegated
 * the transaction will revert. A user must make sure he is transfering less tokens than
 * the ones delegated before calling any kind of transfer.
 */
contract ERC721Delegatable is ERCXXX, ERC721 {
    /// @dev The active nonce of the delegator for the general asset type.
    mapping(address => uint256) private s_delegatorToGeneralActiveNonce;

    /// @dev A boolean thah marks if an asset was/is delegated in a specific nonce of a delegator.
    // key is => keccack256(abi.encode(owner, assetId, activeNonceOfOwner))
    mapping(bytes32 => bool) private s_assetIsDelegatedForDelegator;

    mapping(uint256 => address) private s_assetIdToDelegatee;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) ERCXXX(721) {}

    // ========== PUBLIC FUNCTIONS ==========

    /**
     * @notice Updates the general active nonce of the delegator so all previous
     * delegations are revoked.
     */
    function undelegateFromAll(uint256 /*assetId*/ ) public override {
        s_delegatorToGeneralActiveNonce[_msgSender()]++;

        emit NewActiveNonceFor(_msgSender(), getAssetType(), 0, s_delegatorToGeneralActiveNonce[_msgSender()]);
        emit UndelegatedAll(_msgSender(), getAssetType(), 0);
    }

    /**
     * @notice The `_update()` function is called when using any kind of transfer and when minting and burning.
     * @notice The `auth` parameter does not nessesarily have to be the owner of the asset. It could be an approved address.
     */
    function _update(address _to, uint256 _assetId, address auth) internal virtual override returns (address) {
        address superReturned;
        /// @dev This means _update is being called by a minting function
        /// @dev If asset didnt exist couldn't have been delegated.
        if (_to != address(0) && auth == address(0)) {
            superReturned = super._update(_to, _assetId, auth);
        } else {
            address ownerAdd = ownerOf(_assetId);
            /// @dev When transfering or burning we must make sure there are no delegations active
            require(
                transferAbidesDelegations(ownerAdd, _assetId, 1),
                "ERC721Delegatable: Transfer violates delegation amounts"
            );
            superReturned = super._update(_to, _assetId, auth);
            bytes32 key2 =
                _keyForAssetIsDelegatedForDelegatorAtNonce(ownerAdd, _assetId, _getActiveNonce(ownerAdd, _assetId));
            if (s_assetIsDelegatedForDelegator[key2]) {
                undelegateFrom(s_assetIdToDelegatee[_assetId], _assetId, 1);
            }
        }
        return superReturned;
    }

    // ========== INTERNAL FUNCTIONS ==========

    /**
     * @notice Makes sure and NFT is not delegated twice. If not, it reverts.
     */
    function _ercSpecificValidateDelegation(address _to, uint256 _assetId, uint256 /*_amount*/ ) internal override {
        uint256 activeNonce = _getActiveNonce(_msgSender(), _assetId);
        bytes32 key = _keyForDelegatorToDelegateeAmountOfAsset(_msgSender(), _assetId, _to, activeNonce);
        bytes32 key2 = _keyForAssetIsDelegatedForDelegatorAtNonce(_msgSender(), _assetId, activeNonce);

        require(!s_assetIsDelegatedForDelegator[key2], "ERC721Delegatable: Asset is already delegated");
        require(s_delegateeAmountOfAssetId[key] == 1, "ERC721Delegatable: asset is already delegated to delegatee");
        s_assetIsDelegatedForDelegator[key2] = true;
        s_assetIdToDelegatee[_assetId] = _to;
    }

    function _ercSpecificValidateUndelegation(address, /*_to*/ uint256 _assetId, uint256 /*_amount*/ )
        internal
        override
    {
        uint256 activeNonce = _getActiveNonce(_msgSender(), _assetId);
        bytes32 key2 = _keyForAssetIsDelegatedForDelegatorAtNonce(_msgSender(), _assetId, activeNonce);
        delete s_assetIsDelegatedForDelegator[key2];
        delete s_assetIdToDelegatee[_assetId];
    }

    /**
     * @return Returns the active nonce of the delegator for the general asset type.
     */
    function _getActiveNonce(address _owner, uint256 /*_assetId*/ ) internal view override returns (uint256) {
        return s_delegatorToGeneralActiveNonce[_owner];
    }

    // ========== VIEW && PURE FUNCTIONS ==========

    /**
     * See docs at {IERCXXX-transferAbidesDelegations}
     *
     * @notice In only fungible assets standards like ERC721, this function msut be overwritten
     * because the total assets delegated is not required.
     */
    function transferAbidesDelegations(address _from, uint256 _assetId, uint256 _amount)
        public
        view
        override
        returns (bool)
    {
        uint256 activeNonce = _getActiveNonce(_from, _assetId);
        bytes32 key2 = _keyForAssetIsDelegatedForDelegatorAtNonce(_msgSender(), _assetId, activeNonce);

        return (_amount == 1 && 1 == _balanceOf(_from, _assetId) && !s_assetIsDelegatedForDelegator[key2]);
    }

    /**
     * @return True if the `_assetId` is or was delegated by the delegator (`_owner`) at the active nonce.
     */
    function getAssetIsDelegatedForDelegator(address _owner, uint256 _assetId, uint256 _activeNonce)
        external
        view
        returns (bool)
    {
        return
            s_assetIsDelegatedForDelegator[_keyForAssetIsDelegatedForDelegatorAtNonce(_owner, _assetId, _activeNonce)];
    }

    /**
     * @return The delegatee of the asset with id `_assetId`.
     */
    function getDelegateeOfAssetId(uint256 _assetId) external view returns (address) {
        address delegatee = s_assetIdToDelegatee[_assetId];
        if (delegatee != address(0)) {
            address owner = ownerOf(_assetId);
            bytes32 key =
                _keyForDelegatorToDelegateeAmountOfAsset(owner, _assetId, delegatee, _getActiveNonce(owner, _assetId));
            delegatee = s_delegateeAmountOfAssetId[key] == 1 ? delegatee : address(0);
        }
        return delegatee;
    }

    /**
     * @notice The extra checks added to ERC721 are that the general active nonce also mathces
     * the one delegatee has plus it also checks that the `_amount` must be 1 as every asset is unique.
     * @dev If `deleagteTo()` is implemented properly the `_amount` == 1 should not be necessary.
     * @return true if `delegatee` is valid, false otherwise.
     */
    function _ercSpeficicDelegateeChecks(address _assetOwner, address _delegatee, uint256 _assetId, uint256 _amount)
        internal
        view
        override
        returns (bool)
    {
        uint256 activeNonce = _getActiveNonce(_assetOwner, _assetId);
        bytes32 key = _keyForDelegatorToDelegateeAmountOfAsset(_assetOwner, _assetId, _delegatee, activeNonce);
        bytes32 key2 = _keyForAssetIsDelegatedForDelegatorAtNonce(_assetOwner, _assetId, activeNonce);

        /// @dev You might not need && s_assetIsDelegatedForDelegator[_assetId][activeNonce]
        return (s_delegateeAmountOfAssetId[key] == 1 && _amount == 1 && s_assetIsDelegatedForDelegator[key2]);
    }

    /**
     * @return Balance of `assetId` of `_owner`. 1 if `_owner` is the owner of `_assetId`, 0 otherwise.
     */
    function _balanceOf(address _owner, uint256 _assetId) internal view virtual override returns (uint256) {
        return _ownerOf(_assetId) == _owner ? 1 : 0;
    }

    /**
     * @return The key for the mapping `s_assetIsDelegatedForDelegator`.
     */
    function _keyForAssetIsDelegatedForDelegatorAtNonce(address _owner, uint256 _assetId, uint256 _activeNonceOwner)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_owner, _assetId, _activeNonceOwner));
    }
}
