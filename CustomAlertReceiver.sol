// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CustomAlertReceiver {
    event SpikeDetected(string message, uint256 currentBalance, uint256 previousBalance);

    function handleSpike(bytes calldata data) external {
        (uint256 current, uint256 previous) = abi.decode(data, (uint256, uint256));
        string memory message = "Balance spike detected!";
        emit SpikeDetected(message, current, previous);
    }
}
