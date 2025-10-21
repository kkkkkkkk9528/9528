// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BEP20Token} from "./token.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title 确定性 CREATE2 工厂
/// @notice 地址公式：address = keccak256(0xff, factory, salt, keccak256(creationCode+abi.encode(args)))[12:]
contract Factory is Ownable(msg.sender) {
  event TokenDeployed(address indexed addr, bytes32 indexed salt);

  /// @dev 通过 CREATE2 的 new{salt}
  function deployToken(
    bytes32 salt,
    string memory name,
    string memory symbol,
    uint256 supply,
    uint8 decimals
  ) external payable onlyOwner returns (address addr) {
    BEP20Token tok = new BEP20Token{salt: salt}(name, symbol, supply, decimals);

    // 立即把 owner 转给部署人（msg.sender）
    tok.transferOwnership(msg.sender);

    addr = address(tok);
    emit TokenDeployed(addr, salt);
  }

  /// @notice 计算在本工厂地址下、给定构造参数与 salt 的代币地址（与离线计算一致）
  function computeTokenAddress(
    bytes32 salt,
    string memory name,
    string memory symbol,
    uint256 supply,
    uint8 decimals
  ) external view returns (address) {
    bytes memory init = abi.encodePacked(type(BEP20Token).creationCode, abi.encode(name, symbol, supply, decimals));
    bytes32 initHash = keccak256(init);
    return address(uint160(uint(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, initHash)))));
  }

  /// @notice 仅返回 initCodeHash，便于前端/脚本与本地计算比对
  function computeInitCodeHash(
    string memory name,
    string memory symbol,
    uint256 supply,
    uint8 decimals
  ) external pure returns (bytes32) {
    bytes memory init = abi.encodePacked(type(BEP20Token).creationCode, abi.encode(name, symbol, supply, decimals));
    return keccak256(init);
  }
}