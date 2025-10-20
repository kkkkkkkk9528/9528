// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title BEP20 代币合约（塞翁马版）
 * @notice 使用 OpenZeppelin 的安全 ERC20 实现，提供批量转账、放弃所有权等能力
 * @dev 基于 OZ v5 的 ERC20、ERC20Permit、ERC20Burnable 与 Ownable2Step。
 * @author project team
 */
contract BEP20Token is ERC20, ERC20Permit, ERC20Burnable, Ownable2Step {
  // ===========
  // Errors
  // ===========
  error ErrorArraysLengthMismatch();
  error ErrorEmptyArrays();
  error ErrorTooManyRecipients();
  error ErrorInsufficientBalance();
  error ErrorInvalidRecipient();
  error ErrorApproveToZeroAddress();
  error ErrorApproveNonZeroToNonZero();
  error ErrorDecreasedAllowanceBelowZero();
  error ErrorMintToZeroAddress();
  error ErrorNameEmpty();
  error ErrorSymbolEmpty();
  error ErrorZeroInitialOwner();

  // ===========
  // Constants
  // ===========
  uint256 internal constant MAX_BATCH_RECIPIENTS = 200;

  // ===========
  // Events
  // ===========
  event BatchTransfer(address indexed from, uint256 totalAmount, uint256 recipientCount);
  event Mint(address indexed to, uint256 amount);
  event Burn(address indexed from, uint256 amount);
  event OwnershipRenounced(address indexed previousOwner);

  // ===========
  // Storage
  // ===========
  /// @notice 代币小数位数
  uint8 private immutable _decimals;

  // ===========
  // Constructor
  // ===========
  /**
   * @notice 初始化代币并设置所有者
   * @param _name 代币名称
   * @param _symbol 代币符号
   * @param _initialSupply 初始供应量（以整币单位，不含小数位）
   * @param decimals_ 小数位
   */
  constructor(
   string memory _name,
   string memory _symbol,
   uint256 _initialSupply,
   uint8 decimals_
 ) ERC20(_name, _symbol) ERC20Permit(_name) Ownable(msg.sender) payable {
   if (bytes(_name).length == 0) revert ErrorNameEmpty();
   if (bytes(_symbol).length == 0) revert ErrorSymbolEmpty();
   if (msg.sender == address(0)) revert ErrorZeroInitialOwner();
   _decimals = decimals_;
   _mint(msg.sender, _initialSupply * (10 ** decimals_));
 }
  // ===========
  // Views
  // ===========
  /**
   * @notice 返回代币的小数位
   * @return 小数位数
   * @inheritdoc ERC20
   */
  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  // ===========
  // External / Public
  // ===========
  /**
   * @notice 批量转账（节省 gas 与时间）
   * @dev 批量转账（节省 gas 与时间）
   * @param recipients 接收地址数组
   * @param amounts 金额数组（与 recipients 一一对应）
   */
  function batchTransfer(
    address[] calldata recipients,
    uint256[] calldata amounts
  ) external returns (bool) {
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
   * @notice 铸造代币（仅所有者）
   * @dev 铸造代币（仅所有者）
   * @param to 接收地址
   * @param amount 铸造数量
   */
  function mint(address to, uint256 amount) external payable onlyOwner {
    if (to == address(0)) revert ErrorMintToZeroAddress();
    _mint(to, amount);
    emit Mint(to, amount);
  }

  /**
   * @notice 放弃所有权（不可逆）
   * @dev 放弃所有权（不可逆）
   * @inheritdoc Ownable
   */
  function renounceOwnership() public virtual override onlyOwner {
    emit OwnershipRenounced(owner());
    super.renounceOwnership();
  }

}