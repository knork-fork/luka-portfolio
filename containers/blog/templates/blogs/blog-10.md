### metadata
header: Databases
title: Indexing for people in a hurry
subtitle: A gentle mental model for when an index actually helps.
seo_description: A gentle, practical mental model for understanding when a database index actually helps.
is_featured: false
tags: ["Databases", "SQL"]
topic: null
thumbnail: null
embed_text: A gentle mental model for indexing — how to tell, quickly, when a database index actually helps.
### metadata

# Indexing for people in a hurry

You do not need to understand B-trees to use indexes well. You need one mental model: an
index is a *sorted lookup* the database keeps on the side so it can skip reading every row.

## The query

```sql
SELECT id, email
FROM users
WHERE email = 'ada@example.com';
```

Without an index, the database reads the whole table:

```
Seq Scan on users  (cost=0.00..1834.00 rows=1 width=36)
  Filter: (email = 'ada@example.com')
```

Add the index and it jumps straight to the row:

```sql
CREATE INDEX idx_users_email ON users (email);
```

```
Index Scan using idx_users_email on users  (cost=0.29..8.31 rows=1 width=36)
```

## Rules of thumb

| Situation                           | Index helps? |
|-------------------------------------|--------------|
| Column in a `WHERE` / `JOIN`        | Usually yes  |
| Tiny table (a few hundred rows)     | Rarely       |
| Column you write far more than read | Often not    |

Index the columns you *filter* on, measure with `EXPLAIN`, and resist indexing everything.
