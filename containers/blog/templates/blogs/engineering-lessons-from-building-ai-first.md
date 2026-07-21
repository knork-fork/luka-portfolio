### metadata
title: Engineering Lessons from Building an AI-First Feature
subtitle: What changed beyond the code
card_label: Retrospective
force_gradient: null

seo_description: Practical lessons from building an AI-first product feature, covering code review, architectural decision records, service boundaries, and R&D.
embed_text: What building an AI-first feature changed about code review, technical decisions, service boundaries, and research.

is_published: true
is_featured: false

tags: ["AI", "Engineering"]
topic: null

thumbnail: null

created_at: 2026-07-13T10:00:00+02:00
modified_at: 2026-07-21T10:45:00+02:00
### metadata

This post accompanies a major feature release I worked on. You can read more about the feature itself on [LinkedIn](https://www.linkedin.com/posts/lukaknezic98_gis-ai-geospatialai-share-7482367298541056001-_Rtl/?utm_source=share&utm_medium=member_desktop&rcm=ACoAAB5fMIsBXDziSG1D7k2XmAW1y9Kg_WV35vY).

## A new label

Recently I attended a few meetups that had AI engineering and development as a topic and despite being a self-proclaimed AI-skeptic I ended up pleasantly surprised.

There was no huge *SaaS Company #5120* ad poster showing off their barely unique framework or subscription-based developer tools and there were no panelists trying to spread their eccentric cargo cults.

In fact, no one in the room was trying to sell anything and it was actually full of seemingly equally confused people who were all trying to figure out how they even felt with their new skills and responsibilities. No one was selling a finished solution, because nobody in the room seemed convinced that one existed yet.

Adding to the confusion was this new "AI-first" label. I had already been using AI tools for years. Apparently, using them was not the same as reorganizing the engineering process around what they made possible.

## What changed?

Some call it a "paradigm shift"; I prefer the much simpler term "adapting", since software engineering has always been about adapting to new challenges and environments.
But even with a grounded and almost stoic approach, it was still hard to separate hype from reality, which is why in this article I opted to focus more on consequences rather than the philosophical bike-shedding of what AI-first is or isn't.

Ignoring the last 6 months of LLM harness developments, one of the clearest practical changes is simply the much larger volume of output our existing processes are expected to absorb. Not being prepared to handle that volume is, in my opinion, an engineering problem, not an AI problem (nor any other tool's problem, for that matter). And engineering problems exist so that we can solve them.

In the sections below, I’ll outline some of the lessons I learned from building an AI feature with AI embedded throughout the development process, focusing on how existing engineering practices had to adapt rather than on inventing new tools and methodologies.

## Code reviews

The goal of a code review is more or less to add another pair of eyes to ensure human error is kept to a minimum.
Code reviews were traditionally a manual step somewhere between CI and QA, but they were never really in the spotlight because reading the code was simply an order of magnitude faster than writing it, so not much thought was given to optimizing this process.

So what happens when the implementation throughput suddenly shoots through the roof and code review becomes an apparent bottleneck?
Either you accept that the human reviewers are the slower part of the process and optimize around that fact, or you let go and automate the review process itself and leave your fate to entropy?

Luckily, a balanced approach exists, and I'll outline some approaches below.

#### Limit the scope

A large diff is still a large diff, regardless of how quickly it was written.
Keeping changes focused makes them easier to understand, test, and discuss.

#### Don't focus on syntax

Compilers, formatters, linters, static analysis and other automated checks already exist for issues that are trivial to automate.
Human review time is better spent on intent, architecture, assumptions, edge cases and whether the implementation solves the right problem.

#### Focus on the bigger picture

A small section, single file or class may appear perfectly reasonable in isolation while fitting poorly into the rest of the system.
Reviewing individual lines is not enough; the reviewer also needs to understand where the change belongs and what it affects.

#### Agree on a common standard

Not all teams enforce the same standards, and even within one team, not every repository is maintained with the same level of care.
Make sure everyone working on the same project agrees on what is acceptable: architectural boundaries, naming, testing expectations, error handling and the level of polish expected before review.
This becomes more important when AI tools can quickly reproduce whatever inconsistencies already exist in the codebase.

Keep in mind:
> Increasing implementation throughput without changing the review process mostly moves the bottleneck downstream and makes it someone else's problem.


## Leave a paper trail

If design patterns are just a fancy way of saying "you really shouldn't be reinventing the wheel", then architecture decision records (ADRs) are really just a paper trail of your thought process. The code tells you what was implemented, but it rarely tells you why that approach was chosen, which alternatives were considered, or which constraints mattered at the time.

You don't need to start with a [MADR template](https://github.com/adr/madr); just documenting your decisions and the reasoning behind them is already a huge step forward.
This becomes especially useful when AI can produce a plausible implementation before anyone has properly articulated why it should be built that way.

> You do not want to find yourself in a situation six months from now where your only answer to "why?" is "because Claude did it that way".


## Service boundaries start to matter

Saying "we should turn this into a microservice" sounds like something straight out of a 2019 blog post, but there's a good reason why people were crazy about domain-splitting and hexagonal architecture.

It was about designing systems with clear contracts, boundaries and responsibilities, and most of that applies to modern AI-first development as well.

AI-heavy code is often experimental and prone to changes. Isolating it behind a stable interface can be a pragmatic choice, even when splitting this system into a service would otherwise be unnecessary. For example, an AI "service" may be just a wrapper around an AI provider's API and this wouldn't technically justify a separate service, but the code itself will probably change frequently, depend on nondeterministic behavior and require different testing and review practices compared to the stable application around it.

> Extracting fast-changing AI-heavy code behind a clear service boundary can keep experimentation from leaking into the rest of the system.


## Don't forget the research

Some things that used to be nitpicks in code review have now become serious complaints, while some critical implementation problems were reduced to five-minute Claude sessions.
Terminology and concepts started appearing in meetings that had never been discussed before, and design decisions increasingly depended on technologies that did not exist a few months earlier.

If anything, AI gave us a reminder that R&D is still a critical part of engineering, and prototyping remains a key part of learning the constraints of a system, disproving assumptions and making decisions.

There's even a very nice symbiosis between AI and AI-first development:
- AI as an ecosystem of tools and services comes with a never-ending stream of new technologies and capabilities, forcing constant re-learning
- in turn, AI-first development enables rapid prototyping and experimentation, allowing developers to catch up

> Taking shortcuts and skipping homework is a one-way ticket to cognitive dependency and piled-up technical debt.


## Closing words

You may have noticed that this post doesn't really reinvent the wheel or offer shiny new, ground-breaking AI-first practices.

That isn't to say they don't exist, but I deliberately chose to leave them for a future post. This one was already long enough, and I wanted to focus on the lessons learned directly from the project I worked on.

Expect more in the near future. If you have any questions or want to discuss the topic, feel free to reach out (or leave a comment on the [LinkedIn post](https://www.linkedin.com/posts/lukaknezic98_gis-ai-geospatialai-share-7482367298541056001-_Rtl/?utm_source=share&utm_medium=member_desktop&rcm=ACoAAB5fMIsBXDziSG1D7k2XmAW1y9Kg_WV35vY)).

See more:
- [AI Makes You Faster, But Not More Productive](https://luka-knezic.com/blog/ai-makes-you-faster-but-not-productive)