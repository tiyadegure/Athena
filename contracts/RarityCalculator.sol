// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title RarityCalculator — OpenRarity Information Content
/// @notice Calculates rarity scores from trait probabilities
/// @dev IC = -log2(P), approximated on-chain via bit manipulation
library RarityCalculator {
    /// @notice 9 trait dimensions, each with 4 possible values → 4^9 = 262,144 combinations
    uint256 internal constant TRAIT_DIMENSIONS = 9;
    uint256 internal constant VALUES_PER_TRAIT = 4;

    /// @notice Calculate rarity score from a uint256 seed (18 bits used)
    /// @param seed Encoded trait seed: bits [0:18), each 2-bit field is 0-3
    /// @return score Information Content score (higher = rarer)
    function calculateRarity(uint256 seed) internal pure returns (uint256 score) {
        // Base IC: log2(total_combinations) = log2(262144) = 18
        // This is constant for all tokens. We add bonuses for rare trait values.
        score = 18;

        // Decode each trait and add IC bonus for rare combinations
        for (uint256 i = 0; i < TRAIT_DIMENSIONS; i++) {
            uint8 val = uint8((seed >> (i * 2)) & 0x3);
            // Trait value 3 (last/rarest) gets +2 bonus
            // Trait value 2 gets +1 bonus
            if (val == 3) {
                score += 2;
            } else if (val == 2) {
                score += 1;
            }
        }

        // All-3 bonus (maximum rarity)
        bool allRare = true;
        for (uint256 i = 0; i < TRAIT_DIMENSIONS; i++) {
            if (uint8((seed >> (i * 2)) & 0x3) != 3) {
                allRare = false;
                break;
            }
        }
        if (allRare) {
            score += 10; // Ultra-rare bonus
        }

        // Consecutive rare bonus (3+ consecutive 3s)
        uint256 consecutive = 0;
        uint256 maxConsecutive = 0;
        for (uint256 i = 0; i < TRAIT_DIMENSIONS; i++) {
            if (uint8((seed >> (i * 2)) & 0x3) == 3) {
                consecutive++;
                if (consecutive > maxConsecutive) maxConsecutive = consecutive;
            } else {
                consecutive = 0;
            }
        }
        if (maxConsecutive >= 3) {
            score += maxConsecutive; // Streak bonus
        }
    }

    /// @notice Get tier from rarity score
    /// @param score The rarity score
    /// @return tier 0=S, 1=A, 2=B, 3=C
    function getTier(uint256 score) internal pure returns (uint8 tier) {
        if (score >= 30) return 0; // S tier (~1%)
        if (score >= 25) return 1; // A tier (~9%)
        if (score >= 20) return 2; // B tier (~30%)
        return 3;                    // C tier (~60%)
    }

    /// @notice Get tier name string
    function getTierName(uint8 tier) internal pure returns (string memory) {
        if (tier == 0) return "S";
        if (tier == 1) return "A";
        if (tier == 2) return "B";
        return "C";
    }

    /// @notice Decode seed to 9 trait values
    /// @param seed The encoded seed (18 bits used)
    /// @return traits Array of 9 uint8 values (0-3 each)
    function decodeTraits(uint256 seed) internal pure returns (uint8[9] memory traits) {
        for (uint256 i = 0; i < TRAIT_DIMENSIONS; i++) {
            traits[i] = uint8((seed >> (i * 2)) & 0x3);
        }
    }
}
