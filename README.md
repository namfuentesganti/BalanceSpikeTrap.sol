# BalanceSpikeTrap

## Objective
Deploy a Drosera-compatible trap that:
- Monitors ETH balance spikes of a specific wallet.
- Uses the standard collect() / shouldRespond() interface.
- Triggers if the balance increases or decreases by ≥5%.
- Passes the balance data to an external alert contract (e.g., CustomAlertReceiver).

## Problem
Wallets used by DAOs, DeFi protocols, or multisig treasuries often hold large amounts of ETH. Any unexpected movement of funds — either a spike or drop — may indicate:

- Private key compromise,
- Automation bugs,
- Exploits or misconfigurations.

## Solution
The trap monitors the ETH balance of a user-defined target address over time.
If the balance changes by 5% or more (up or down), it triggers a response contract which logs or reacts to the anomaly.

## Trap Logic

**Contract: BalanceSpikeTrap.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

contract BalanceSpikeTrap is ITrap {
    address public target;
    uint256 public constant spikePercent = 5;

    constructor(address _target) {
        target = _target;
    }

    function collect() external view override returns (bytes memory) {
        return abi.encode(target.balance);
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) return (false, abi.encode("Not enough data"));

        uint256 current = abi.decode(data[0], (uint256));
        uint256 previous = abi.decode(data[1], (uint256));

        if (previous == 0) return (false, abi.encode("No baseline"));

        uint256 change = current > previous ? current - previous : previous - current;
        uint256 percentChange = (change * 100) / previous;

        if (percentChange >= spikePercent) {
            return (true, abi.encode(current, previous));
        }

        return (false, "");
    }
}
```

## Response Contract

**Contract: CustomAlertReceiver.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CustomAlertReceiver {
    event SpikeDetected(address indexed triggeredBy, string message, uint256 currentBalance, uint256 previousBalance);

    function handleSpike(bytes calldata data) external {
        (uint256 current, uint256 previous) = abi.decode(data, (uint256, uint256));
        string memory message = "Balance spike detected!";
        emit SpikeDetected(msg.sender, message, current, previous);
    }
}
```


## Deployment & Setup

Deploy contracts with Foundry:

bash

```solidity
forge create src/CustomAlertReceiver.sol:CustomAlertReceiver \
  --rpc-url https://ethereum-hoodi-rpc.publicnode.com \
  --private-key 0xYOUR_PRIVATE_KEY
```

Update `drosera.toml`:

[traps.heartbeat]

path = "out/BalanceSpikeTrap.sol/BalanceSpikeTrap.json"

response_contract = "0x<YOUR_DEPLOYED_CustomAlertReceiver_ADDRESS>"

response_function = "handleSpike(bytes)"

Apply changes:

bash

```solidity
DROSERA_PRIVATE_KEY=0xYOUR_PRIVATE_KEY drosera apply
```

## Testing the Trap

Send ETH to/from the target address.

Wait a few blocks.

Check Drosera logs — look for shouldRespond = true.

Confirm SpikeDetected event was emitted

## Ideas for Extension
- Add a setter to change spikePercent dynamically.
- Support ERC-20 token balance tracking.
- Chain multiple traps and aggregate their output.

## Metadata
- Created: July 26, 2025
- Author: Namfuentesganti
- Telegram: @likisili
- Discord: namfuentesganti
- Email: bawanyloaqp6610@gmail.com
