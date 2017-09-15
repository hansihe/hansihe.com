---
layout: post
title:  "Preemptive scheduling of Erlang NIFs"
date:   2016-07-26 13:42:38 +0200
categories: erlang elixir c
---

* TOC
{:toc}

In this article we look at a completely reckless and unsafe (but fun) way to work around some of the issues with running native code from Erlang. This involves allocating a new C stack and switching to it, then interrupting execution when a certain amount of time has passed and switching back to the original thread, for then to resume execution where we left off later at a later point in time.

Note that is is purely done for fun, is completely nonportable, and does quite a few things that could crash or deadlock the Erlang VM if you so much as look at it the wrong way. What's not to love :)

{% include image.html name="segfault.png" %}

If you are already familiar with how Erlang processes and scheduling works, you can safely skip the following section.

## Background
One of the most attractive features of the Erlang VM (BEAM) is the way it executes code. All work in Erlang is done within an [Erlang process](http://erlang.org/doc/getting_started/conc_prog.html) (not to be confused with OS processes). They are designed to be extremely lightweight, meaning you can run millions of them at the same time. If you were to write a web application in Erlang, you would start a new process for every incoming request.

The reason this works as well as it does, is because of the way the BEAM schedules execution of different processes. The BEAM makes sure a single process doesn't run for more then a designated amount of time before it is bumped to the back of the run-queue, and other processes are allowed to run. For your web application this means that one (or a hundred) misbehaving requests doesn't ruin the latency and experience for your other requests.

If this sounds interesting to you, [this](https://hamidreza-s.github.io/erlang/scheduling/real-time/preemptive/migration/2016/02/09/erlang-scheduler-details.html) is a good article with further details.

### Native code
NIF stands for Native Implemented Function, and is one of the mechanisms provided by the BEAM for running native code as part of your Erlang application. The NIF method involves writing a shared library in C (or [Rust](https://github.com/hansihe/Rustler), but that's a whole other blog post) that exports functions that can be loaded into the BEAM and called.

NIFs are commonly used both for speeding up computations by dropping down to native code, and for exposing useful functionality in low-level libraries to Erlang.

A big caveat of NIFs is that they run in the same thread as the Erlang scheduler. Because the Erlang schedulers are very finely tuned, they are not designed to get blocked for long amounts of time. This means that a NIF that blocks for more than around a millisecond will start negatively affecting performance, stability and latency of the whole VM.

{% include image.html name="long-running-nif.gif" %}

## The horrible idea
If we want to make execution of native code transparently interruptable while still running on the same thread, what can we do? Well, we need two things:

1. A way to jump out of an arbitrary point in the call stack, do something else, then jump back in and continue working
2. A way for another thread to interrupt an ongoing computation without cooperation

The solutions I came up with for these problems are:

1. We would effectively need the ability to jump up to a function earlier on the call chain, do some other work, then at a later time resume computation were we left off. If we were to just naively jump down the stack, subsequent calls would overwrite the data on the stack we would need to resume the paused computation. We therefore need a separate stack to do our interruptible work on.
2. In the posix implementation of linux, the only way I could find for a thread to interrupt execution of another thread was signals. We register a signal handler for a user signal that will jump back to our main stack when executed.

### Switching stacks
*Surprisingly* the functionality for switching stacks is largely neglected in the C language, so we have to do the heavy lifting ourselves. For this we use a big chunk of inline assembly where we save the current state of the processor, restore the state of the other stack, then jump to where we want to continue execution.

```c
// We store our registers in this type when switching ctx.
typedef void *exec_ctx[8];

// This will switch from one stack to another, passing message over to the 
// other world.
// Inspired by the context switch code of luajit's Coco.
static inline void *ctx_switch(exec_ctx from, exec_ctx to, void *message) {
    __asm__ __volatile__ (
            // The following instructions first moves all process registers we
            // need to preserve into the `from` exec_ctx. We then restore the
            // processor state of the `to` exec_ctx.
            "leaq 1f(%%rip), %%rax\n" // ip + (distance to label 1 forwards)
            "movq %%rax, (%0)\n"      // Move rip to from[0]
            "movq %%rsp, 8(%0)\n"     // Move rsp to from[1]
            "movq %%rbp, 16(%0)\n"    // from[2]
            "movq %%rbx, 24(%0)\n"    // from[3]
            "movq %%r12, 32(%0)\n"    // from[4]
            "movq %%r13, 40(%0)\n"    // from[5]
            "movq %%r14, 48(%0)\n"    // from[6]
            "movq %%r15, 56(%0)\n"    // from[7]
            "movq 56(%1), %%r15\n"    // Restore backwards
            "movq 48(%1), %%r14\n" 
            "movq 40(%1), %%r13\n"
            "movq 32(%1), %%r12\n" 
            "movq 24(%1), %%rbx\n" 
            "movq 16(%1), %%rbp\n"
            "movq 8(%1), %%rsp\n" 
            // The jmpq instruction will jump to the exact location where we
            // left off in the other exec_ctx.
            "jmpq *(%1)\n"
            // This is the label the leaq instruction further up gets its
            // offset to. This is effectively what we store in the `exec_ctx`
            // as the program counter, and this is where we return when
            // switching back to this context.
            "1:\n"
            : "+S" (from), "+D" (to), 
            // We force `message` into the c register, this will be read by the 
            // receiver in the other execution context.
            "+c" (message) 
            :
            // Clobber registers. This prevents the compiler from using these.
            : "rax", "rcx", "rdx", "r8", "r9", "r10", "r11", "memory", "cc"
            );
    return message;
}
```

We now have a way to jump into a stack we have already established, but how do we create a new one? We need to fabricate a new `exec_ctx` that jumps into a piece of code which prepares the new stack for use, optionally receives the `message`, and then calls the function containing the actual computation function.

```c
// We store the data we need in order to get back into our original
// stack in a thread local.
_Thread_local Exec_state *exec_state = 0;

typedef struct {
    // Pointer to our pocket universe
    void *alloc_stack_ptr;
    int alloc_stack_size;
    // This always stores data related to the exec stack.
    exec_ctx ctx;
    // This always stores data related to the scheduler stack.
    exec_ctx return_ctx;
    // Debug counter that stores the amount of reschedules we have experienced.
    int reschedules;
} Exec_state;

// Used to call a function on a new stack
static inline void exec_stack_launchpad(void) {
    void *func;
    NifArgs *message;
    // When we jump to the launchpad, this assembly runs directly
    // after ctx_switch executes the jmpq instruction.
    // It can read relevant data from the registers `ctx_switch` last
    // put them.
    __asm__ __volatile__ (
            "movq %%r12, %0\n"
            "movq %%rcx, %1\n"
            //"jmpq *%%r12\n"
            : "=m" (func), "=m" (message)
            );
    ReturnStruct ret;
    ret.type = RETURN;
    
    pthread_t thread = pthread_self();
    add_nif_timer(thread);
    ret.return_term = ((ERL_NIF_TERM (*)(ErlNifEnv*, int, const ERL_NIF_TERM[]))func)
        (message->env, message->argc, message->argv);
    rem_nif_timer(thread);

    free(message);
    ctx_switch(exec_state->ctx, exec_state->return_ctx, &ret);
}

void nif_function() {
    exec_state = enif_alloc_resource(INCOMPLETE_EXEC_ENV, sizeof(Exec_state));
    exec_state->alloc_stack_ptr = malloc(STACK_SIZE);
    exec_state->alloc_stack_size = STACK_SIZE;

    // Find the start of our stack, the uppermost address
    size_t *stack_start = (size_t *)(exec_state->alloc_stack_ptr + STACK_SIZE);
    // Set the bottom of the stack to a value easy to spot in a debugger
    stack_start[-1] = 0xdeaddeaddeaddead;

    // Initialize the context we are going to jump to in a second
    exec_state->ctx[0] = (void *)(exec_stack_launchpad); // PC address
    exec_state->ctx[1] = (void *)(&stack_start[-1]);     // SP address
    exec_state->ctx[2] = (void *)0;
    exec_state->ctx[3] = (void *)0;
    // Argument for the launchpad, this is the actual function that will be called
    // on the other stack.
    exec_state->ctx[4] = (void *)(inner_test);
    exec_state->ctx[5] = (void *)0;
    exec_state->ctx[6] = (void *)0;
    exec_state->ctx[7] = (void *)0;

    [...]

    // Go!
    // This is where we jump to the launchpad in the other stack.
    ReturnStruct *ret = (ReturnStruct *)ctx_switch(exec_state->return_ctx, exec_state->ctx, args);

    [...]
}
```

### Interrupting execution
For interrupting execution, we use posix signals. We register a signal handler for our chosen signal number when we first load our library. The signal handler then uses our stack switching function `ctx_switch` for going back to our primary stack.

We then have a separate thread that sends the signal to NIFs which run for too long.

```c
void on_nif_load() {
    // Register interrupt signal handler
    signal(INT_SIGNAL, handle_thread_int);
}

void handle_thread_int(int signum) {
    // We use ret to inform the receiving code of the state of the execution.
    // This means either that it execution needs to be continued at a later time,
    // or that the execution has finished, and we have a result.
    ctx_switch(exec_state->ctx, exec_state->return_ctx, &ret);
}
```

## Testing it
When the jigsaw puzzle is assembled, it does actually work. Given a proper smart timing algorithm, I would think it could be made relatively efficient.

The complete code is located [here](https://gist.github.com/hansihe/7e553c08b3a25e39e402975b9d4ee05e).

## Caveats
While it does work, there is no way it should be used anywhere outside of testing.

* If a reschedule happens while we are in a call into the Erlang VM, seriously bad things could happen. (lockups, crashes) This is avoidable by disabling rescheduling while doing VM calls.
* You can't create new terms and later enable rescheduling. When you want to create new Erlang terms for return, you need to disable rescheduling for the rest of the computation. Re-enabling rescheduling could cause the terms you are working with to be garbage collected in a schedule.
* When a computation is started, it is passed a Nif Environment. This is not supposed to outlive the duration of the NIF call, as you get a new one for each call. In our case we have little choice but to use the same Nif Environment across several schedules. This is very dangerous, as we have no idea if any of the pointers in there are even valid.

## Better solutions
This technique may work if the erlang VM itself supports it, but as is, it is unusable. Fortunately there are other alternatives already available:

* Split your computation into chunks manually. This is more work, and does not work when calling into other libraries.
* Dirty NIFs. You can manually mark your NIF as dirty, which will make it run on a "Dirty Scheduler". This solves some problems like VM stability, but performance is worse, and latency is still a concern. At the moment this is experimental, and requires a special build of the BEAM.
* Threaded NIFs. You can manually move your computation into your own thread. This could solve both the stability, performance and latency problems, but introduces more code complexity for the user.
* Ports. With ports you can communicate with an external program through stdin and stdout.

## Sources
* [LuaJit CoCo](http://coco.luajit.org/) - I used this as a reference for implementing the context switching code.
