### metadata
header: Security
title: Threat modelling for small projects
subtitle: You do not need a big team to think about attackers.
seo_description: How to do lightweight threat modelling for small projects without a dedicated security team.
is_featured: false
tags: ["Security"]
topic: null
thumbnail: null
embed_text: Threat modelling for small projects — you don't need a big team to start thinking about attackers.
### metadata

# Threat modelling for small projects

Threat modelling sounds like something that needs a war room and a whiteboard. For a
small project it is really just one question asked honestly: **what could go wrong here?**

## A lightweight pass: STRIDE

| Threat                  | Example on a small app            |
|-------------------------|-----------------------------------|
| **S**poofing            | Guessable session tokens          |
| **T**ampering           | Editing a price in a form post    |
| **R**epudiation         | No audit trail for admin actions  |
| **I**nfo disclosure     | Stack traces leaking to users     |
| **D**enial of service   | An unbounded search query         |
| **E**levation of priv.  | A missing role check on a route   |

## Fix the cheap ones first

Never trust input that came from a user. Escape on the way out:

```php
echo '<h1>' . htmlspecialchars($title, ENT_QUOTES, 'UTF-8') . '</h1>';
```

And keep secrets out of the repo — grep your history before it bites you:

```bash
git log -p | rg -i 'api[_-]?key|secret|password'
```

> You will not stop a determined attacker with a weekend of effort. You *will* stop the
> boring, automated 90% — and for a small project that is most of the risk.
