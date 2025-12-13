from fastapi import APIRouter
from pydantic import BaseModel, conlist
from typing import Optional, List


router= APIRouter(
    prefix= "/schedule"
)




'''
Request Format:
process(pid,arrival, burst)
quantum for RR

'''     


class Input(BaseModel):
    processes: List[List[int]]
    quantum: Optional[int] = None





@router.post("/fcfs")
def fcfs(schedule: Input):
    processes = schedule.processes

    processes.sort(key=lambda x: x[1])  # sort by arrival time
    start, finish, order = [], [], []
    time = 0
    for process in processes:
        pid, at, bt, pri = process  # Unpack all 4 values
        if time < at:
            time = at
        start.append(time)
        time += bt
        finish.append(time)
        order.append(pid)

    return {
        'finish': finish,
        'order': order
    }
    


@router.post("/sjf")
def sjf(schedule: Input):
    processes = schedule.processes

    processes.sort(key=lambda x: x[1])  # Sort by arrival time
    n = len(processes)
    time, completed, order, finish = 0, [], [], []

    while len(completed) < n:
        available = [p for p in processes if p[1] <= time and p not in completed]
        if not available:
            time += 1
            continue
        # Choose process with shortest burst time
        p = min(available, key=lambda x: x[2])
        time += p[2]
        completed.append(p)
        order.append(p[0])
        finish.append(time)

    return {
        'finish': finish,
        'order': order
    }

@router.post("/pri")
def priority_scheduling(schedule:Input):

    processes= schedule.processes

    processes.sort(key=lambda x: x[1])
    n = len(processes)
    time, completed, order, finish = 0, [], [], []

    while len(completed) < n:
        available = [p for p in processes if p[1] <= time and p not in completed]
        if not available:
            time += 1
            continue
        p = min(available, key=lambda x: x[3])  # smallest priority
        time += p[2]
        completed.append(p)
        order.append(p[0])
        finish.append(time)

    return {
        'finish':finish,
        'order': order
    }

@router.post("/rr")
def round_robin(schedule: Input):
    processes = schedule.processes
    quantum = schedule.quantum

    if quantum is None:
        return {"error": "Quantum must be provided for Round Robin scheduling"}

    # Create process dictionary for easier access
    process_dict = {p[0]: {"arrival": p[1], "burst": p[2], "priority": p[3], "remaining": p[2]} for p in processes}
    
    # Sort by arrival time
    sorted_processes = sorted(processes, key=lambda x: x[1])
    time = 0
    queue = []
    completed = set()
    order = []
    finish = []
    n = len(processes)

    while len(completed) < n:
        # Add processes that have arrived by current time
        for p in sorted_processes:
            pid = p[0]
            if (process_dict[pid]["arrival"] <= time and 
                pid not in completed and 
                pid not in queue):
                queue.append(pid)
        
        if not queue:
            time += 1
            continue

        # Get next process from queue
        current_pid = queue.pop(0)
        
        # Execute for quantum or remaining time
        exec_time = min(quantum, process_dict[current_pid]["remaining"])
        process_dict[current_pid]["remaining"] -= exec_time
        time += exec_time
        
        # Record this execution
        order.append(current_pid)
        finish.append(time)

        # Check for new arrivals during this execution
        for p in sorted_processes:
            pid = p[0]
            if (process_dict[pid]["arrival"] <= time and 
                pid not in completed and 
                pid not in queue and 
                pid != current_pid):
                queue.append(pid)

        # If process still has work, put it back in queue
        if process_dict[current_pid]["remaining"] > 0:
            queue.append(current_pid)
        else:
            completed.add(current_pid)

    return {
        'finish': finish,
        'order': order
    }