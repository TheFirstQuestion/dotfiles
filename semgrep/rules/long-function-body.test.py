# ruleid: long-function-body-py
def too_long():
    a0 = 0
    a1 = 1
    a2 = 2
    a3 = 3
    a4 = 4
    a5 = 5
    a6 = 6
    a7 = 7
    a8 = 8
    a9 = 9
    a10 = 10
    a11 = 11
    a12 = 12
    a13 = 13
    a14 = 14
    a15 = 15
    a16 = 16
    a17 = 17
    a18 = 18
    a19 = 19
    return a0


# ok: long-function-body-py
def fine():
    b0 = 0
    b1 = 1
    b2 = 2
    b3 = 3
    b4 = 4
    b5 = 5
    b6 = 6
    b7 = 7
    b8 = 8
    b9 = 9
    b10 = 10
    b11 = 11
    b12 = 12
    b13 = 13
    b14 = 14
    b15 = 15
    b16 = 16
    b17 = 17
    b18 = 18
    return b0


# ok: long-function-body-py
def single_long_call():
    return schedule_zus_pull_job(
        event,
        athena_id,
        time_zone,
        zus_pull_queue,
        worker_name,
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
    )


# ok: long-function-body-py
def short():
    return 1

