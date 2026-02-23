// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC165} from "@openzeppelin-contracts/utils/introspection/IERC165.sol";
import {EnumerableSet} from "@openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import {IERC6909TokenSupply, IERC6909} from "@openzeppelin-contracts/interfaces/draft-IERC6909.sol";

import {AccountId, MarketId} from "../types/Types.sol";

/// @title IRegistry
/// @notice Interface for the Registry contract which manages tokenization for the DYTM protocol.
/// @author Chinmay <chinmay@dhedge.org>
interface IRegistry is IERC6909TokenSupply {
    /////////////////////////////////////////////
    //                 Events                 //
    /////////////////////////////////////////////

    event Registry__AccountCreated(AccountId indexed account, address indexed owner);
    event Registry__AccountTransfer(AccountId indexed account, address indexed oldOwner, address indexed newOwner);
    event Registry__OperatorSet(
        address indexed owner, AccountId indexed account, address indexed operator, bool approved
    );
    event Registry__Transfer(
        address indexed caller, AccountId indexed from, AccountId indexed to, uint256 tokenId, uint256 amount
    );
    event Registry__Approval(
        address owner, AccountId indexed account, AccountId indexed spender, uint256 indexed tokenId, uint256 amount
    );

    /////////////////////////////////////////////
    //                  Errors                 //
    /////////////////////////////////////////////

    error Registry__ZeroAddress();
    error Registry__ZeroAccount();
    error Registry__NoAccountOwner(AccountId account);
    error Registry__InvalidSpender(AccountId spender);
    error Registry__NotAuthorizedCaller(AccountId account, address caller);
    error Registry__TokenRemovalFromSetFailed(AccountId account, uint256 tokenId);
    error Registry__DebtIdMismatch(AccountId account, uint256 expectedDebtId, uint256 actualDebtId);
    error Registry__InsufficientBalance(AccountId account, uint256 balance, uint256 needed, uint256 tokenId);
    error Registry__DifferentOwnersWhenTransferringDebt(
        AccountId from, AccountId to, address fromOwner, address toOwner, uint256 tokenId
    );
    error Registry__InsufficientAllowance(
        AccountId account, AccountId spender, uint256 allowance, uint256 needed, uint256 tokenId
    );

    /////////////////////////////////////////////
    //                Structs                  //
    /////////////////////////////////////////////

    /**
     * @dev Struct which stores the collateral token IDs and debt token ID per account and market.
     */
    struct TokensData {
        uint256 debtId;
        EnumerableSet.UintSet collateralIds;
    }

    /////////////////////////////////////////////
    //              User Functions             //
    /////////////////////////////////////////////

    /**
     * @notice Creates a new isolated account with the given `newOwner`.
     * @param newOwner The address of the new owner of the account.
     * @return newAccount The newly created AccountId.
     */
    function createIsolatedAccount(address newOwner) external returns (AccountId newAccount);

    /**
     * @inheritdoc IERC6909
     * @dev Implicitly uses the owner's and spender's user account.
     * @dev Read more the behaviour of allowances in the natspec of `allowance` in
     *      the 'Account Functions' section of this interface.
     */
    function allowance(address owner, address spender, uint256 id) external view returns (uint256 remaining);

    /**
     * @inheritdoc IERC6909
     * @dev Implicitly uses the caller's and spender's user accounts.
     */
    function approve(address spender, uint256 tokenId, uint256 amount) external returns (bool success);

    /**
     * @inheritdoc IERC6909
     * @dev Implicitly uses the caller's user account.
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256 balance);

    /**
     * @notice Returns the collateral token IDs for a given market and owner.
     * @dev Implicitly converts `owner` address to user account.
     * @param owner The user address.
     * @param market The market ID of the market.
     * @return collateralIds Array of collateral token IDs.
     */
    function getAllCollateralIds(address owner, MarketId market) external view returns (uint256[] memory collateralIds);

    /**
     * @notice Returns the debt token ID for a given market and user.
     * @dev Implicitly converts `owner` address to user account.
     * @param owner The user address.
     * @param market The market ID of the market.
     * @return debtId The debt token ID for the account in the market.
     */
    function getDebtId(address owner, MarketId market) external view returns (uint256 debtId);

    /**
     * @inheritdoc IERC6909
     * @dev Provides temporary operator access to the delegatee in a delegation call context.
     */
    function isOperator(address owner, address spender) external view returns (bool approved);

