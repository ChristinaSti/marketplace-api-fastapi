# Web Server
## Uvicorn
- is a lightweight, fast ASGI (Asynchronous Server Gateway Interface) web server implementation for Python
- is designed to run asynchronous web applications (using `async def` and `await`) and frameworks such as FastAPI, Starlette (handling incoming HTTP requests and returning responses, layer between network and python code)
- asynchronous/concurrency(interleaving tasks): the program does not block while waiting for slow operations, i.e. network (e.g. HTTP request), disk (file read/write), database queries. One worker can switch between tasks (e.g. requests) during waits which is managed by an event loop
    - => especially helpful for I/O heavy applications
    - it is not parallelism/multi-processing on multiple CPU cores => does NOT help with CPU heavy work (e.g. data processing, ML)
- `CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]`

## Gunicorn
- is a Python WSGI HTTP server => by itself currently support for async frameworks like FastAPI
- it implements a pre-fork worker model: the master process manages a configurable pool of worker processes - each handling multiple HTTP requests
- it is a process manager, crashed workers are automatically restarted without service interruption

## Combining Gunicorn with Uvicorn
- => in this project on Cloud Run, if each container has multiple CPUs, guvicorn could be used for vertical scaling to manage the same number of uvicorn workers as there are CPUs <br>
`CMD ["gunicorn", "-k", "uvicorn.workers.UvicornWorker", "app.main:app", "--bind", "0.0.0.0:8080", "--workers", "2"]`
- but there are nuances to be considered for Cloud Run:
    - Cloud Run already does horizontal scaling (more instances, adaption to traffick burst is slower than in vertical scaling due to cold start) and request concurrency per instance
    - too many workers can also hurt, since memory usage goes up, there is more context switching, number of DB connection can explode (since every worker itself has a connection pool) which can break the system
        -=> When to add more CPUs (and workers): requests are CPU-heavy, CPU usage is consistently high, scaling lag causes latency spikes, DB connections are NOT too high yet


    
