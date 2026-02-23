# Test Trees

You might have noticed that each test file in the `test/` directory has a corresponding tree file. These tree files are used to describe the structure of the tests in a way that can be easily parsed and understood by tools and they adhere to the [Branching Tree Technique](https://x.com/PaulRBerg/status/1682346315806539776).

Before writing a test file or even a test function, you should first create a tree file. This tree file will serve as a blueprint for your tests, which can be used to generate test functions automatically. We use [Bulloak](https://github.com/alexfertel/bulloak?tab=readme-ov-file#rules) package scaffold the tests based on these tree files. It's important to understand the syntax and structure of these tree files, please refer to the Bulloak docs. 

>[!NOTE] 
However, some test trees may not be fully
compatible with Bulloak given the following [issue](https://github.com/alexfertel/bulloak/issues/78). It's recommended not to use `bulloak check` command to validate the tree files, as it may not work correctly with all test trees. The test trees are primarily there for readability purposes and to help you understand the structure of the tests.

To write the tree files, you can use the [Ascii Tree Generator](https://marketplace.visualstudio.com/items?itemName=aprilandjan.ascii-tree-generator) VSCode extension.