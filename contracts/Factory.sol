// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./token.sol";

/**
 * @title Factory
 * @dev Factory contract for deploying WBGZToken using CREATE2
 */
contract WBGZFactory {
    event WBGZTokenDeployed(address indexed tokenAddress, address indexed initialOwner, uint8 decimalsValue, uint256 initialSupply, bytes32 salt);

    /**
     * @notice Deploys a new WBGZToken contract using CREATE2
     * @param initialOwner The initial owner of the token
     * @param decimalsValue The number of decimals for the token
     * @param initialSupply The initial supply of the token
     * @param salt A unique salt for CREATE2 deployment
     * @return tokenAddress The address of the deployed token
     */
    function deployWBGZToken(
        address initialOwner,
        uint8 decimalsValue,
        uint256 initialSupply,
        bytes32 salt
    ) external returns (address tokenAddress) {
        // Get the bytecode of WBGZToken
        bytes memory bytecode = type(WBGZToken).creationCode;

        // Encode the constructor arguments
        bytes memory encodedArgs = abi.encode(initialOwner, decimalsValue, initialSupply);

        // Append the encoded arguments to the bytecode
        bytes memory fullBytecode = abi.encodePacked(bytecode, encodedArgs);

        // Deploy using CREATE2
        assembly {
            tokenAddress := create2(0, add(fullBytecode, 0x20), mload(fullBytecode), salt)
        }

        // Check if deployment was successful
        require(tokenAddress != address(0), "Deployment failed");

        // Emit event
        emit WBGZTokenDeployed(tokenAddress, initialOwner, decimalsValue, initialSupply, salt);
    }

    /**
     * @notice Computes the address of a WBGZToken contract that would be deployed with the given parameters
     * @param initialOwner The initial owner of the token
     * @param decimalsValue The number of decimals for the token
     * @param initialSupply The initial supply of the token
     * @param salt A unique salt for CREATE2 deployment
     * @return The computed address
     */
    function getWBGZTokenAddress(
        address initialOwner,
        uint8 decimalsValue,
        uint256 initialSupply,
        bytes32 salt
    ) external view returns (address) {
        // Get the bytecode of WBGZToken
        bytes memory bytecode = type(WBGZToken).creationCode;

        // Encode the constructor arguments
        bytes memory encodedArgs = abi.encode(initialOwner, decimalsValue, initialSupply);

        // Append the encoded arguments to the bytecode
        bytes memory fullBytecode = abi.encodePacked(bytecode, encodedArgs);

        // Compute the address using CREATE2 formula
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(fullBytecode)
            )
        );

        return address(uint160(uint256(hash)));
    }
}