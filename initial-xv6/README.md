# Testing system calls

## Running Tests for getreadcount

Running tests for this syscall is easy. Just do the following from
inside the `initial-xv6` directory:

```sh
prompt> ./test-getreadcounts.sh
```

If you implemented things correctly, you should get some notification
that the tests passed. If not ...

The tests assume that xv6 source code is found in the `src/` subdirectory.
If it's not there, the script will complain.

The test script does a one-time clean build of your xv6 source code
using a newly generated makefile called `Makefile.test`. You can use
this when debugging (assuming you ever make mistakes, that is), e.g.:

```sh
prompt> cd src/
prompt> make -f Makefile.test qemu-nox
```

You can suppress the repeated building of xv6 in the tests with the
`-s` flag. This should make repeated testing faster:

```sh
prompt> ./test-getreadcounts.sh -s
```

---

## Running Tests for sigalarm and sigreturn

**After implementing both sigalarm and sigreturn**, do the following:
- Make the entry for `alarmtest` in `src/Makefile` inside `UPROGS`
- Run the command inside xv6:
    ```sh
    prompt> alarmtest
    ```

---

## Getting runtimes and waittimes for your schedulers
- Run the following command in xv6:
    ```sh
    prompt> schedulertest
    ```  
---

## Running tests for entire xv6 OS
- Run the following command in xv6:
    ```sh
    prompt> usertests
    ```

---

## Implementation of FCFS
- we have to schedule the process that came first in this to achieve this, 
- Loop through the all the runnable processes same as a RR scheduler.
- The process that came first can be found out by using the ctime entry in struct proc.
- Schedule the process with the minium ctime first. 

---

# Implementation of MLFQ
- We define 3 new entries in the struct proc, they are : CurrentLevel, Waiticks, TicksElapsed.
- The update_time function is used to compute the Ticks the process has been waiting for and the Ticks has taken while running. 
- We use both of these to determine the priority of the process if a process exceeds the timeslice its been allocated then its pushed down.
- and if any process is starving(wait time exceeds starvation time) and if it is we boost it to its next higher level and the wait time is reset to zero. 
- At last all we iterate over all the processes to find the Process with the Highest Priority.
- This is done for every tick so when a higher priority process arrives then the iteratinig automatically gives the highest priority process as the new one. 
 
--- 

# Comparing the schedulers

```
Average rtime 10,  wtime 140  scheduler : RR	cpus = 1 the wtime is in the range of 130s to 160s at max
Average rtime 11,  wtime 122  scheduler : FCFS	cpus = 1 the wtime is in the range of 120s to 130s at max
Average rtime 10,  wtime 132  scheduler : MLFQ	cpus = 1 the wtime is in the range of 130s to 150s at max
```
---

