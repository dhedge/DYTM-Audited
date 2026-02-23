# SlotDerivation
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)

*Library for computing storage (and transient storage) locations from namespaces and deriving slots
corresponding to standard patterns. The derivation method for array and mapping matches the storage layout used by
the solidity language / compiler.
See https://docs.soliditylang.org/en/v0.8.20/internals/layout_in_storage.html#mappings-and-dynamic-arrays[Solidity docs for mappings and dynamic arrays.].
Example usage:
```solidity
contract Example {
// Add the library methods
using StorageSlot for bytes32;
using SlotDerivation for bytes32;
// Declare a namespace
string private constant _NAMESPACE = "<namespace>"; // eg. OpenZeppelin.Slot
function setValueInNamespace(uint256 key, address newValue) internal {
_NAMESPACE.erc7201Slot().deriveMapping(key).getAddressSlot().value = newValue;
}
function getValueInNamespace(uint256 key) internal view returns (address) {
return _NAMESPACE.erc7201Slot().deriveMapping(key).getAddressSlot().value;
}
}
```
TIP: Consider using this library along with {StorageSlot}.
NOTE: This library provides a way to manipulate storage locations in a non-standard way. Tooling for checking
upgrade safety will ignore the slots accessed through this library.
_Available since v5.1._*


## Functions
### erc7201Slot

*Derive an ERC-7201 slot from a string (namespace).*


```solidity
function erc7201Slot(string memory namespace) internal pure returns (bytes32 slot);
```

### offset

*Add an offset to a slot to get the n-th element of a structure or an array.*


```solidity
function offset(bytes32 slot, uint256 pos) internal pure returns (bytes32 result);
```

### deriveArray

*Derive the location of the first element in an array from the slot where the length is stored.*


```solidity
function deriveArray(bytes32 slot) internal pure returns (bytes32 result);
```

### deriveMapping

*Derive the location of a mapping element from the key.*


```solidity
function deriveMapping(bytes32 slot, address key) internal pure returns (bytes32 result);
```

### deriveMapping

*Derive the location of a mapping element from the key.*


```solidity
function deriveMapping(bytes32 slot, bool key) internal pure returns (bytes32 result);
```

### deriveMapping

*Derive the location of a mapping element from the key.*


```solidity
function deriveMapping(bytes32 slot, bytes32 key) internal pure returns (bytes32 result);
```

### deriveMapping

*Derive the location of a mapping element from the key.*


```solidity
function deriveMapping(bytes32 slot, uint256 key) internal pure returns (bytes32 result);
```

### deriveMapping

*Derive the location of a mapping element from the key.*


```solidity
function deriveMapping(bytes32 slot, int256 key) internal pure returns (bytes32 result);
```

### deriveMapping

*Derive the location of a mapping element from the key.*


```solidity
function deriveMapping(bytes32 slot, string memory key) internal pure returns (bytes32 result);
```

### deriveMapping

*Derive the location of a mapping element from the key.*


```solidity
function deriveMapping(bytes32 slot, bytes memory key) internal pure returns (bytes32 result);
```

