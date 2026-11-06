class Order {
	constructor(customer) {
		this.customer = customer;
	}

	placeFine(arg) {
		arg.validate();
		this.customer.notify();
		const wallet = new Wallet();
		wallet.charge();
		// ok: law-of-demeter-js
		return this.total();
	}

	placeBad(arg) {
		// ruleid: law-of-demeter-js
		return this.customer.getWallet().charge();
	}

	placeBadArg(arg) {
		// ruleid: law-of-demeter-js
		return arg.getWallet().charge();
	}

	placeBadNew() {
		// ruleid: law-of-demeter-js
		return new Wallet().open().charge();
	}
}

function storesThenCalls(a) {
	const b = a.getB();
	// ok: law-of-demeter-js
	return b.getC();
}
