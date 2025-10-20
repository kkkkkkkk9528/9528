// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title NFT 合约（塞翁马版）
 * @notice 使用 OpenZeppelin 的安全 ERC721 实现，支持批量铸造、销毁、暂停、版税
 * @dev 保持原有业务行为不变，仅进行风格与可读性重构；移除 SafeMath（Solidity 0.8+ 原生溢出检查）
 */
contract NFT is ERC721, ERC721URIStorage, ERC721Burnable, Ownable, Pausable {
  // ===========
  // Errors
  // ===========
  error ErrorMintToZeroAddress();
  error ErrorMaxSupplyReached();
  error ErrorInvalidCount();
  error ErrorExceedsMaxSupply();
  error ErrorInvalidReceiver();
  error ErrorFeeTooHigh();
  error ErrorInvalidMaxSupply();

  // ===========
  // Events
  // ===========
  event BatchMint(address indexed to, uint256 startTokenId, uint256 count);
  event BaseURIUpdated(string newBaseURI);
  event MaxSupplyUpdated(uint256 newMaxSupply);
  event RoyaltyInfoUpdated(address receiver, uint96 feeNumerator);
  event OwnershipRenounced(address indexed previousOwner);

  // ===========
  // Storage
  // ===========
  uint256 private _tokenIdCounter;
  string private _baseTokenURI;

  /// @notice 最大供应量（0 表示无限制）
  uint256 public maxSupply;

  /// @notice 版税接收地址
  address public royaltyReceiver;

  /// @notice 版税费率基点（250 = 2.5%）
  uint96 public royaltyFeeNumerator;

  // ===========
  // Constructor
  // ===========
  /**
   * @param _name 名称
   * @param _symbol 符号
   * @param baseURI_ 初始 BaseURI
   * @param _maxSupply 最大供应量（0 为无限制）
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory baseURI_,
    uint256 _maxSupply
  ) ERC721(_name, _symbol) Ownable(msg.sender) {
    _baseTokenURI = baseURI_;
    maxSupply = _maxSupply;
    royaltyReceiver = msg.sender;
    royaltyFeeNumerator = 250; // 默认 2.5%
  }

  // ===========
  // Views
  // ===========
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /// @notice 返回当前总供应量
  function totalSupply() external view returns (uint256) {
    return _tokenIdCounter;
  }

  /**
   * @notice EIP-2981 版税信息
   * @param salePrice 销售价格
   * @return receiver 收款地址
   * @return royaltyAmount 版税金额
   */
  function royaltyInfo(uint256, uint256 salePrice) public view returns (address receiver, uint256 royaltyAmount) {
    royaltyAmount = (salePrice * royaltyFeeNumerator) / 10000;
    receiver = royaltyReceiver;
  }

  // ===========
  // External / Public
  // ===========
  /**
   * @notice 铸造单个 NFT（仅所有者）
   * @param to 接收地址
   * @return tokenId 铸造的 Token ID
   */
  function mint(address to) public onlyOwner returns (uint256 tokenId) {
    if (to == address(0)) revert ErrorMintToZeroAddress();
    if (maxSupply > 0 && _tokenIdCounter >= maxSupply) revert ErrorMaxSupplyReached();

    tokenId = _tokenIdCounter;
    _tokenIdCounter++;
    _safeMint(to, tokenId);
  }

  /**
   * @notice 铸造并设置 URI（仅所有者）
   * @param to 接收地址
   * @param uri Token URI
   * @return tokenId 铸造的 Token ID
   */
  function mintWithURI(address to, string memory uri) public onlyOwner returns (uint256 tokenId) {
    tokenId = mint(to);
    _setTokenURI(tokenId, uri);
  }

  /**
   * @notice 批量铸造（仅所有者）
   * @param to 接收者
   * @param count 数量（1~100）
   * @return tokenIds 铸造的 Token ID 数组
   */
  function batchMint(address to, uint256 count) public onlyOwner returns (uint256[] memory tokenIds) {
    if (to == address(0)) revert ErrorMintToZeroAddress();
    if (count == 0 || count > 100) revert ErrorInvalidCount();

    if (maxSupply > 0 && _tokenIdCounter + count > maxSupply) revert ErrorExceedsMaxSupply();

    uint256 startTokenId = _tokenIdCounter;
    tokenIds = new uint256[](count);

    for (uint256 i = 0; i < count; i++) {
      uint256 tokenId = _tokenIdCounter;
      _tokenIdCounter++;
      _safeMint(to, tokenId);
      tokenIds[i] = tokenId;
    }

    emit BatchMint(to, startTokenId, count);
  }

  /**
   * @notice 批量铸造并设置 URI（仅所有者）
   * @param to 接收者
   * @param uris URI 列表（长度 1~100）
   * @return tokenIds 铸造的 Token ID 数组
   */
  function batchMintWithURIs(address to, string[] memory uris) public onlyOwner returns (uint256[] memory tokenIds) {
    if (to == address(0)) revert ErrorMintToZeroAddress();
    if (uris.length == 0 || uris.length > 100) revert ErrorInvalidCount();

    if (maxSupply > 0 && _tokenIdCounter + uris.length > maxSupply) revert ErrorExceedsMaxSupply();

    uint256 startTokenId = _tokenIdCounter;
    tokenIds = new uint256[](uris.length);

    for (uint256 i = 0; i < uris.length; i++) {
      uint256 tokenId = _tokenIdCounter;
      _tokenIdCounter++;
      _safeMint(to, tokenId);
      _setTokenURI(tokenId, uris[i]);
      tokenIds[i] = tokenId;
    }

    emit BatchMint(to, startTokenId, uris.length);
  }

  /**
   * @notice 设置 Base URI（仅所有者）
   * @param newBaseURI 新的 Base URI
   */
  function setBaseURI(string memory newBaseURI) public onlyOwner {
    _baseTokenURI = newBaseURI;
    emit BaseURIUpdated(newBaseURI);
  }

  /**
   * @notice 设置最大供应量（仅所有者）
   * @param _maxSupply 新的最大供应量
   * @dev 新的最大值必须不小于当前已铸数量，或为 0（不限制）
   */
  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    if (!(_maxSupply == 0 || _maxSupply >= _tokenIdCounter)) revert ErrorInvalidMaxSupply();
    maxSupply = _maxSupply;
    emit MaxSupplyUpdated(_maxSupply);
  }

  /**
   * @notice 设置版税信息（仅所有者）
   * @param receiver 收款地址（不可为零地址）
   * @param feeNumerator 版税基点（<= 10000）
   */
  function setRoyaltyInfo(address receiver, uint96 feeNumerator) public onlyOwner {
    if (receiver == address(0)) revert ErrorInvalidReceiver();
    if (feeNumerator > 10000) revert ErrorFeeTooHigh();
    royaltyReceiver = receiver;
    royaltyFeeNumerator = feeNumerator;
    emit RoyaltyInfoUpdated(receiver, feeNumerator);
  }

  /**
   * @notice 暂停合约（仅所有者）
   */
  function pause() public onlyOwner {
    _pause();
  }

  /**
   * @notice 恢复合约（仅所有者）
   */
  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   * @notice 放弃所有权（不可逆）
   * @dev 放弃所有权（不可逆）
   */
  function renounceOwnership() public virtual override onlyOwner {
    emit OwnershipRenounced(owner());
    super.renounceOwnership();
  }

  // ===========
  // Hooks / Overrides
  // ===========

  /**
   * @notice 返回 Token URI
   * @param tokenId Token ID
   * @return Token URI 字符串
   */
  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  // v5: use _update hook for pause checks; do not override _burn
  function _update(address to, uint256 tokenId, address auth)
    internal
    virtual
    override(ERC721)
    returns (address from)
  {
    require(!paused(), "Pausable: paused");
    return super._update(to, tokenId, auth);
  }



  /**
   * @notice 检查接口支持
   * @param interfaceId 接口 ID
   * @return 是否支持该接口
   */
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }
}