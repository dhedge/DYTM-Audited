# Constants
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)

### BEFORE_SUPPLY_FLAG

```solidity
uint160 constant BEFORE_SUPPLY_FLAG = 1 << 0;
```

### AFTER_SUPPLY_FLAG

```solidity
uint160 constant AFTER_SUPPLY_FLAG = 1 << 1;
```

### BEFORE_SWITCH_COLLATERAL_FLAG

```solidity
uint160 constant BEFORE_SWITCH_COLLATERAL_FLAG = 1 << 2;
```

### AFTER_SWITCH_COLLATERAL_FLAG

```solidity
uint160 constant AFTER_SWITCH_COLLATERAL_FLAG = 1 << 3;
```

### BEFORE_BORROW_FLAG

```solidity
uint160 constant BEFORE_BORROW_FLAG = 1 << 4;
```

### AFTER_BORROW_FLAG

```solidity
uint160 constant AFTER_BORROW_FLAG = 1 << 5;
```

### BEFORE_WITHDRAW_FLAG

```solidity
uint160 constant BEFORE_WITHDRAW_FLAG = 1 << 6;
```

### AFTER_WITHDRAW_FLAG

```solidity
uint160 constant AFTER_WITHDRAW_FLAG = 1 << 7;
```

### BEFORE_REPAY_FLAG

```solidity
uint160 constant BEFORE_REPAY_FLAG = 1 << 8;
```

### AFTER_REPAY_FLAG

```solidity
uint160 constant AFTER_REPAY_FLAG = 1 << 9;
```

### BEFORE_LIQUIDATE_FLAG

```solidity
uint160 constant BEFORE_LIQUIDATE_FLAG = 1 << 10;
```

### AFTER_LIQUIDATE_FLAG

```solidity
uint160 constant AFTER_LIQUIDATE_FLAG = 1 << 11;
```

### BEFORE_MIGRATE_SUPPLY_FLAG

```solidity
uint160 constant BEFORE_MIGRATE_SUPPLY_FLAG = 1 << 12;
```

### AFTER_MIGRATE_SUPPLY_FLAG

```solidity
uint160 constant AFTER_MIGRATE_SUPPLY_FLAG = 1 << 13;
```

### ALL_HOOK_MASK

```solidity
uint160 constant ALL_HOOK_MASK = uint160((1 << 14) - 1);
```

### OFFICE_STORAGE_LOCATION

```solidity
bytes32 constant OFFICE_STORAGE_LOCATION = 0x71d51ffbf9e21449409619cca98ecabe4a4a4497c444c0c069176d2b254ae700;
```

### ACCOUNTS_STORAGE_LOCATION

```solidity
bytes32 constant ACCOUNTS_STORAGE_LOCATION = 0x5e1358d18e2f22d9f7b5b2ce571845b90812696899eaa9f0525b422dc97c1400;
```

### MAX_TRANSIENT_QUEUE_LENGTH

```solidity
uint8 constant MAX_TRANSIENT_QUEUE_LENGTH = 10;
```

### TRANSIENT_QUEUE_STORAGE_BASE_SLOT

```solidity
uint256 constant TRANSIENT_QUEUE_STORAGE_BASE_SLOT = 100;
```

### RESERVE_KEY_ZERO

```solidity
ReserveKey constant RESERVE_KEY_ZERO = ReserveKey.wrap(0);
```

### ACCOUNT_ID_ZERO

```solidity
AccountId constant ACCOUNT_ID_ZERO = AccountId.wrap(0);
```

### MARKET_ID_ZERO

```solidity
MarketId constant MARKET_ID_ZERO = MarketId.wrap(0);
```

### USD_ISO_ADDRESS

```solidity
address constant USD_ISO_ADDRESS = address(840);
```

### WAD

```solidity
uint256 constant WAD = 1e18;
```

