// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DCollection} from "../../../src/DCollection.sol";
import {console} from "forge-std/Test.sol";

import {InvariantConstants} from "../InvariantConstants.sol";

/**
 * @notice Storage of the following contract, collapse in VSCode for better view.
 */
contract AMStorage {
    struct ActorHistorical {
        address actor;
        uint256 amountOwned;
        uint256 amountDelegated;
        uint256 amountNotDelegated;
    }

    address[] public actors;
    mapping(address => uint256) public indexUsrActors;
    mapping(address => uint256[]) public assetsOfActor;

    // Must have minted and not delegated token
    address[] public actorsCanBurn;
    mapping(address => uint256) public indexUsrCanBurn;
    mapping(uint256 => bool) public tknCanBurn;
    mapping(uint256 => bool) public tknIsBurn;

    // Must have a token, must be undelegated token
    address[] public actorsCanDelegate;
    mapping(address => uint256) public indexUsrCanDelegate;
    mapping(uint256 => bool) public tknCanUndelegate;

    // Must have token and must be delegated token
    address[] public actorsCanUndelegate;
    mapping(address => uint256) public indexUsrCanUndelegate;

    // Must have token and must be not delegated token
    address[] public actorsCanTransfer;
    mapping(address => uint256) public indexUsrCanTransfer;
}

/**
 * @dev Keeps track of all actors interacting with contract and its data
 * when invariant testing.
 */
