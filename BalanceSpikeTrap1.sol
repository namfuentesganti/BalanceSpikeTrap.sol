// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

contract BalanceSpikeTrap is ITrap {
    function collect() external view override returns (bytes memory) {
        return abi.encode(block.number); // отслеживаем номер блока
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) return (false, "Insufficient data");

        uint256 currentBlock = abi.decode(data[0], (uint256));
        uint256 previousBlock = abi.decode(data[1], (uint256));

        // Срабатывает при любом новом блоке (или можно изменить на раз в 2-3 блока)
        if ((currentBlock - previousBlock) >= 1) {
            return (true, abi.encodePacked("Triggered at block ", currentBlock));
        }

        return (false, "");
    }
}
