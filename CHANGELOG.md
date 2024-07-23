# Changelog

## v0.4

```
Update currently ongoing.  This updated included a change to the Rust library,
and the new version has not yet been compiled for X11 and Windows.
I will remove this notice once the update is complete.
```

* Gas estimations have been added to the transaction sequence.

* Instead of the optional `gas_limit` parameter, transactions now have an optional `maximum_gas_fee`, which will cause a revert if the gas estimate is higher than the provided fee.

* Transactions can now be queued from any node using `Ethers.queue_transaction()`.  Queued transactions execute in sequence automatically.

* Nodes can now call `Ethers.register_transaction_log()` to receive new transaction objects and updates emitted during the transaction sequence.

* `Ethers.big_uint_math()` has been added for use on BigNumber Strings.  The available operations are ADD, SUBTRACT, MULTIPLY, DIVIDE, GREATER THAN, LESS THAN, GREATER THAN OR EQUAL, LESS THAN OR EQUAL, and EQUAL

* `Ethers.create_account()` now has an optional parameter for importing private keys as 64-character hex Strings.
