# ruleid: long-block-body-py
if too_long_cond:
    a0 = 0
    a1 = 1
    a2 = 2
    a3 = 3
    a4 = 4
    a5 = 5


# ok: long-block-body-py
if fine_cond:
    b0 = 0
    b1 = 1
    b2 = 2
    b3 = 3
    b4 = 4


# ruleid: long-block-body-py
while too_long_while:
    c0 = 0
    c1 = 1
    c2 = 2
    c3 = 3
    c4 = 4
    c5 = 5


# ok: long-block-body-py
while fine_while:
    d0 = 0
    d1 = 1
    d2 = 2
    d3 = 3
    d4 = 4


# ruleid: long-block-body-py
for item in items:
    e0 = 0
    e1 = 1
    e2 = 2
    e3 = 3
    e4 = 4
    e5 = 5


# ok: long-block-body-py
for item in items:
    f0 = 0
    f1 = 1
    f2 = 2
    f3 = 3
    f4 = 4


# ok: long-block-body-py
if single_long_call_cond:
    schedule_zus_pull_job(
        event,
        athena_id,
        time_zone,
        zus_pull_queue,
        worker_name,
    )


# ruleid: long-block-body-py
if outer_cond:
    g0 = 0
    g1 = 1
    g2 = 2
    g3 = 3
    g4 = 4
    if inner_cond:
        z = 1

