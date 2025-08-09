// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

contract BalanceSpikeTrap is ITrap {
    address public target;

    constructor() {
        target = 0x52Aaa7E1332b0E9581dE47A8539Ced670458069d;
    }

    function collect() external view override returns (bytes memory) {
        return abi.encode(block.number);
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) return (false, abi.encode("Not enough data"));

        uint256 currentBlock = abi.decode(data[0], (uint256));
        uint256 previousBlock = abi.decode(data[1], (uint256));

        if (previousBlock == 0) return (false, abi.encode("No baseline"));

        if ((currentBlock - previousBlock) >= 1) {
            return (true, abi.encodePacked("Triggered at block ", currentBlock));
        }

        return (false, "");
    }
}