    /**
     * @notice Provides authorization to invoke market functions on behalf of the `spender`.
     * @dev Implicitly uses the caller's user account.
     * @param spender The address of the spender to authorize.
     * @param approved Whether the operator is approved or not.
     * @return success Returns true if the operation was successful.
     */
    function setOperator(address spender, bool approved) external returns (bool success);

    /**
     * @inheritdoc IERC165
     * @dev Returns `true` if `interfaceId` is that of IERC6909 or IERC165.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool isSupported);

    /**
     * @inheritdoc IERC6909TokenSupply
     */
    function totalSupply(uint256 id) external view returns (uint256 supply);

    /**
     * @inheritdoc IERC6909
     * @notice For isolated account transfers, the `amount` must be 1.
     * @dev Implicitly uses the caller's and receiver's user accounts.
     */
    function transfer(address receiver, uint256 tokenId, uint256 amount) external returns (bool success);

    /**
     * @inheritdoc IERC6909
     * @dev Implicitly uses the caller's and receiver's user accounts.
     * @dev - If caller is not the current owner or the operator, the transfer happens
     *        using the allowance amount as configured by the current account owner.
     *      - If the caller is an operator and the tokenId represents an isolated account,
     *        the transfer will only take place if the operator is approved by the current account owner.
     *      - Allows transferring debt tokens between accounts owned by the same owner
     *        even if the caller is not the owner or an operator of either accounts
     *        as long as the caller has allowance from the owner for the debt token.
     */
    function transferFrom(
        address sender,
        address receiver,
        uint256 tokenId,
        uint256 amount
    )
        external
        returns (bool success);

    /////////////////////////////////////////////
    //            Account Functions            //
    /////////////////////////////////////////////

    /**
     * @notice Returns the allowance of `spender` for `tokenId` tokens of `account` as configured by
     *         a particular account owner.
     *
     * > [!NOTE]
     * > The allowances are tied to the owner of the account, not the account itself.
     * > If an account is transferred to a new owner and back to the previous owner, the allowances
     * > set by the original owner will remain.
     *
     * @dev This function does not include operator allowances.
     *      To check operator allowances, use `isOperator`.
     * @param owner The address of the owner of the account.
     * @param account The AccountId of the account.
     * @param spender The AccountId of the spender.
     * @param tokenId The ID of the token to check the allowance for.
     * @return remaining The allowance of the spender for the token of the account.
     */
    function allowance(
        address owner,
        AccountId account,
        AccountId spender,
        uint256 tokenId
    )
        external
        view
        returns (uint256 remaining);

    /**
     * @notice Approves a `spender` to operate on `tokenId` tokens of the `account`.
     *
     * - Can be called by anyone even if they never owned the account. The allowances will be active
     *   if/when they own the account.
     * - Can be called by an address which isn't the owner of `account` AND
     *   `account` is a user account. However, this is practically useless given
     *   user accounts can't be transferred.
     *
     * @param account The AccountId of the account.
     * @param spender The AccountId of the spender. MUST be a user account.
     * @param tokenId The ID of the token to approve.
     * @param amount The amount of tokens to approve.
     * @return success Returns true if the operation was successful.
     */
    function approve(
        AccountId account,
        AccountId spender,
        uint256 tokenId,
        uint256 amount
    )
        external
        returns (bool success);

    /**
     * @notice Returns the balance of `tokenId` tokens for the given `account`.
     * @param account The AccountId of the account.
     * @param tokenId The ID of the token to check the balance for.
     * @return balance The balance of the token for the account.
     */
    function balanceOf(AccountId account, uint256 tokenId) external view returns (uint256 balance);

    /**
     * @notice Returns the collateral token IDs for a given market and account.
     * @dev A collateral token ID is technically a token ID but with additional details like
     *      the token type (e.g. escrowed or lent).
     *
     * > [!Note]
     * > This function is gas-intensive and this limits the amount of collateral assets
     * > that can be allowed per market or per account.
     *
     * @param account The account ID.
     * @param market The market ID of the market.
     * @return collateralIds Array of collateral token IDs.
     */
    function getAllCollateralIds(
        AccountId account,
        MarketId market
    )
        external
        view
        returns (uint256[] memory collateralIds);

    /**
     * @notice Returns the debt token ID for a given market and account.
     * @param account The account ID.
     * @param market The market ID of the market.
     * @return debtId The debt token ID for the account in the market.
     */
    function getDebtId(AccountId account, MarketId market) external view returns (uint256 debtId);

