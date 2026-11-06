// ok: impure-function-js
function pure(a, b) {
	return a + b;
}

// ruleid: impure-function-js
function logsSomething(a) {
	console.log(a);
	return a;
}

// ruleid: impure-function-js
function mutatesThis(a) {
	this.total = a;
	return a;
}

// ruleid: impure-function-js
function mutatesThisArray(a) {
	this.items.push(a);
	return a;
}

// ruleid: impure-function-js
function fetchesData(url) {
	return fetch(url);
}

// ruleid: impure-function-js
function schedulesWork(cb) {
	setTimeout(cb, 100);
}

// ruleid: impure-function-js
function random() {
	return Math.random();
}

// ok: impure-function-js
const pureArrow = (a, b) => {
	const sum = a + b;
	return sum;
};

// ruleid: impure-function-js
const impureArrow = (a) => {
	console.log(a);
	return a;
};

// ok: impure-function-js
function buildsLocalArray(items) {
	const result = [];
	result.push(items[0]);
	return result;
}
