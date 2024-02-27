// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️
 * @dev @dev @dev @dev
 *
 * THIS CONTRACT HAS NOT BEEN TESTED OR FULLY
 * IMPLEMENTED. IT IS AN EXAMPLE CONTRACT ON HOW
 * ERCXX WOULD BE IMPLEMENTED WITH OTHER STANDARDS
 * OTHER THAN THE FULLY IMPLEMENTED AND TESTED IN
 * THIS REPO, ERC721
 *
 * @dev @dev @dev @dev
 * ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️
 */
import {ERCXXX} from "./ERCXXX.sol";
import {ERC1155} from "@openzeppelin/token/ERC1155/ERC1155.sol";
import {Arrays} from "@openzeppelin/utils/Arrays.sol";

/**
 * @title ERC1155Delegatable
 * @author @CarlosAlegreUr
 * @notice In this implementation, if transfering more assets than the amount delegated
 * the transaction will revert. A user must make sure he is transfering less tokens than
 * the ones delegated before calling any kind of transfer.
 */
contract ERC1155Delegatable is ERCXXX, ERC1155 {
    using Arrays for uint256[];

    constructor(string memory _uri) ERC1155(_uri) ERCXXX(1155) {}

    /// @dev Depending on how you implement distinction between fungible, semi-fungible and non-fungible
    /// assets this contract might need to override more function from ERCXXX.

    /**
     * @notice Overriden to avoid transfering delegated tokens that could mess up the delegation state.
     * @dev In ERC1155, as there are batched transfers, we need to loop trhough them and check before each one
     * takes place.
     * @dev Notice the `_update()` is exactly the same as OpenZeppelins implementation one but I've added
     * a call to `transferAbidesDelegations()` before each transfer and a call to `batchUndelegateFromAll()`
     * at the end to update properly the delegation states. Furthermore now as the `_balances` mapping is
     * private, I've had to use assembly to access it.
     * @dev If this contract is ever adapted for an Upgradeable version, the assembly used to access storage
     * will have to be changed most probably.
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        virtual
        override
    {
        if (ids.length != values.length) {
            revert ERC1155InvalidArrayLength(ids.length, values.length);
        }

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids.unsafeMemoryAccess(i);
            uint256 value = values.unsafeMemoryAccess(i);

            /// @dev Before each transfer we check if the transfer abides delegations.
            require(transferAbidesDelegations(from, id, value), "Unsafe transfer for delegations detected in batch.");

            if (from != address(0)) {
                uint256 fromBalance = _balanceOf(from, id);
                if (fromBalance < value) {
                    revert ERC1155InsufficientBalance(from, fromBalance, value, id);
                }
                unchecked {
                    /// @dev direct acces to storage slot 0 to acces _balances mapping
                    /// in OZ imlementation it is private so there is no other way to access it.
                    // Overflow not possible: value <= fromBalance
                    // before was => _balances[id][from] = fromBalance - value;
                    _setBalances(id, from, fromBalance - value);
                }
            }

            if (to != address(0)) {
                // before was => _balances[id][to] += value;
                _setBalances(id, from, _balanceOf(from, id) + value);
            }
        }

        if (ids.length == 1) {
            uint256 id = ids.unsafeMemoryAccess(0);
            uint256 value = values.unsafeMemoryAccess(0);
            emit TransferSingle(operator, from, to, id, value);
        } else {
            emit TransferBatch(operator, from, to, ids, values);
        }

        /// @dev Once everything is transfered safely, updare delegations.
        batchUndelegateFromAll(ids);
    }

    /**
     * @notice ERC1155's assets can be fungible, semi-fungible or non-fungible, and the standard
     * does not enforce a specific way of detecting this. Thus this function MUST be overwriten on
     * a per-implementation basis to treat each kind of asset accordingly.
     *
     * @dev To get inspiration on how to treat fungible or semi-fungible assets, check the ERC20Delegatable contract.
     * @dev To get inspiration on how to treat non-fungible assets, check the ERC721Delegatable contract.
     */
    function _ercSpecificValidateDelegation(address _to, uint256 _assetId, uint256 _amount) internal virtual override {}

    /**
     * @notice ERC1155's assets can be fungible, semi-fungible or non-fungible, and the standard
     * does not enforce a specific way of detecting this. Thus this function MUST be overwriten on
     * a per-implementation basis to treat each kind of asset accordingly.
     *
     * @dev To get inspiration on how to treat fungible or semi-fungible assets, check the ERC20Delegatable contract.
     * @dev To get inspiration on how to treat non-fungible assets, check the ERC721Delegatable contract.
     * @dev But ultimately all will depend on how you implement fungible, semi-fungible and non-fungible assets in ERC1155.
     */
    function _ercSpecificValidateUndelegation(address _to, uint256 _assetId, uint256 _amount)
        internal
        virtual
        override
    {}

    /**
     * @return Balance of assets with `assetId` of `_owner`.
     */
    function _balanceOf(address _owner, uint256 _assetId) internal view virtual override returns (uint256) {
        return balanceOf(_owner, _assetId);
    }

    /**
     * @notice A foor loop that calls `undelegateFromAll()` for each `id` in `ids`.
     * Each `id` is an asset id.
     */
    function batchUndelegateFromAll(uint256[] memory _ids) internal virtual {
        for (uint256 i = 0; i < _ids.length; i++) {
            undelegateFromAll(_ids[i]);
        }
    }

    /**
     * @notice Access and writes to slot 0 expecting it to be a `_balances` mapping as the one
     * in OpenZeppelin used implementation of ERC1155.
     */
    function _setBalances(uint256 _id, address _account, uint256 _newValue) private {
        // Calculate the slot for the specific entry in the nested mapping outside of assembly
        uint256 slot =
            uint256(keccak256(abi.encodePacked(_id, uint256(keccak256(abi.encodePacked(_account, uint256(0)))))));

        // Use assembly to perform the storage operation
        assembly {
            sstore(slot, _newValue)
        }
    }
}
