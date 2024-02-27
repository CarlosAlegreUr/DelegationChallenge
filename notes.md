ERC-2535 -> DIAMOND PROXY

FIRST IDEA:

- Override ownerOf function and add exeption
return true if approved address. Forbid this on transfer.

Basically approved address can do anything but transfer it.

Why would you delegate an NFT?

- Delegate to a funds management actor.
- Delegate as a rent.

THE DELEGATEE CAN DO ANYTHING THAT DOES NOT INVOLVE ANY `transfer()` or `transferFrom()` operation

Problem, maybe a lot of apps will ask, are you ownerOf()?
ownerOf in ERC721 returns address of owner and not whether
is owner or not so...

Create another NFT that represents delegation of an NFT.
Then you are actually the owner.

And in tokenURI() or metadata function then it returns
the underlying NFT.

Override all funcs of this NFT to call the underlying NFT
data.

delNFT prooves delegation over any asset
delNFTId => address 
hash(delNFTId, address) => id
