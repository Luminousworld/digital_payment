import { assertEquals } from "vitest";

Clarinet.test({
  name: "Listing and purchasing sheet music",
  async fn(chain, accounts) {
    const deployer = accounts.get("deployer")!;
    const user = accounts.get("wallet_1")!;
    const admin = accounts.get("wallet_2")!;

    // Set marketplace admin
    let block = chain.mineBlock([
      Tx.contractCall("sheet-music-marketplace", "transfer-admin", [
        `'${admin.address}`
      ], deployer.address),
    ]);
    assertEquals(block.receipts[0].result, "(ok true)");

    // List new sheet music
    block = chain.mineBlock([
      Tx.contractCall("sheet-music-marketplace", "list-sheet-music", [
        "'Canon in D", "'Pachelbel", "'John Doe", "'Intermediate", "u100", "u10", "none"],
        admin.address
      ),
    ]);
    assertEquals(block.receipts[0].result, "(ok u1)");

    // Purchase sheet music
    block = chain.mineBlock([
      Tx.contractCall("sheet-music-marketplace", "purchase-sheet-music", ["u1", "'personal"], user.address),
    ]);
    assertEquals(block.receipts[0].result, "(ok true)");

    // Check ownership
    let ownerCheck = chain.callReadOnlyFn("sheet-music-marketplace", "check-ownership", [
      `'${user.address}`, "u1"],
      user.address
    );
    assertEquals(ownerCheck.result, "true");
  }
});
