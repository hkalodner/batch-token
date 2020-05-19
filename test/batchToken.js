const BatchToken = artifacts.require("./BatchToken.sol");

function setupCall(sender, dest, nonce, amount) {
	let data = web3.utils.toBN(0)
		.add(web3.utils.toBN(amount))
		.shln(32)
		.add(web3.utils.toBN(nonce))
		.shln(32)
		.add(web3.utils.toBN(dest))
		.shln(32)
		.add(web3.utils.toBN(sender));

	let messageHash = web3.utils.soliditySha3(
		{t: "uint256", v: data}
	);
	return [data, "0x" + data.toString(16, 64)];
}

contract("BatchToken", accounts => {
	it("it should be cheap", async () => {
		let instance = await BatchToken.new({value: web3.utils.toWei("1")});
		await instance.registerAccount.sendTransaction({from: accounts[1]});
		let [data, messageHash] = setupCall(0, 1, 0, 1);
		let sig = await web3.eth.sign(messageHash, accounts[0]);
		await instance.sequencerBatchTransfer(
			sig,
			[data],
		);
		
		let datas = [];
		let sigs = [];
		for (let i = 1; i < 101; i++) {
			let [data, messageHash] = setupCall(0, 1, i, 1);
			let sig = await web3.eth.sign(messageHash, accounts[0]);
			datas.push(data);
			sigs.push(sig)
		}

		let fullSig = "0x";
		for (let i = 0; i < sigs.length; i++) {
			fullSig += sigs[i].substring(2);
		}
		let tx = await instance.sequencerBatchTransfer(
			fullSig,
			datas
		);
		let newBalance = await instance.accounts(1);
		assert.equal(newBalance.balance.toNumber(), 101, "Ended up with incorrect balance");
		console.log("Batch transfer of 100 used", tx.receipt.cumulativeGasUsed, "gas");
		console.log("Used", (tx.receipt.cumulativeGasUsed - 21000)/100, "gas per transfer");
	});
});