// ruleid: three-param-limit-js
function tooMany(a, b, c, d) {
	return a + b + c + d;
}

// ok: three-param-limit-js
function fine(a, b, c) {
	return a + b + c;
}

// ruleid: three-param-limit-js
const arrowTooMany = (a, b, c, d, e) => a + b + c + d + e;

// ok: three-param-limit-js
const arrowFine = (a, b) => a + b;

// ruleid: three-param-limit-js
function wayTooMany(a, b, c, d, e, f, g) {
	return a + b + c + d + e + f + g;
}

// ruleid: three-param-limit-js
const arrowWayTooMany = (a, b, c, d, e, f, g) => a + b + c + d + e + f + g;

// ruleid: three-param-limit-js
const nonReturnBlockTooMany = (a, b, c, d) => {
	console.log(a, b, c, d);
};

// ok: three-param-limit-js
const nonReturnBlockFine = (a, b, c) => {
	console.log(a, b, c);
};

// ruleid: three-param-limit-js
let letArrowTooMany = (a, b, c, d) => a + b;

// ruleid: three-param-limit-js
var varArrowTooMany = (a, b, c, d) => {
	return a;
};

// ruleid: three-param-limit-js
someArray.forEach((a, b, c, d) => {
	console.log(a, b, c, d);
});

// ok: three-param-limit-js
someArray.forEach((a, b, c) => {
	console.log(a, b, c);
});

// ruleid: three-param-limit-js
someArray.map((a, b, c, d) => a + b);
