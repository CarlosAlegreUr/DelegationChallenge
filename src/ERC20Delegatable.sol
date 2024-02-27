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
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

/**
 * @title ERC20Delegatable
 * @author @CarlosAlegreUr
 * @notice In this implementation, if transfering more assets than the amount delegated
 * the transaction will revert. A user must make sure he is transfering less tokens than
 * the ones delegated before calling any kind of transfer.
 */
contract ERC20Delegatable is ERCXXX, ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) ERCXXX(20) {}

    /**
     * @notice The `_update()` function is called in any kind of transfe of ERC20 tokens.
     * So, for any transfer to be successful, it must be checked if it complies with delegations.
     */
    function _update(address from, address to, uint256 value) internal override {
        require(transferAbidesDelegations(from, 0, value), "Transfer violates delegations");
        super._update(from, to, value);
        undelegateFromAll(0);
    }

    /**
     * @notice ERC20s dont need this function when implementing ERCXXX
     */
    function _ercSpecificValidateDelegation(address, /*_to*/ uint256, /*_assetId*/ uint256 /*_amount*/ )
        internal
        virtual
        override
    {}

    /**
     * @notice ERC20s dont need this function when implementing ERCXXX
     */
    function _ercSpecificValidateUndelegation(address _to, uint256 _assetId, uint256 _amount)
        internal
        virtual
        override
    {}

    /**
     * @return Balance of `_owner`.
     */
    function _balanceOf(address _owner, uint256 /*_assetId*/ ) internal view virtual override returns (uint256) {
        return balanceOf(_owner);
    }
}
