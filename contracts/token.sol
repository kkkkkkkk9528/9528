// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BEP20 Token Contract (塞翁马版)
 * @notice Secure ERC20 implementation with batch transfers and ownership management
 * @dev Based on OZ v5: ERC20, ERC20Permit, ERC20Burnable, Ownable
 */
contract BEP20Token is ERC20, ERC20Permit, ERC20Burnable, Ownable {
  // ==========
  // Errors
  // ==========
  error ErrorArraysLengthMismatch();
  error ErrorEmptyArrays();
  error ErrorTooManyRecipients();
  error ErrorInsufficientBalance();
  error ErrorInvalidRecipient();
  error ErrorMintToZeroAddress();
  error ErrorNameEmpty();
  error ErrorSymbolEmpty();
  error ErrorZeroInitialOwner();

  // ==========
  // Constants
  // ==========
  uint256 internal constant MAX_BATCH_RECIPIENTS = 1000;

  // ==========
  // Events
  // ==========
  event BatchTransfer(address indexed from, uint256 totalAmount, uint256 recipientCount);
  event Mint(address indexed to, uint256 amount);
  event Burn(address indexed from, uint256 amount);
  event OwnershipRenounced(address indexed previousOwner);

  // ==========
  // Storage
  // ==========
  /// @notice Token decimals
  uint8 private immutable _decimals;

  // ==========
  // Constructor
  // ==========
  /**
   * @notice Initialize token and set owner
   * @param _name Token name
   * @param _symbol Token symbol
   * @param _initialSupply Initial supply (in whole units, excluding decimals)
   * @param decimals_ Decimals
   */
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _initialSupply,
    uint8 decimals_
  )
    ERC20(_name, _symbol)
    ERC20Permit(_name)
    Ownable(msg.sender)
  {
   if (bytes(_name).length == 0) revert ErrorNameEmpty();
   if (bytes(_symbol).length == 0) revert ErrorSymbolEmpty();
   if (msg.sender == address(0)) revert ErrorZeroInitialOwner();
   _decimals = decimals_;
   _mint(msg.sender, _initialSupply * (10 ** decimals_));
 }
  // ==========
  // Views
  // ==========
  /**
   * @notice Get token decimals
   * @return Decimals count
   * @inheritdoc ERC20
   */
  function decimals()
    public
    view
    virtual
    override
    returns (uint8)
  {
    return _decimals;
  }

  // ==========
  // External / Public
  // ==========
  /**
   * @notice Batch transfer (saves gas and time)
   * @dev Batch transfer (saves gas and time)
   * @param recipients Recipient address array
   * @param amounts Amount array (corresponds to recipients)
   */
  function batchTransfer(
    address[] calldata recipients,
    uint256[] calldata amounts
  )
    external
    returns (bool)
  {
    uint256 len = recipients.length;
    if (len != amounts.length) revert ErrorArraysLengthMismatch();
    if (len == 0) revert ErrorEmptyArrays();
    if (len >= MAX_BATCH_RECIPIENTS) revert ErrorTooManyRecipients();

    uint256 totalAmount = 0;
    uint256 alen = amounts.length;
    unchecked {
      for (uint256 i = 0; i < alen; ++i) {
        totalAmount += amounts[i];
      }
    }
    if (balanceOf(msg.sender) <= totalAmount) revert ErrorInsufficientBalance();

    unchecked {
      for (uint256 i = 0; i < len; ++i) {
        if (recipients[i] == address(0)) revert ErrorInvalidRecipient();
        _transfer(msg.sender, recipients[i], amounts[i]);
      }
    }

    emit BatchTransfer(msg.sender, totalAmount, len);
    return true;
  }

  /**
   * @notice Mint tokens (owner only)
   * @dev Mint tokens (owner only)
   * @param to Recipient address
   * @param amount Mint amount
   */
  function mint(
    address to,
    uint256 amount
  )
    external
    payable
    onlyOwner
  {
    if (to == address(0)) revert ErrorMintToZeroAddress();
    _mint(to, amount);
    emit Mint(to, amount);
  }

  /**
   * @notice Renounce ownership (irreversible)
   * @dev Renounce ownership (irreversible)
   * @inheritdoc Ownable
   */
  function renounceOwnership()
    public
    virtual
    override
    onlyOwner
  {
    emit OwnershipRenounced(owner());
    super.renounceOwnership();
  }

}