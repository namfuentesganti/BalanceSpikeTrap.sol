// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

contract BalanceSpikeTrap is ITrap {
    address public constant target = 0x52Aaa7E1332b0E9581dE47A8539Ced670458069d;
    uint256 public constant spikePercent = 5;

    function collect() external view override returns (bytes memory) {
        return abi.encode(target.balance);
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) return (false, "Not enough data");

        uint256 current = abi.decode(data[0], (uint256));
        uint256 previous = abi.decode(data[1], (uint256));

        if (previous == 0) return (false, "No baseline");

        uint256 change = current > previous ? current - previous : previous - current;
        uint256 percentChange = (change * 100) / previous;

        if (percentChange >= spikePercent) {
            return (true, abi.encode(current, previous));
        }

        return (false, "");
    }
}
