# BalanceSpikeTrap

## Objective
Build and deploy a fully functional Drosera trap that:
- Monitors ETH balance spikes of a specific wallet.
- Uses the standard collect() / shouldRespond() interface.
- Triggers a response when balance deviation exceeds 5%.
- Integrates with a separate response contract to handle alert logic.

## Problem
Ethereum wallets used by DAOs, DeFi protocols, or multisig treasuries are critical infrastructure.
Any unexpected ETH movement — whether loss or gain — might signal:

- Private key compromise,
- Automation bugs,
- Exploits or misconfigurations.

## Solution
The trap monitors ETH balance over consecutive blocks. If a change of 5% or more is detected (up or down), it triggers a custom alert handler to log the anomaly or initiate a reaction.

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
```

## Response Contract

**Contract: CustomAlertReceiver.sol**

```solidity
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
- Send ETH to or from address 0x52Aaa7E1332b0E9581dE47A8539Ced670458069d on Ethereum Hoodi testnet.
- Wait a few blocks.
- Monitor Drosera operator logs or dashboard.
- Look for:
  shouldRespond = true

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
