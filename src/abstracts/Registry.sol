// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.29;

import {IERC165} from "@openzeppelin-contracts/interfaces/IERC165.sol";
import {IERC6909} from "@openzeppelin-contracts/interfaces/draft-IERC6909.sol";
import {EnumerableSet} from "@openzeppelin-contracts/utils/structs/EnumerableSet.sol";

import {ACCOUNT_ID_ZERO} from "../libraries/Constants.sol";
import {TokenHelpers, TokenType} from "../libraries/TokenHelpers.sol";
import {getRegistryStorageStruct} from "../libraries/StorageAccessors.sol";

import {Context} from "../abstracts/storages/Context.sol";

import {AccountId, MarketId} from "../types/Types.sol";
import {AccountIdLibrary} from "../types/AccountId.sol";

import {IRegistry} from "../interfaces/IRegistry.sol";

/// @title Registry
/// @notice Tokenization as inspired by OpenZeppelin's ERC6909 implementation.
/// @dev May not be fully compliant with the ERC6909 standard because of the following reasons:
///      - The `transferFrom` function does not allow transferring isolated account tokens by operators
///        unless the caller explicitly approved them.
///      - The operator scope is not just limited to transfers but also allows all market functions' access except
///        for transferring the account itself.
/// @author Chinmay <chinmay@dhedge.org>
abstract contract Registry is IRegistry, Context {
    using AccountIdLibrary for *;
    using TokenHelpers for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    /////////////////////////////////////////////
    //                 Structs                 //
    /////////////////////////////////////////////

    /// @param accountCount Counter for isolated accounts, incremented each time a new isolated account is created
    /// @param ownerOf Maps isolated accounts to their owner addresses
    /// @param totalSupplies Tracks the total supply of each token ID across all accounts
    /// @param ownerData Stores owner-specific data including operator approvals and allowances
    /// @param balances Tracks token balances for each account and token ID
    /// @param marketWiseData Stores market-specific data per account, including debt IDs and collateral token sets
    /// @custom:storage-location erc7201:DYTM.storage.Accounts
    struct RegistryStorageStruct {
        uint96 accountCount;
        mapping(AccountId account => address owner) ownerOf;
        mapping(uint256 tokenId => uint256 supply) totalSupplies;
        mapping(address owner => OwnerSpecificData data) ownerData;
        mapping(AccountId account => mapping(uint256 tokenId => uint256 amount)) balances;
        mapping(AccountId account => mapping(MarketId market => TokensData tokens)) marketWiseData;
    }

    /// @param operatorApprovals Owner specific mapping of operator approvals per account.
    /// @param allowances Owner specific mapping of allowances per account and tokenId.
    struct OwnerSpecificData {
        mapping(AccountId account => mapping(address operator => bool isApproved)) operatorApprovals;
        mapping(AccountId account => mapping(uint256 tokenId => mapping(AccountId spender => uint256 amount)))
            allowances;
    }

    //////////////////////////////////////////////
    //                 Modifiers                //
    //////////////////////////////////////////////

    modifier onlyAuthorizedCaller(AccountId account) {
        _verifyCallerAuthorization(account);
        _;
    }

    /////////////////////////////////////////////
    //              ERC6909 Functions          //
    /////////////////////////////////////////////

    /// @inheritdoc IRegistry
    function approve(address spender, uint256 tokenId, uint256 amount)
        external
        virtual
        override
        returns (bool success)
    {
        address caller = msg.sender;

        success = approve({
            account: caller.toUserAccount(), spender: spender.toUserAccount(), tokenId: tokenId, amount: amount
        });

        emit Approval({owner: caller, spender: spender, id: tokenId, amount: amount});
    }

    /// @inheritdoc IRegistry
    function transfer(address receiver, uint256 tokenId, uint256 amount) external virtual returns (bool success) {
        address caller = msg.sender;

        success = transferFrom({
            sender: caller.toUserAccount(), receiver: receiver.toUserAccount(), tokenId: tokenId, amount: amount
        });

        emit Transfer({caller: caller, sender: caller, receiver: receiver, id: tokenId, amount: amount});
    }

    /// @inheritdoc IRegistry
    function transferFrom(
        address sender,
        address receiver,
        uint256 tokenId,
        uint256 amount
    )
        external
        virtual
        returns (bool success)
    {
        success = transferFrom({
            sender: sender.toUserAccount(), receiver: receiver.toUserAccount(), tokenId: tokenId, amount: amount
        });

        emit Transfer({caller: msg.sender, sender: sender, receiver: receiver, id: tokenId, amount: amount});
    }

    /// @inheritdoc IRegistry
    function setOperator(address spender, bool approved) public virtual returns (bool success) {
        address caller = msg.sender;

        _setOperator({owner: caller, account: caller.toUserAccount(), operator: spender, approved: approved});

        success = true;

        emit OperatorSet({owner: caller, spender: spender, approved: approved});
    }

    /// @inheritdoc IRegistry
    function balanceOf(address owner, uint256 id) external view returns (uint256 balance) {
        return balanceOf({account: owner.toUserAccount(), tokenId: id});
    }

    /// @inheritdoc IRegistry
    function totalSupply(uint256 id) public view virtual returns (uint256 supply) {
        RegistryStorageStruct storage $ = getRegistryStorageStruct();

        supply = $.totalSupplies[id];
    }

    /// @inheritdoc IRegistry
    function allowance(address owner, address spender, uint256 id) external view returns (uint256 remaining) {
        AccountId account = owner.toUserAccount();
        address currentOwner = ownerOf(account);

        return allowance({owner: currentOwner, account: account, spender: spender.toUserAccount(), tokenId: id});
    }

    /// @inheritdoc IRegistry
    function isOperator(address owner, address spender) public view virtual returns (bool approved) {
        return isOperator(owner.toUserAccount(), spender);
    }

    /// @inheritdoc IRegistry
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool isSupported) {
        return interfaceId == type(IERC6909).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /////////////////////////////////////////////
    //            Account Functions            //
    /////////////////////////////////////////////

    /// @inheritdoc IRegistry
    function createIsolatedAccount(address newOwner) public returns (AccountId newAccount) {
        RegistryStorageStruct storage $ = getRegistryStorageStruct();

        require(newOwner != address(0), Registry__ZeroAddress());

        // Pre-increment the account count to ensure the first account is 1.
        uint96 accountCount = ++$.accountCount;
        newAccount = accountCount.toIsolatedAccount();
        $.ownerOf[newAccount] = newOwner;

        // It's assumed that an isolated account with the same `accountCount` does not exist
        // and hence we are skipping the `totalSupply` check.
        _mint({to: newOwner.toUserAccount(), tokenId: newAccount.toTokenId(), amount: 1});

        emit Registry__AccountCreated(newAccount, newOwner);
    }

    /// @inheritdoc IRegistry
    function approve(
        AccountId account,
        AccountId spender,
        uint256 tokenId,
        uint256 amount
    )
        public
        virtual
        returns (bool success)
    {
        require(spender.isUserAccount(), Registry__InvalidSpender(spender));

        _approve({owner: msg.sender, from: account, spender: spender, tokenId: tokenId, amount: amount});
        success = true;
    }

    /// @inheritdoc IRegistry
    /// @dev While we could reduce the number of local variable assignments, we keep them for better readability.
    function transferFrom(
        AccountId sender,
        AccountId receiver,
        uint256 tokenId,
        uint256 amount
    )
        public
        virtual
        returns (bool success)
    {
        address caller = msg.sender;
        address senderAccountOwner = ownerOf(sender);
        address receiverAccountOwner = ownerOf(receiver);
        bool callerIsSenderOperator = isOperator(sender, caller);
        TokenType tokenType = tokenId.getTokenType();

        bool isPrivileged = (caller == senderAccountOwner || callerIsSenderOperator); // Privileged caller of `sender` account

        // Check if the caller is the owner of the `receiver` account or is calling via a `delegationCall`
        // Note that in case of latter, the caller must be the `delegateeContext` as otherwise, any contract
        // during a delegation call could mess with all the accounts of the owner.
        bool callerIsOwnerOfReceiver =
            (caller == receiverAccountOwner
                || (callerContext == receiverAccountOwner && caller == address(delegateeContext)));
        bool isAllowanceRequired;

        // If a debt token is being transferred and if the receiver of the debt is not owned by the caller
        // then, we need to ensure that both `sender` and `receiver` accounts are owned by the same owner.
        // If they are we require allowance to be present between the `sender` account owner and the caller.
        // Note that self accounts transfer (i.e., when caller is the owner of both `sender` and `receiver` accounts)
        // doesn't require allowance.
        if (tokenType == TokenType.DEBT) {
            require(
                senderAccountOwner == receiverAccountOwner,
                Registry__DifferentOwnersWhenTransferringDebt({
                    from: sender,
                    to: receiver,
                    fromOwner: senderAccountOwner,
                    toOwner: receiverAccountOwner,
                    tokenId: tokenId
                })
            );

            isAllowanceRequired = !callerIsOwnerOfReceiver;
        } else if (!isPrivileged || (tokenType == TokenType.ISOLATED_ACCOUNT && callerIsSenderOperator)) {
            // If a debt token is not being transferred and:
            //  - the caller is not privileged,
            //  - or caller is operator of the `sender` account during an isolated account transfer,
            // then allowance is required.
            isAllowanceRequired = true;
        }

        if (isAllowanceRequired) {
            _spendAllowance({
                currentOwner: senderAccountOwner,
                from: sender,
                spender: caller.toUserAccount(),
                tokenId: tokenId,
                amount: amount
            });
        }

        _transfer({from: sender, to: receiver, tokenId: tokenId, amount: amount});
        success = true;
    }

    /// @inheritdoc IRegistry
    function setOperator(address operator, AccountId account, bool approved) public virtual returns (bool success) {
        _setOperator({owner: msg.sender, account: account, operator: operator, approved: approved});
        success = true;
    }

    /// @dev Creates `amount` of token `tokenId` and assigns them to `account`, by transferring it from ACCOUNT_ID_ZERO.
    /// Relies on the `_update` mechanism.
    ///
    /// Emits a {Transfer} event with `from` set to the zero AccountId.
    ///
    /// NOTE: This function is not virtual, {_update} should be overridden instead.
    function _mint(AccountId to, uint256 tokenId, uint256 amount) internal {
        require(to != ACCOUNT_ID_ZERO, Registry__ZeroAccount());

        _update({from: ACCOUNT_ID_ZERO, to: to, tokenId: tokenId, amount: amount});
    }

    /// @dev Moves `amount` of token `tokenId` from `from` to `to` without checking for approvals. This function
    /// verifies that neither the sender nor the receiver are ACCOUNT_ID_ZERO, which means it cannot mint or burn tokens.
    /// Relies on the `_update` mechanism.
    ///
    /// Emits a {Transfer} event.
    ///
    /// NOTE: This function is not virtual, {_update} should be overridden instead.
    function _transfer(AccountId from, AccountId to, uint256 tokenId, uint256 amount) internal {
        require(from != ACCOUNT_ID_ZERO && to != ACCOUNT_ID_ZERO, Registry__ZeroAccount());

        _update({from: from, to: to, tokenId: tokenId, amount: amount});
    }

    /// @dev Destroys a `amount` of token `tokenId` from `account`.
    /// Relies on the `_update` mechanism.
    ///
    /// Emits a {Transfer} event with `to` set to the zero AccountId.
    ///
    /// NOTE: This function is not virtual, {_update} should be overridden instead
    function _burn(AccountId from, uint256 tokenId, uint256 amount) internal {
        require(from != ACCOUNT_ID_ZERO, Registry__ZeroAccount());

        _update({from: from, to: ACCOUNT_ID_ZERO, tokenId: tokenId, amount: amount});
    }

    /// @dev Transfers `amount` of token `tokenId` from `from` to `to`, or alternatively mints (or burns) if `from`
    /// (or `to`) is the zero AccountId. All customizations to transfers, mints, and burns should be done by overriding
    /// this function.
    ///
    /// Emits a {Transfer} event.
    function _update(AccountId from, AccountId to, uint256 tokenId, uint256 amount) internal virtual {
        RegistryStorageStruct storage $ = getRegistryStorageStruct();
        address caller = msg.sender;
        TokenType tokenType = tokenId.getTokenType();
        bool isCollateral = tokenId.isCollateral();

        // Emitting transfer event early as zero amount transfers will return early.
        emit Registry__Transfer({caller: caller, from: from, to: to, tokenId: tokenId, amount: amount});

        // If the amount is zero, we do not need to do anything.
        // We don't explicitly revert as there could be cases where
        // token transfer computations can lead to 0 and if not taken special care,
        // it could lead to a reversion.
        if (amount == 0) {
            return;
        }

        if (from != ACCOUNT_ID_ZERO) {
            MarketId marketId = tokenId.getMarketId();
            uint256 fromBalance = $.balances[from][tokenId];

            require(fromBalance >= amount, Registry__InsufficientBalance(from, fromBalance, amount, tokenId));

            uint256 balanceDelta = fromBalance - amount;

            if (balanceDelta == 0) {
                if (isCollateral) {
                    // If tokens are NOT being minted i.e., `from` is not address(0) and
                    // if the `amount` is equal to the total balance of `from` then
                    // remove the tokenId from the `fromCollateralIds`.
                    EnumerableSet.UintSet storage fromCollateralIds = $.marketWiseData[from][marketId].collateralIds;

                    require(fromCollateralIds.remove(tokenId), Registry__TokenRemovalFromSetFailed(from, tokenId));
                } else if (tokenType == TokenType.DEBT) {
                    // If the balance of the `from` account is going to be zero after this transfer,
                    // we remove the debtId from the `from` account's market-wise data.
                    delete $.marketWiseData[from][marketId].debtId;
                }
            }

            unchecked {
                // Overflow not possible: amount <= fromBalance.
                $.balances[from][tokenId] = balanceDelta;
            }

            // Burn condition so update total supply.
            if (to == ACCOUNT_ID_ZERO) {
                unchecked {
                    // amount <= _balances[from][id] <= _totalSupplies[id]
                    $.totalSupplies[tokenId] -= amount;
                }
            }
        }

        if (to != ACCOUNT_ID_ZERO) {
            if (tokenType == TokenType.DEBT) {
                MarketId marketId = tokenId.getMarketId();
                uint256 toDebtId = $.marketWiseData[to][marketId].debtId;

                // If the `to` account doesn't have a debtId set, we set it to the `tokenId`.
                if (toDebtId == 0) {
                    $.marketWiseData[to][marketId].debtId = tokenId;
                } else if (toDebtId != tokenId) {
                    // If the `to` account already has a debtId set, it must match the `tokenId`.
                    // We don't allow minting multiple debt IDs per account per market.
                    revert Registry__DebtIdMismatch(to, tokenId, toDebtId);
                }
            } else if (isCollateral) {
                MarketId marketId = tokenId.getMarketId();

                // If tokens are not being burnt i.e., `to` is not address(0) and
                // if the tokenId doesn't exist in the `toCollateralIds` set then
                // add the tokenId regardless of `from` address.
                EnumerableSet.UintSet storage toCollateralIds = $.marketWiseData[to][marketId].collateralIds;

                toCollateralIds.add(tokenId);
            } else if (tokenType == TokenType.ISOLATED_ACCOUNT) {
                // If an isolated account is being transferred and `to` is a user account,
                // we need to update the `ownerOf` mapping.
                // Note: `toUserAddress` will revert in case `to` is not a user account.
                //       However, it won't revert if `to` is a null account (i.e., zero address).
                //       This is fine because we don't expect an account token (or an account) to be burned
                //       and transfers to the zero address are not allowed.
                $.ownerOf[AccountId.wrap(tokenId)] = to.toUserAddress();
            }

            $.balances[to][tokenId] += amount;

            // Mint condition so update total supply.
            if (from == ACCOUNT_ID_ZERO) {
                $.totalSupplies[tokenId] += amount;
            }
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the `from`'s `tokenId` tokens.
    ///
    /// This internal function is equivalent to `approve`, and can be used to e.g. set automatic allowances for certain
    /// subsystems, etc.
    ///
    /// Emits an {Approval} event.
    ///
    /// Requirements:
    /// - `from` cannot be the zero AccountId.
    /// - `spender` cannot be the zero AccountId.
    ///
    /// > [!WARNING]
    /// > - This function does not check if `from` is owned by `owner`.
    /// > - Doesn't revert if `owner` is not the current owner of `from`
    ///     AND `from` is a user account.
    /// > - This function does not check if `owner` is the zero address given that the only other place
    ///     it is used is in the `approve` function which already checks for it.
    /// > - This function does not check if the `tokenId` actually exists. As long as it's in the correct format
    ///     (i.e., is encoded as a valid token Id), it will be accepted.
    function _approve(
        address owner,
        AccountId from,
        AccountId spender,
        uint256 tokenId,
        uint256 amount
    )
        internal
        virtual
    {
        RegistryStorageStruct storage $ = getRegistryStorageStruct();

        require(from != ACCOUNT_ID_ZERO && spender != ACCOUNT_ID_ZERO, Registry__ZeroAccount());

        $.ownerData[owner].allowances[from][tokenId][spender] = amount;

        emit Registry__Approval({owner: owner, account: from, spender: spender, tokenId: tokenId, amount: amount});
    }

    /// @dev Approve `operator` to operate on all of `account`'s tokens.
    /// @dev This internal function is equivalent to `setOperator`, and can be used to e.g. set automatic allowances for
    ///      certain subsystems, etc.
    ///
    /// Emits an {OperatorSet} event.
    ///
    /// Requirements:
    /// - `owner` cannot be the zero address.
    /// - `operator` cannot be the zero address.
    function _setOperator(address owner, AccountId account, address operator, bool approved) internal virtual {
        RegistryStorageStruct storage $ = getRegistryStorageStruct();

        require(owner != address(0) && operator != address(0), Registry__ZeroAddress());

        $.ownerData[owner].operatorApprovals[account][operator] = approved;

        emit Registry__OperatorSet({owner: owner, account: account, operator: operator, approved: approved});
    }

    /// @dev Updates `from`'s allowance for `spender` based on spent `amount`.
    /// - Does not update the allowance value in case of infinite allowance.
    /// - Reverts if enough allowance is not available.
    /// - Does not emit an {Approval} event.
    function _spendAllowance(
        address currentOwner,
        AccountId from,
        AccountId spender,
        uint256 tokenId,
        uint256 amount
    )
        internal
        virtual
    {
        RegistryStorageStruct storage $ = getRegistryStorageStruct();
        uint256 currentAllowance = allowance(currentOwner, from, spender, tokenId);

        if (currentAllowance < type(uint256).max) {
            require(
                currentAllowance >= amount,
                Registry__InsufficientAllowance({
                    account: from, spender: spender, allowance: currentAllowance, needed: amount, tokenId: tokenId
                })
            );

            unchecked {
                $.ownerData[currentOwner].allowances[from][tokenId][spender] = currentAllowance - amount;
            }
        }
    }

    /////////////////////////////////////////////
    //             View Functions              //
    /////////////////////////////////////////////

    /// @inheritdoc IRegistry
    function isAuthorizedCaller(AccountId account, address caller) public view returns (bool isAuthorized) {
        return caller == ownerOf(account) || isOperator(account, caller);
    }

    /// @inheritdoc IRegistry
    function ownerOf(AccountId account) public view virtual returns (address owner) {
        RegistryStorageStruct storage $ = getRegistryStorageStruct();

        // If the account is a user account, the current owner is the user address.
        // Otherwise, it retrieves the owner from the storage.
        address currentOwner = (account.isUserAccount()) ? account.toUserAddress() : $.ownerOf[account];

        require(currentOwner != address(0), Registry__NoAccountOwner(account));

        owner = currentOwner;
    }

    /// @inheritdoc IRegistry
    function isOperator(AccountId account, address operator) public view virtual returns (bool approved) {
        return isOperator({owner: ownerOf(account), account: account, operator: operator});
    }

    /// @inheritdoc IRegistry
    function isOperator(address owner, AccountId account, address operator)
        public
        view
        virtual
        returns (bool approved)
    {
        RegistryStorageStruct storage $ = getRegistryStorageStruct();

        approved = $.ownerData[owner].operatorApprovals[account][operator]
            || (isOngoingDelegationCall()
                // - The `callerContext` is the owner of the `account` or an operator approved by the owner.
                // - AND the `operator` is the `delegateeContext`.
                && (callerContext == owner || $.ownerData[owner].operatorApprovals[account][callerContext])
                && operator == address(delegateeContext));
    }

    /// @inheritdoc IRegistry
    function balanceOf(AccountId account, uint256 tokenId) public view virtual returns (uint256 balance) {
        RegistryStorageStruct storage $ = getRegistryStorageStruct();

        balance = $.balances[account][tokenId];
    }

    /// @inheritdoc IRegistry
    function allowance(
        address owner,
        AccountId account,
        AccountId spender,
        uint256 tokenId
    )
        public
        view
        virtual
        returns (uint256 remaining)
    {
        RegistryStorageStruct storage $ = getRegistryStorageStruct();

        remaining = $.ownerData[owner].allowances[account][tokenId][spender];
    }

    /// @inheritdoc IRegistry
    function getDebtId(address owner, MarketId market) public view returns (uint256 debtId) {
        return getDebtId(owner.toUserAccount(), market);
    }

    /// @inheritdoc IRegistry
    function getDebtId(AccountId account, MarketId market) public view returns (uint256 debtId) {
        RegistryStorageStruct storage $ = getRegistryStorageStruct();

        return $.marketWiseData[account][market].debtId;
    }

    /// @inheritdoc IRegistry
    function getAllCollateralIds(address owner, MarketId market) public view returns (uint256[] memory collateralIds) {
        return getAllCollateralIds(owner.toUserAccount(), market);
    }

    /// @inheritdoc IRegistry
    function getAllCollateralIds(
        AccountId account,
        MarketId market
    )
        public
        view
        returns (uint256[] memory collateralIds)
    {
        RegistryStorageStruct storage $ = getRegistryStorageStruct();

        return $.marketWiseData[account][market].collateralIds.values();
    }

    /// @dev Reverts if the caller is not authorized as per `isAuthorizedCaller` function.
    function _verifyCallerAuthorization(AccountId account) internal view {
        require(isAuthorizedCaller(account, msg.sender), Registry__NotAuthorizedCaller(account, msg.sender));
    }
}
