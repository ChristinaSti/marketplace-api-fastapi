# Object-relational mapping (ORM)

## What is ORM?
- is a programming technique and toolset that allows developers to interact with a relational database using the object-oriented paradigm of their programming language instead of writing raw SQL
- is a software layer that translates programming language entities (objects) to the underlying database, abstracting database details from the programmer
- classes = tables, attributes = columns, class instances/objects = rows, methods (e.g. user.save()) = SQL queries (e.g. INSERT INTO users...)

# Benefits
- can avoid repeated implementation of basic CRUD operations, reduce boilerplate code
- prevents unauthorized data access via SQL injection, since ORM sends data separately from parametrized DB queries (using data placeholders)
- can improve system performance by caching commonly-retrieved data objects for faster access

# Drawbacks
- complex OOP data structures (e.g. hierarchies) can be difficult to map to DBs
- direct SQL queries are more computationally efficient that using ORM -> especially relevant for complex queries 

# When using ORM can help:
- your app has many objects
- your app repeats similar DB queries
- schema evolution is ongoing: ORMs often include migration tools for applying changes in a structured way and version control
- DB portability: ORM abstraction layer reduces effort of moving between DB systems (but full portability is not guaranteed)

# When NOT to use ORM:
- app only performs straightforward CRUD operations
- when high-performance computing is critical, e.g. in real-time analytics, where milliseconds matter, the computational time and resources added by ORM may not be acceptable
- when you use denormalized schemas (redundant data across tables), mapping queries within ORM may not be effective