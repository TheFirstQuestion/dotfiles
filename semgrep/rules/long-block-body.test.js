// ruleid: long-block-body-js
if (tooLongCond) {
	const a0 = 0;
	const a1 = 1;
	const a2 = 2;
	const a3 = 3;
	const a4 = 4;
	const a5 = 5;
}

// ok: long-block-body-js
if (fineCond) {
	const b0 = 0;
	const b1 = 1;
	const b2 = 2;
	const b3 = 3;
	const b4 = 4;
}

// ruleid: long-block-body-js
while (tooLongWhile) {
	const c0 = 0;
	const c1 = 1;
	const c2 = 2;
	const c3 = 3;
	const c4 = 4;
	const c5 = 5;
}

// ok: long-block-body-js
while (fineWhile) {
	const d0 = 0;
	const d1 = 1;
	const d2 = 2;
	const d3 = 3;
	const d4 = 4;
}

// ruleid: long-block-body-js
for (let i = 0; i < 10; i++) {
	const e0 = 0;
	const e1 = 1;
	const e2 = 2;
	const e3 = 3;
	const e4 = 4;
	const e5 = 5;
}

// ok: long-block-body-js
for (let i = 0; i < 10; i++) {
	const f0 = 0;
	const f1 = 1;
	const f2 = 2;
	const f3 = 3;
	const f4 = 4;
}

// ruleid: long-block-body-js
for (const item of items) {
	const g0 = 0;
	const g1 = 1;
	const g2 = 2;
	const g3 = 3;
	const g4 = 4;
	const g5 = 5;
}

// ok: long-block-body-js
for (const item of items) {
	const h0 = 0;
	const h1 = 1;
	const h2 = 2;
	const h3 = 3;
	const h4 = 4;
}

// ruleid: long-block-body-js
for (const key in obj) {
	const k0 = 0;
	const k1 = 1;
	const k2 = 2;
	const k3 = 3;
	const k4 = 4;
	const k5 = 5;
}

// ok: long-block-body-js
for (const key in obj) {
	const m0 = 0;
	const m1 = 1;
	const m2 = 2;
	const m3 = 3;
	const m4 = 4;
}

// ok: long-block-body-js
if (singleLongCallCond) {
	scheduleZusPullJob(
		event,
		athenaId,
		timeZone,
		zusPullQueue,
		workerName,
	);
}

// ruleid: long-block-body-js
if (outerCond) {
	const n0 = 0;
	const n1 = 1;
	const n2 = 2;
	const n3 = 3;
	const n4 = 4;
	if (innerCond) {
		const z = 1;
	}
}

