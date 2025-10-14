// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title WBGZToken
 * @dev An ERC-20 token contract based on OpenZeppelin
 * Includes minting, burning, and pausing functionality, controlled by the owner
 */
contract WBGZToken is ERC20, ERC20Burnable, Ownable, Pausable {
    // Token decimals
    uint8 private _decimals;

    /// @notice Maximum total supply of the token
    uint256 private constant MAX_SUPPLY = 10_000_000 * 1e18;

    /**
     * @notice Initializes the token with custom parameters
     * @dev Constructor
     * @param initialOwner Initial owner address
     * @param decimalsValue Number of decimals for the token
     * @param initialSupply Initial token supply
     */
    constructor(
        address initialOwner,
        uint8 decimalsValue,
        uint256 initialSupply
    ) ERC20(unicode"完璧归赵", unicode"完璧归赵") Ownable(initialOwner) {
        require(initialOwner != address(0), "Invalid owner");
        require(decimalsValue <= 18, "Decimals too high");
        require(initialSupply != 0, "Initial supply must be positive");
        require(initialSupply <= type(uint256).max / (10 ** decimalsValue), "Supply too large");

        _decimals = decimalsValue;

        // Mint initial token supply to the initial owner
        _mint(initialOwner, initialSupply * (10 ** decimalsValue));
    }

    /**
     * @notice Returns the number of decimals used for token
     * @dev Returns the number of decimals used for token
     * @inheritdoc ERC20
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Mint new tokens
     * @dev Mint new tokens
     * @param to Recipient address
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
        _mint(to, amount);
    }

    /**
     * @notice Pause all token transfers
     * @dev Pause all token transfers
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Resume token transfers
     * @dev Resume token transfers
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Override _update function to add pause functionality
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override whenNotPaused {
        super._update(from, to, value);
    }
}