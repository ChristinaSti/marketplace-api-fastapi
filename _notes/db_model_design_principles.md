# DB Model Design Principles

## Auto-Increment (Surrogate Key) vs. UUID v7 as PKs
### Principles
1. Auto-increment: 
- db automatically assigns the next available integer to each record
- requires a central authority (the database) to track the current sequence
2. UUID v7:
- uses the current Unix Epoch timestamp (in milliseconds) for the first 48 bits, followed by random data => IDs generated later are numerically greater than earlier ones => are time-ordered
    - note: earlier UUID versions were not time-ordered (no timestamp in the first bits) => did not have the advantages of ordered index keys (as elaborated in the pros and cons section)
- is usually made of 32 hex values and 4 hyphens, e.g. `550e8400-e29b-41d4-a716-446655440000`
    - hexadecimal: base 16 => 16 possible values: 0-9, A(10)-F(15)
    - each hex char is represented by 4 bits with the values 8-4-2-1 that get 1 if they participate in the sum to get the hex char value, otherwise 0 => D = 13 = 8 + 4 + 1 = 1-1-0-1
- excludes collisions through a combination of temporal separation (same IDs need to generated in the same millisecond window) and statistical improbability (remaining 74 bits provides roughly 1.8 x 10²² possible combinations for that single millisecond)

### Pros and Cons
- **Storage size**:
1. Auto-increment: smaller
    - (TINYINT  1 byte  -128 - 127)
    - SMALLINT  2 bytes -32,768 to +32,767
    - INT       4 bytes -2,147,483,648 to +2,147,483,647
    - BIGINT    8 bytes -9,223,372,036,854,775,808 to +9,223,372,036,854,775,807
2. UUID v7: larger
    - 16 bytes = 128 bits
- **Performance**:
    - generally: 
        - Smaller keys mean more records fit into each database page => fewer costly I/O operations (read: fetch page from disk to memory, write: vice versa)
        - ordered keys mean new data is appended to the end of the index => this part of the index can be kept in cache/RAM nearly eliminating expensive disk reads

- **Distributed systems**:
1. Auto-increment: 
- con: requires central coordination (performance bottleneck) to avoid duplicate IDs across different servers
2. UUID v7:
- pro: can be generated independently on different nodes without collisions

- **Security**:
1. Auto-increment: 
- con: IDs are predictable, allowing attackers to guess other records or estimate total data size
2. UUID v7:
- pro: random components make them harder to guess, though timestamps are exposed

- **Offline generation**:
1. Auto-increment: 
- con: impossible; requires a connection to the database to get the next ID
2. UUID v7:
- pro: possible; clients or services can generate IDs before sending data to the database

#### summary:
- Use Auto-increment when/for: performance is absolute priority, human readability is required (e.g. for debugging), storage space is limited, strict internal use (no public URLs or APIs using IDs)
- Use UUID v7 when/for: building distributed systems, IDs are public-facing, data migration/merging is likely

## Unique constraints
- ensures all values in a specific column are distinct
- unlike primary key, unique constraint allows for NULL values and can be applied multiple times per table

### When to use it
- Enforce Business Rules: Use it for secondary identifiers that must be unique but are not the primary key, such as email addresses, usernames, phone numbers, or passport IDs
- Composite Uniqueness: Apply it to combinations of columns to prevent duplicate relationships, such as ensuring a student cannot enroll in the same course twice
- Support Search Performance: Unique constraints automatically create a unique index. This is ideal for columns frequently used in WHERE clauses for searching or filtering
- Data Integrity "Last Line of Defense": Even if application logic checks for duplicates, use database-level constraints to prevent race conditions or "dirty" data from manual entries.

### When to avoid it
- High-Volume Write Operations