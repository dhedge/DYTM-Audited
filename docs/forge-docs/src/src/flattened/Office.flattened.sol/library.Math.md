# Math
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)

*Standard math utilities missing in the Solidity language.*


## Functions
### add512

*Return the 512-bit addition of two uint256.
The result is stored in two 256 variables such that sum = high * 2²⁵⁶ + low.*


```solidity
function add512(uint256 a, uint256 b) internal pure returns (uint256 high, uint256 low);
```

### mul512

*Return the 512-bit multiplication of two uint256.
The result is stored in two 256 variables such that product = high * 2²⁵⁶ + low.*


```solidity
function mul512(uint256 a, uint256 b) internal pure returns (uint256 high, uint256 low);
```

### tryAdd

*Returns the addition of two unsigned integers, with a success flag (no overflow).*


```solidity
function tryAdd(uint256 a, uint256 b) internal pure returns (bool success, uint256 result);
```

### trySub

*Returns the subtraction of two unsigned integers, with a success flag (no overflow).*


```solidity
function trySub(uint256 a, uint256 b) internal pure returns (bool success, uint256 result);
```

### tryMul

*Returns the multiplication of two unsigned integers, with a success flag (no overflow).*


```solidity
function tryMul(uint256 a, uint256 b) internal pure returns (bool success, uint256 result);
```

### tryDiv

*Returns the division of two unsigned integers, with a success flag (no division by zero).*


```solidity
function tryDiv(uint256 a, uint256 b) internal pure returns (bool success, uint256 result);
```

### tryMod

*Returns the remainder of dividing two unsigned integers, with a success flag (no division by zero).*


```solidity
function tryMod(uint256 a, uint256 b) internal pure returns (bool success, uint256 result);
```

### saturatingAdd

*Unsigned saturating addition, bounds to `2²⁵⁶ - 1` instead of overflowing.*


```solidity
function saturatingAdd(uint256 a, uint256 b) internal pure returns (uint256);
```

### saturatingSub

*Unsigned saturating subtraction, bounds to zero instead of overflowing.*


```solidity
function saturatingSub(uint256 a, uint256 b) internal pure returns (uint256);
```

### saturatingMul

*Unsigned saturating multiplication, bounds to `2²⁵⁶ - 1` instead of overflowing.*


```solidity
function saturatingMul(uint256 a, uint256 b) internal pure returns (uint256);
```

### ternary

*Branchless ternary evaluation for `a ? b : c`. Gas costs are constant.
IMPORTANT: This function may reduce bytecode size and consume less gas when used standalone.
However, the compiler may optimize Solidity ternary operations (i.e. `a ? b : c`) to only compute
one branch when needed, making this function more expensive.*


```solidity
function ternary(bool condition, uint256 a, uint256 b) internal pure returns (uint256);
```

### max

*Returns the largest of two numbers.*


```solidity
function max(uint256 a, uint256 b) internal pure returns (uint256);
```

### min

*Returns the smallest of two numbers.*


```solidity
function min(uint256 a, uint256 b) internal pure returns (uint256);
```

### average

*Returns the average of two numbers. The result is rounded towards
zero.*


```solidity
function average(uint256 a, uint256 b) internal pure returns (uint256);
```

### ceilDiv

*Returns the ceiling of the division of two numbers.
This differs from standard division with `/` in that it rounds towards infinity instead
of rounding towards zero.*


```solidity
function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256);
```

### mulDiv

*Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
denominator == 0.
Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
Uniswap Labs also under MIT license.*


```solidity
function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result);
```

### mulDiv

*Calculates x * y / denominator with full precision, following the selected rounding direction.*


```solidity
function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256);
```

### mulShr

*Calculates floor(x * y >> n) with full precision. Throws if result overflows a uint256.*


```solidity
function mulShr(uint256 x, uint256 y, uint8 n) internal pure returns (uint256 result);
```

### mulShr

*Calculates x * y >> n with full precision, following the selected rounding direction.*


```solidity
function mulShr(uint256 x, uint256 y, uint8 n, Rounding rounding) internal pure returns (uint256);
```

### invMod