    /**
     * @notice Checks if the `caller` is authorized to operate on the `account`.
     *
     * The caller is authorized if:
     *   - The caller is the owner of the account (includes user accounts).
     *   - The caller is an operator of the account.
     *   - The caller is the delegatee of the account for the duration of a delegation call.
     *
     * @param account The AccountId of the account to check authorization for.
     * @param caller The address of the caller.
     * @return isAuthorized Returns true if the caller is authorized to operate on the account.
     */
    function isAuthorizedCaller(AccountId account, address caller) external view returns (bool isAuthorized);

    /**
     * @notice Returns true if the `operator` is approved by the owner of the `account` to operate on behalf of the owner.
     * @dev Equivalent to `isOperator(ownerOf(account), account, operator)` so see the detailed behaviour there.
     * @param account The AccountId of the account.
     * @param operator The address of the operator to check.
     * @return approved True if the operator is authorized to operate on the account.
     */
    function isOperator(AccountId account, address operator) external view returns (bool approved);

    /**
     * @notice Returns true if:
     *           - The `operator` is approved by the owner of the `account` to operate on behalf of the owner.
     *           - If in a delegation call:
     *              - The `callerContext` is the owner of the `account` or an operator approved by the owner.
     *              - AND the `operator` is the `delegateeContext`.
     * @dev > [!WARNING] An operator is tied to the `owner` address provided here (i.e. the address that called
     *      > `setOperator`), not inherently to the current owner of the `account` or the account itself.
     *      > If an account is transferred to a new owner and back to the previous owner then
     *      > the operators set by the original `owner` address will remain unless manually reset using `setOperator`.
     *      > It's advised to use the `isOperator(account, operator)` function for integrations.
     * @dev MAY return `true` if the `account` is a user account and the `owner` has set the `operator` as an operator
     *      for the account even if the `owner` is not the current owner of the `account`.
     * @dev During a delegation call for `account`, if the `operator` is the same as the `delegateeContext`,
     *      it returns true.
     * @param owner The address of the owner to tie the operator to.
     * @param account The AccountId of the account.
     * @param operator The address of the operator to check.
     * @return approved True if the operator is authorized to operate on the account.
     */
    function isOperator(address owner, AccountId account, address operator) external view returns (bool approved);

    /**
     * @notice Returns the owner of the `account`.
     * @dev Reverts if the `account` is not created.
     * @dev In case the `account` is a user account, it returns the address of the user.
     * @param account The AccountId of the account.
     * @return owner The address of the owner of the account.
     */
    function ownerOf(AccountId account) external view returns (address owner);

    /**
     * @notice Sets an operator for the `account` that can perform actions on behalf of the owner of the `account`.
     *
     * - If the account is transferred to a new owner, the previously set operators won't have any permissions
     *   by default. However, if the same account is transferred back to the previous owner, the operators will
     *   regain their permissions. This behaviour is similar to how allowances work in this system.
     * - Operators can be set for user accounts even if the caller is not the owner of the user account.
     * - Implicitly ties the operator to the caller and account combo and not the account itself.
     *   The operator will be authorized when the caller becomes the owner of the account.
     *
     * > [!WARNING]
     * > If setting a contract as an operator, ensure that the contract has access controls to prevent unauthorized invocation of
     * > privileged functions. For example, contract `A` is set as an operator for account `X`. If `A` doesn't verify
     * > that the caller is authorized to perform actions on behalf of `X`, then anyone can call `A` to perform actions on behalf of `X`.
     *
     * @param operator The address of the operator.
     * @param account The AccountId of the account.
     * @param approved Whether the operator is approved or not.
     * @return success Returns true if the operation was successful.
     */
    function setOperator(address operator, AccountId account, bool approved) external returns (bool success);

    /**
     * @notice Transfers `amount` of token `tokenId` from the caller's account to `receiver`.
     *
     * > [!NOTE]
     * > This function could deviate from the ERC6909 standard given that an operator cannot transfer
     * > a specific type of token (isolated account token) unless approved by the current account owner.
     *
     * @param sender The AccountId of the sender.
     * @param receiver The AccountId of the receiver.
     * @param tokenId The ID of the token to transfer.
     * @param amount The amount of tokens to transfer.
     * @return success Returns true if the operation was successful.
     */
    function transferFrom(
        AccountId sender,
        AccountId receiver,
        uint256 tokenId,
        uint256 amount
    )
        external
        returns (bool success);
}
