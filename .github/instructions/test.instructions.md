---
applyTo: 'test/**/*.t.sol'
---
# Test Instructions

## Purpose

This file contains instructions for writing tests using the Foundry testing framework for DYTM smart contract functions.

## Instructions

- DO NOT MODIFY ANY CORE CONTRACTS IN #src DIRECTORY.

- Each test file to be generated should be generated using the name of the corresponding `.tree` file. For example, if there is a tree file named `Office_liquidate.tree`, the test file should be named `Office_liquidate.t.sol`.

- The test file should be in the same directory or subdirectory as the `.tree` file it corresponds to.

- The new test file should always include the following import (modify according to relative path):

```solidity
import "../../shared/CommonScenarios.sol";
```

- Never use named imports and always use global imports in test files.

- Tests in the new test file should start with the `test_` prefix followed by the specific conditions being tested for. For example if you have the following test condition:

```
└── When reserve exists
    ├── When reserve is not borrowable
    │   └── It should return 0.
    │       └── Because the asset is not borrowable.
```

The test function should be named as follows:

```solidity
function test_WhenReserveExists_WhenReserveIsNotBorrowable_ItShouldReturn0() public {
    // Test logic here
}
```

- If a few conditions are common across multiple tests for example `WhenReserveExists`, avoid including it in the test function name as long as the test name remains unique.

- The `It` condition statements are supposed to be test assertions and hence, there should be a comment over each assertion inside the test function.

- Revert tests should start with `test_Revert` followed by the conditions being tested.

- Do not include `vm.stopPrank` in the test functions, as it is not required. The prank will automatically stop at the end of the test function. In case any test requires changing pranked addresses, use `vm.startPrank`.

- Each test should re-use modifiers in the #CommonScenarios.sol file where applicable to ensure consistency and reduce code duplication.

- If new modifiers are needed to reduce code duplication, they should be only added in the current test file and not in the #CommonScenarios.sol file.

- Variables common to some or all tests should be `internal` and start with an underscore.

- Refer the contract whose name appears as the first word (before the underscore) of the tree file. For example, if the tree file is `Office_liquidate.tree`, refer to the `Office` contract in your tests.

- If for some test condition the caller's account type is not mentioned, use isolated accounts i.e, `givenAccountIsIsolated` modifier from the #CommonScenarios.sol file.

- Each new test function should have a comment at the top indicating the test case number (sequential natural numbers) according to the order of the test cases in the tree file.

- If tests repeatedly fail executing, this could mean the contract or function you are testing has a bug. In such cases, you should not modify the test file to make it pass. Instead, you should create the test and mark it as failing by adding the `// Failing` comment at the top of the test function.

- All test files should end with a comment ` // Generated using co-pilot: <MODEL_NAME>` to indicate that the file was generated using the copilot tool.

- After creating the file and finishing the prompt, don't summarize the changes made.