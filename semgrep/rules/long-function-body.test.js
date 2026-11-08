// ruleid: long-function-body-js
function tooLong() {
	const a0 = 0;
	const a1 = 1;
	const a2 = 2;
	const a3 = 3;
	const a4 = 4;
	const a5 = 5;
	const a6 = 6;
	const a7 = 7;
	const a8 = 8;
	const a9 = 9;
	const a10 = 10;
	const a11 = 11;
	const a12 = 12;
	const a13 = 13;
	const a14 = 14;
	const a15 = 15;
	const a16 = 16;
	const a17 = 17;
	const a18 = 18;
	const a19 = 19;
	return a0;
}

// ok: long-function-body-js
function fine() {
	const b0 = 0;
	const b1 = 1;
	const b2 = 2;
	const b3 = 3;
	const b4 = 4;
	const b5 = 5;
	const b6 = 6;
	const b7 = 7;
	const b8 = 8;
	const b9 = 9;
	const b10 = 10;
	const b11 = 11;
	const b12 = 12;
	const b13 = 13;
	const b14 = 14;
	const b15 = 15;
	const b16 = 16;
	const b17 = 17;
	const b18 = 18;
	return b0;
}

// ruleid: long-function-body-js
const arrowTooLong = (x) => {
	const c0 = 0;
	const c1 = 1;
	const c2 = 2;
	const c3 = 3;
	const c4 = 4;
	const c5 = 5;
	const c6 = 6;
	const c7 = 7;
	const c8 = 8;
	const c9 = 9;
	const c10 = 10;
	const c11 = 11;
	const c12 = 12;
	const c13 = 13;
	const c14 = 14;
	const c15 = 15;
	const c16 = 16;
	const c17 = 17;
	const c18 = 18;
	const c19 = 19;
	return c0;
};

// ok: long-function-body-js
let arrowFine = (x) => {
	const d0 = 0;
	const d1 = 1;
	const d2 = 2;
	const d3 = 3;
	const d4 = 4;
	const d5 = 5;
	const d6 = 6;
	const d7 = 7;
	const d8 = 8;
	const d9 = 9;
	const d10 = 10;
	const d11 = 11;
	const d12 = 12;
	const d13 = 13;
	const d14 = 14;
	const d15 = 15;
	const d16 = 16;
	const d17 = 17;
	const d18 = 18;
	return d0;
};

// ok: long-function-body-js
function singleLongCall() {
	return scheduleZusPullJob(
		event,
		athenaId,
		timeZone,
		zusPullQueue,
		workerName,
		extra1,
		extra2,
		extra3,
		extra4,
		extra5,
		extra6,
		extra7,
		extra8,
		extra9,
		extra10,
		extra11,
		extra12,
		extra13,
		extra14,
		extra15,
		extra16,
		extra17,
		extra18,
		extra19,
		extra20,
	);
}

// ok: long-function-body-js
var shortExpr = (x) => x + 1;

