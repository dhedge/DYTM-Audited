# DYTM Accounts

DYTM uses accounts instead of plain addresses to issue shares. There are two types of accounts; user accounts and isolated accounts. User accounts are derived from a user's address while the isolated accounts have no such derivation and are created on demand during [`supply`](../src/Office.sol) operation. Both type of accounts are represented by the [`AccountId`](../src/types/Types.sol) type, which has `uint256` as its underlying type. Only difference between the two is that user accounts can't be transferred to another address, while isolated accounts can be transferred.

## User Accounts

A user account is technically a `uint256` underlying type whose least significant 160 bits are the address of the user and the most significant 96 bits are zero. As you can understand, it is pretty easy to derive a user account from an address and the owner of a user account is the address itself. We don't store the owner of a user account in the `ownerOf` mapping.

A user account has the following properties:
- The least significant 160 bits are the address of the user.
- The most significant 96 bits are zero.
- The `ownerOf` function returns the address of the user.
- A user account can't be transferred to another address.

User accounts are mostly useful for people looking to only supply assets to a market although there are no restrictons when it comes to other market operations like borrowing or withdrawing. So a user account is akin to a soulbound token (SBT) in the sense that it is tied to a user and can't be transferred.

## Isolated Accounts

An isolated account is a `uint256` underlying type whose least significant 160 bits are null and the most significant 96 bits represent a monotonically increasing account count. The account id for an isolated account doesn't have any relation to the address of the owner of the account. The owner of an isolated account is stored in the `ownerOf` mapping and can be transferred to another address.

An isolated account has the following properties:
- The least significant 160 bits are null.
- The most significant 96 bits represent a monotonically increasing account count.
- The `ownerOf` function returns the address of the current owner of the isolated account.
- An isolated account can be transferred to another address.
- Is only created on demand during [`supply`](../src/Office.sol) operation.

## Rationale

The rationale behind using accounts instead of plain addresses is to provide a more flexible and extensible way to manage user interactions with the protocol. By using accounts and especially isolated accounts, we can provide features such as isolated debt positions, instant debt settlement via account trading, stop-loss and profit-take orders and much more. They are detailed as follows:

Some possible features are:
- **Isolated debt positions**: Isolated accounts can be used to create isolated debt positions, allowing users to create debt positions independent of their other debt positions in the same market. Imagine you want to borrow 'a' amount of WETH from a market by supplying 'z' amount of USDC. You also want to borrow 'b' amount of WBTC by supplying 'y' amount of USDC. You can create 2 accounts, one for each debt position, and supply USDC to both accounts. If WETH price tanks, only that account is affected.
- **Instant debt settlement via account trading**: Since you can trade accounts, it's akin to trading debt positions. Now imagine a network of keepers whose only purpose is to unwind accounts or debt positions. One can create markets to trade accounts and keepers can 'buy' accounts and provide value close to the account value. They can later on unwind the account and settle the debt position. This can be used to enable instant exit from a debt position without manually unwinding it.
- **Stop-loss and profit-take orders**: Operators who have been given permissions by a owner can execute actions on behalf of any account of the owner, this means they can close a debt position if the price of the asset goes below a certain threshold or take profit if the price goes above a certain threshold. This can be used to create stop-loss and profit-take orders.