*Calculate the modular multiplicative inverse of a number in Z/nZ.
If n is a prime, then Z/nZ is a field. In that case all elements are inversible, except 0.
If n is not a prime, then Z/nZ is not a field, and some elements might not be inversible.
If the input value is not inversible, 0 is returned.
NOTE: If you know for sure that n is (big) a prime, it may be cheaper to use Fermat's little theorem and get the
inverse using `Math.modExp(a, n - 2, n)`. See [invModPrime](/src/flattened/Office.flattened.sol/library.Math.md#invmodprime).*


```solidity
function invMod(uint256 a, uint256 n) internal pure returns (uint256);
```

### invModPrime

*Variant of [invMod](/src/flattened/Office.flattened.sol/library.Math.md#invmod). More efficient, but only works if `p` is known to be a prime greater than `2`.
From https://en.wikipedia.org/wiki/Fermat%27s_little_theorem[Fermat's little theorem], we know that if p is
prime, then `a**(p-1) ≡ 1 mod p`. As a consequence, we have `a * a**(p-2) ≡ 1 mod p`, which means that
`a**(p-2)` is the modular multiplicative inverse of a in Fp.
NOTE: this function does NOT check that `p` is a prime greater than `2`.*


```solidity
function invModPrime(uint256 a, uint256 p) internal view returns (uint256);
```

### modExp

*Returns the modular exponentiation of the specified base, exponent and modulus (b ** e % m)
Requirements:
- modulus can't be zero
- underlying staticcall to precompile must succeed
IMPORTANT: The result is only valid if the underlying call succeeds. When using this function, make
sure the chain you're using it on supports the precompiled contract for modular exponentiation
at address 0x05 as specified in https://eips.ethereum.org/EIPS/eip-198[EIP-198]. Otherwise,
the underlying function will succeed given the lack of a revert, but the result may be incorrectly
interpreted as 0.*


```solidity
function modExp(uint256 b, uint256 e, uint256 m) internal view returns (uint256);
```

### tryModExp

*Returns the modular exponentiation of the specified base, exponent and modulus (b ** e % m).
It includes a success flag indicating if the operation succeeded. Operation will be marked as failed if trying
to operate modulo 0 or if the underlying precompile reverted.
IMPORTANT: The result is only valid if the success flag is true. When using this function, make sure the chain
you're using it on supports the precompiled contract for modular exponentiation at address 0x05 as specified in
https://eips.ethereum.org/EIPS/eip-198[EIP-198]. Otherwise, the underlying function will succeed given the lack
of a revert, but the result may be incorrectly interpreted as 0.*


```solidity
function tryModExp(uint256 b, uint256 e, uint256 m) internal view returns (bool success, uint256 result);
```

### modExp

*Variant of [modExp](/src/flattened/Office.flattened.sol/library.Math.md#modexp) that supports inputs of arbitrary length.*


```solidity
function modExp(bytes memory b, bytes memory e, bytes memory m) internal view returns (bytes memory);
```

### tryModExp

*Variant of [tryModExp](/src/flattened/Office.flattened.sol/library.Math.md#trymodexp) that supports inputs of arbitrary length.*


```solidity
function tryModExp(
    bytes memory b,
    bytes memory e,
    bytes memory m
)
    internal
    view
    returns (bool success, bytes memory result);
```

### _zeroBytes

*Returns whether the provided byte array is zero.*


```solidity
function _zeroBytes(bytes memory byteArray) private pure returns (bool);
```

### sqrt

*Returns the square root of a number. If the number is not a perfect square, the value is rounded
towards zero.
This method is based on Newton's method for computing square roots; the algorithm is restricted to only
using integer operations.*


```solidity
function sqrt(uint256 a) internal pure returns (uint256);
```

### sqrt

*Calculates sqrt(a), following the selected rounding direction.*


```solidity
function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256);
```

### log2

*Return the log in base 2 of a positive value rounded towards zero.
Returns 0 if given 0.*


```solidity
function log2(uint256 x) internal pure returns (uint256 r);
```

### log2

*Return the log in base 2, following the selected rounding direction, of a positive value.
Returns 0 if given 0.*


```solidity
function log2(uint256 value, Rounding rounding) internal pure returns (uint256);
```

### log10

*Return the log in base 10 of a positive value rounded towards zero.
Returns 0 if given 0.*


```solidity
function log10(uint256 value) internal pure returns (uint256);
```

### log10

*Return the log in base 10, following the selected rounding direction, of a positive value.
Returns 0 if given 0.*


```solidity
function log10(uint256 value, Rounding rounding) internal pure returns (uint256);
```

### log256

*Return the log in base 256 of a positive value rounded towards zero.
Returns 0 if given 0.
Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.*


```solidity
function log256(uint256 x) internal pure returns (uint256 r);
```

### log256

*Return the log in base 256, following the selected rounding direction, of a positive value.
Returns 0 if given 0.*


```solidity
function log256(uint256 value, Rounding rounding) internal pure returns (uint256);
```

### unsignedRoundsUp

*Returns whether a provided rounding mode is considered rounding up for unsigned integers.*


```solidity
function unsignedRoundsUp(Rounding rounding) internal pure returns (bool);
```

## Enums
### Rounding

```solidity
enum Rounding {
    Floor,
    Ceil,
    Trunc,
    Expand
}
```