contract ActorManagerERC721DelegatableTest is AMStorage, InvariantConstants {
    DCollection public immutable COLLECTION;

    constructor(address _collection) {
        COLLECTION = DCollection(_collection);
        // Push address 0 to indexUsr 0 of arrays to use as empty value
        actors.push(address(0));
        actorsCanDelegate.push(address(0));
        actorsCanUndelegate.push(address(0));
        actorsCanBurn.push(address(0));
        actorsCanTransfer.push(address(0));
    }

    mapping(address => ActorHistorical) public actorHistorical;

    // ============ MINT CONTROLLERS ============

    function controller_mintAction(address _actor, uint256 _nftMinted) public {
        _actor = _actor == address(0) ? FALLBACK_ADDRESS_IF_RNDM_USER_INVALID : _actor;
        _actor = _actor == OWNS_NO_TOKENS_ADDRESS ? FALLBACK_ADDRESS_IF_RNDM_USER_INVALID : _actor;
        _addIfNewActor(_actor);

        actorHistorical[_actor].amountOwned++;
        actorHistorical[_actor].amountNotDelegated++;
        assetsOfActor[_actor].push(_nftMinted);
        tknCanBurn[_nftMinted] = true;

        _addToIndexUsersCanIfNotIn(_actor, actorsCanBurn, indexUsrCanBurn);
        _addToIndexUsersCanIfNotIn(_actor, actorsCanTransfer, indexUsrCanTransfer);
        _addToIndexUsersCanIfNotIn(_actor, actorsCanDelegate, indexUsrCanDelegate);
    }

    // ============ BURN CONTROLLERS ============

    function controller_burnActionBefore(uint256 _actor)
        public
        view
        returns (address _validActor, uint256 _assetId, bool _canProceedWithoutRevert)
    {
        _validActor = _getRandomActorFromValidActorsArray(actorsCanBurn, _actor);
        _assetId = _loopAndGetAssetTrue(assetsOfActor[_validActor], tknCanBurn);
        _canProceedWithoutRevert = _validActor != address(0) && _assetId != 0;
    }

    function controller_burnActionAfter(address _actor, uint256 _nftId) public {
        actorHistorical[_actor].amountOwned--;
        actorHistorical[_actor].amountNotDelegated--;
        tknCanBurn[_nftId] = false;
        tknIsBurn[_nftId] = true;
        _popFromArray(_nftId, assetsOfActor[_actor]);

        if (actorHistorical[_actor].amountOwned == 0 || actorHistorical[_actor].amountNotDelegated == 0) {
            _popFromArrayDeleteIndexMapping(_actor, actorsCanBurn, indexUsrCanBurn);
        }
    }

    // ============ DELEGATE CONTROLLERS ============

    function controller_delegateToActionBefore(uint256 _actor)
        public
        view
        returns (address _validActor, uint256 _assetId, bool _canProceedWithoutRevert)
    {
        _validActor = _getRandomActorFromValidActorsArray(actorsCanDelegate, _actor);
        _assetId = _loopAndGetAssetTrue(assetsOfActor[_validActor], tknCanBurn);
        _canProceedWithoutRevert = _validActor != address(0) && _assetId != 0;
    }

    function controller_delegateToActionAfter(address _delegator, uint256 _nftId) public {
        actorHistorical[_delegator].amountDelegated++;
        actorHistorical[_delegator].amountNotDelegated--;

        _addToIndexUsersCanIfNotIn(_delegator, actorsCanUndelegate, indexUsrCanUndelegate);

        tknCanBurn[_nftId] = false;
        tknCanUndelegate[_nftId] = true;

        // If you delegated your last token, you cant transfer or burn
        if (actorHistorical[_delegator].amountNotDelegated == 0) {
            _popFromArrayDeleteIndexMapping(_delegator, actorsCanTransfer, indexUsrCanTransfer);
            _popFromArrayDeleteIndexMapping(_delegator, actorsCanBurn, indexUsrCanBurn);
        }
    }

    // ============ UNDELEGATE CONTROLLERS ============

    function controller_undelegateFromActionBefore(uint256 _actor)
        public
        view
        returns (address _validActor, address _validDelegatee, uint256 _assetId, bool _canProceedWithoutRevert)
    {
        _validActor = _getRandomActorFromValidActorsArray(actorsCanUndelegate, _actor);
        _assetId = _loopAndGetAssetTrue(assetsOfActor[_validActor], tknCanUndelegate);
        _validDelegatee = COLLECTION.getDelegateeOfAssetId(_assetId);
        _canProceedWithoutRevert = _validActor != address(0) && _assetId != 0 && _validDelegatee != address(0);
    }

    function controller_undelegateFromActionAfter(address _delegator, uint256 _nftId) public {
        actorHistorical[_delegator].amountDelegated--;
        actorHistorical[_delegator].amountNotDelegated++;

        _addToIndexUsersCanIfNotIn(_delegator, actorsCanDelegate, indexUsrCanDelegate);
        _addToIndexUsersCanIfNotIn(_delegator, actorsCanTransfer, indexUsrCanTransfer);
        _addToIndexUsersCanIfNotIn(_delegator, actorsCanBurn, indexUsrCanBurn);

        // If you undelegated your last delegated token you cant undelegate
        if (actorHistorical[_delegator].amountDelegated == 0) {
            _popFromArrayDeleteIndexMapping(_delegator, actorsCanUndelegate, indexUsrCanUndelegate);
        }

        tknCanBurn[_nftId] = true;
        tknCanUndelegate[_nftId] = false;
    }

    // ============ UNDELEGATE FROM ALL CONTROLLERS ============

    function controller_undelegateFromAllActionBefore(uint256 _actor)
        public
        view
        returns (address _validActor, bool _canProceedWithoutRevert)
    {
        _validActor = _getRandomActorFromValidActorsArray(actorsCanUndelegate, _actor);
        _canProceedWithoutRevert = _validActor != address(0);
    }

    function controller_undelegateFromAllActionAfter(address _delegator) public {
        actorHistorical[_delegator].amountNotDelegated += actorHistorical[_delegator].amountDelegated;
        actorHistorical[_delegator].amountDelegated = 0;

        _addToIndexUsersCanIfNotIn(_delegator, actorsCanDelegate, indexUsrCanDelegate);
        _addToIndexUsersCanIfNotIn(_delegator, actorsCanTransfer, indexUsrCanTransfer);
        _addToIndexUsersCanIfNotIn(_delegator, actorsCanBurn, indexUsrCanBurn);

        // If you undelegated all your delegated tokens you cant undelegate
        _popFromArrayDeleteIndexMapping(_delegator, actorsCanUndelegate, indexUsrCanUndelegate);

        uint256[] memory delegatorTokens = assetsOfActor[_delegator];
        for (uint256 i = 0; i < delegatorTokens.length; i++) {
            tknCanBurn[delegatorTokens[i]] = true;
            tknCanUndelegate[delegatorTokens[i]] = false;
        }
    }

    // ============ TRANSFER CONTROLLERS ============

    function controller_transferActionBefore(uint256 _actor)
        public
        view
        returns (address _validActor, address _to, uint256 _assetId, bool _canProceedWithoutRevert)
    {
        _validActor = _getRandomActorFromValidActorsArray(actorsCanTransfer, _actor);
        _to = _getRandomAddressDifferentThan(_actor, _validActor);
        // if it can burn it can be transfered as its not delegated
        _assetId = _loopAndGetAssetTrue(assetsOfActor[_validActor], tknCanBurn);
        // note the _to address = 0 should not be necessary check later, same in undeleagte func
        _canProceedWithoutRevert = _validActor != address(0) && _assetId != 0 && _to != address(0);
    }

    function controller_transferActionAfter(address _sender, address _to, uint256 _nftId) public {
        actorHistorical[_sender].amountOwned--;
        actorHistorical[_to].amountOwned++;

        actorHistorical[_sender].amountNotDelegated--;
        actorHistorical[_to].amountNotDelegated++;

        _popFromArray(_nftId, assetsOfActor[_sender]);
        assetsOfActor[_to].push(_nftId);

        // If you transferred your last token, you cant transfer or burn
        if (actorHistorical[_sender].amountOwned == 0) {
            _popFromArrayDeleteIndexMapping(_sender, actorsCanTransfer, indexUsrCanTransfer);
            _popFromArrayDeleteIndexMapping(_sender, actorsCanBurn, indexUsrCanBurn);
        }

        // If to received his first token he can burn, tranfer or delegate
        if (actorHistorical[_to].amountOwned == 1) {
            _addToIndexUsersCanIfNotIn(_to, actorsCanTransfer, indexUsrCanTransfer);
            _addToIndexUsersCanIfNotIn(_to, actorsCanBurn, indexUsrCanBurn);
            _addToIndexUsersCanIfNotIn(_to, actorsCanDelegate, indexUsrCanDelegate);
        }
    }

    // ============ UTILS ============

    function _loopAndGetAssetTrue(uint256[] memory _array, mapping(uint256 => bool) storage _map)
        private
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_map[_array[i]]) {
                return _array[i];
            }
        }
        return 0; // Valid for this collection as asset 0 does not exist
    }

    function _getRandomActorFromValidActorsArray(address[] memory _arr, uint256 _actor)
        private
        pure
        returns (address _validActor)
    {
        // not > 1 because 0 is empty value
        if (_arr.length >= 2) {
            uint256 rndmValidActorIndex = _actor % _arr.length;
            rndmValidActorIndex = rndmValidActorIndex == 0 ? 1 : rndmValidActorIndex;
            _validActor = _arr[rndmValidActorIndex];
        } else {
            _validActor = address(0);
        }
    }

    function _getRandomAddressDifferentThan(uint256 _rndmNum, address _differentThan)
        private
        pure
        returns (address _newAdd)
    {
        // non-zero
        _newAdd = address(uint160(_rndmNum) % type(uint160).max + 1);
        uint256 i = 2;
        while (_newAdd == _differentThan) {
            _newAdd = address(uint160(_rndmNum % i) % type(uint160).max + 1);
            i++;
        }
    }

    function _popFromArrayDeleteIndexMapping(
        address _actor,
        address[] storage _array,
        mapping(address => uint256) storage _indexMap
    ) private {
        address prevActorAtLastIndex = _array[_array.length - 1];
        _array[_indexMap[_actor]] = _array[_array.length - 1];
        _array.pop();
        _indexMap[prevActorAtLastIndex] = _indexMap[_actor];
        _indexMap[_actor] = 0;
    }

    function _popFromArray(uint256 _value, uint256[] storage _arr) private {
        for (uint256 i = 0; i < _arr.length; i++) {
            if (_arr[i] == _value) {
                _arr[i] = _arr[_arr.length - 1];
                _arr.pop();
                break;
            }
        }
    }

    function _addIfNewActor(address _actor) private {
        if (actorHistorical[_actor].actor == address(0)) {
            actorHistorical[_actor].actor = _actor;
            actors.push(_actor);
        }
    }

    function _addToIndexUsersCanIfNotIn(
        address actor,
        address[] storage _usersCan,
        mapping(address => uint256) storage _indexMap
    ) private {
        if (_indexMap[actor] == 0) {
            _usersCan.push(actor);
            _indexMap[actor] = _usersCan.length - 1;
        }
    }

    /// @dev The following functions uneffiient loops. If ever needed more intense testing they should be optimized.

    function getDelegatedToken() external view returns (uint256 delegatedNft, address delegatee) {
        for (uint256 i = 1; i < COLLECTION.s_nextId(); i++) {
            if (tknCanUndelegate[i]) {
                delegatedNft = i;
                delegatee = COLLECTION.getDelegateeOfAssetId(i);
                break;
            }
        }
    }

    function getNotDelegatedToken() external view returns (uint256 delegatedNft) {
        for (uint256 i = 1; i < COLLECTION.s_nextId(); i++) {
            if (!tknCanUndelegate[i] && !tknIsBurn[i]) {
                delegatedNft = i;
                break;
            }
        }
    }

    function getBurnedToken() external view returns (uint256 burnNft) {
        for (uint256 i = 1; i < COLLECTION.s_nextId(); i++) {
            if (tknIsBurn[i]) {
                burnNft = i;
                break;
            }
        }
    }
}
