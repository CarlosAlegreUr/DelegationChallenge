// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract TestsSettings {
    // ===== GENERAL SETTINGS =====

    string internal constant COLLECTION_NAME = "Test Collection";
    string internal constant COLLECTION_SYMBOL = "TC";

    /// @dev Min amount of users for unit test to pass => 3
    uint256 internal constant AMOUNT_OF_USERS = 50;

    // ===== NFTS MINTED SCENARIO SETTINGS =====

    /// @dev Min amount of ERC721 tokens for unit test to pass => 2
    uint256 internal AMOUNT_OF_TOKENS_TO_MINT_EACH_USER = 55;
}

contract TestUtils is TestsSettings {
    function _getUser(uint256 _userNum) internal pure returns (address) {
        return address(uint160(_userNum));
    }

    function get2DistinctRandomUsersFromFuzz(address u1, address u2) public pure returns (address, address) {
        uint256 rndm1 = uint256(uint160(u1)) % AMOUNT_OF_USERS + 1;
        uint256 rndm2 = uint256(uint160(u2)) % AMOUNT_OF_USERS + 1;
        rndm2 = rndm2 == rndm1 ? (rndm2 + 1) % AMOUNT_OF_USERS + 1 : rndm2;
        /// @dev When downcasting last 160 bits could be 0, we dont want address 0
        uint160 add1 = (uint160(rndm1) == 0) ? uint160(rndm1) + 1 : uint160(rndm1);
        uint160 add2 = (uint160(rndm2) == 0) ? uint160(rndm2) + 1 : uint160(rndm2);
        /// @dev Could happen both where address 0, so we offset both to 1, so now we want 1 to be different and set it to 2.
        rndm2 = rndm2 == rndm1 ? rndm2 + 1 : rndm2;
        return (address(add1), address(add2));
    }

    // add1 and add2 are distinct and inside the address range of AMOUNT_OF_USERS
    function get3rdDistinctAddresFrom(address add1, address add2) public pure returns (address) {
        uint160 nonZeroAddress = uint160(uint256(uint160(add1)) % type(uint256).max + 1);
        nonZeroAddress = (nonZeroAddress == 0) ? nonZeroAddress + 1 : nonZeroAddress;
        // Now we get a non-zero with a valid user address in fuzz
        nonZeroAddress = uint160(nonZeroAddress % AMOUNT_OF_USERS) + 1;

        // We know that add1 != add2 and that minimum modulu will be 3
        address thirdDistinct = address(nonZeroAddress);
        if (thirdDistinct == add1 || thirdDistinct == add2) {
            for (uint256 i = 1; i <= AMOUNT_OF_USERS; i++) {
                thirdDistinct = address(uint160(nonZeroAddress + i % AMOUNT_OF_USERS) + 1);
                if (thirdDistinct != add1 && thirdDistinct != add2) {
                    break;
                }
            }
        }
        return thirdDistinct;
    }

    function getNftFromUser(uint256 numberOfNft, address user) public view returns (uint256) {
        require(numberOfNft > 0, "TEST: Nfts of users numbered starting from 1.");
        require(numberOfNft <= AMOUNT_OF_TOKENS_TO_MINT_EACH_USER, "TEST: Number of NFTs to mint is too high.");
        return uint256(uint160(user)) * AMOUNT_OF_TOKENS_TO_MINT_EACH_USER
            - (AMOUNT_OF_TOKENS_TO_MINT_EACH_USER - numberOfNft);
    }

    function makeSureNumbersAreDifferent(uint256 a, uint256 b, uint256 maxValue)
        public
        pure
        returns (uint256, uint256)
    {
        if (a == b) {
            if (a == maxValue) {
                return (a, a - 1);
            }
            return (a, a + 1);
        } else {
            return (a, b);
        }
    }
}
