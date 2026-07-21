### metadata
title: AI Makes You Faster, But Not More Productive
subtitle: Why speed alone does not always lead to faster delivery
card_label: AI Productivity
force_gradient: blog-card-grad-4

seo_description: An exploration of why AI can increase the speed of individual work without necessarily improving overall productivity or delivery.
embed_text: Why working faster with AI does not automatically translate into greater productivity or faster delivery.

is_published: true
is_featured: true

tags: ["AI", "Engineering", "Productivity"]
topic: null

thumbnail: null

created_at: 2026-07-21T09:30:00+02:00
modified_at: null
### metadata

## Force multipliers

Just a few years ago, "10x developers" were a hot topic - superstar developers who could replace entire teams by themselves, and deliver features faster than anyone else.

After hype cooled down and the dust settled it turned out a team of non-10x developers who were team players were a much better fit, as all that output also had to be maintained (and preferably documented).

Fast forward to today, and now we have "100x developers" who can use AI to outperform and outproduce entire departments and spit out features faster than they could be reviewed or tested.

Skipping past the fact that history repeated itself, the difference this time around is that the force multiplier is not an individual, but a tool given to an individual. This is why it is important to note that "force multiplier" is not a standalone property, but rather a multiplication of the individual using the tool (with all the positive and negative connotations that may bring).

## A video game analogy

In order to better demonstrate my point, I'm going to be using Factorio as an analogy.

While some consider it Minecraft with an Excel spreadsheet, in a broader sense it's actually a game about optimizing pipelines and processes, and finding and fixing bottlenecks without just throwing in more resources in the hope of a problem going away.

If that sounds familiar, you'll quickly realize why the Factorio community overlaps so much with engineering and software development communities.

<img src="/static/blog_media/factorio_assembler.jpg" alt="A humble assembler with no upgrades">

In Factorio, an assembler is the bread and butter of every factory. It's a machine that takes in raw materials and produces some form of a product.

Thinking about it more generally, it's a worker that uses resources to produce something of value.

In order to get a complex, finished product, one would need to connect multiple assemblers together into something that closely resembles a process pipeline.

If we are in the context of developing a feature, this pipeline would look something like this:
- Tech Specs
- Estimation
- Implementation
- Review
- Testing
- Delivery

To simplify, we'll transform a basic pipeline into a small factory with just two assemblers, where the first assembler produces gears, and the second assembler consumes those gears to produce a more complex item. This corresponds to a developer working on the implementation phase, and a second developer reviewing their work.

## Need for speed

We wanted to speed up the development, so in the video shown below we have upgraded the assembler on the left with so-called speed modules (displayed as 4 blue square icons). These modules increase the crafting speed of an assembler, at the cost of increased electricity consumption.

<video src="/static/blog_media/factorio_speed.webm" autoplay loop muted playsinline data-caption="Assembler on the left produces gears, assembler on the right consumes gears to produce a more complex item"></video>

This speed-optimized assembler represents a developer who is using AI to increase their output. If the same standard of quality is expected before the code reaches the next stage of the pipeline, then the reviewer still has just as much work to do as before.

At first, the first assembler rapidly produces gears, but after a while the conveyor belt leading to the second assembler gets clogged up as the second assembler simply cannot keep up with the first one.

The first assembler now often idles (wasting all those expensive speed modules) and the second assembler ends up being the bottleneck of the whole process, despite having no control over how quickly work is pushed into its stage of the process.

If we take a look at the in-game production graph below, we can see that the first assembler is consuming around 30 iron plates per minute to supply the second assembler with gears, while the second assembler is producing 15 complex products per minute using those gears (the ratio is not an accident, it takes two iron plates and a single copper plate to produce one [automation science pack](https://wiki.factorio.com/Automation_science_pack)).

<img src="/static/blog_media/factorio_speed_graph.jpg" alt="Production rates shown on the left, and consumption rates shown on the right.">


## Slow down

What if, instead, the two developers worked in harmony and they found a way to spend some of their allocated time improving the process rather than focusing on completing the feature work and then handing it off to the next stage as soon as possible? The formula is simple - decreasing the amount of total work that needs to be done means the job is done faster without sacrificing quality.

The video below shows the same two assemblers, only this time both are equipped with productivity modules (4 orange square icons). These modules increase the amount of output produced per unit of input, at the cost of increased electricity consumption **but also slower crafting speed**.

<video src="/static/blog_media/factorio_prod.webm" autoplay loop muted playsinline data-caption="Notice the left assembler being a lot less idle now that it's slower"></video>

Not only does the first assembler now idle less, productivity modules in both assemblers cause the whole production line to use less raw materials, and productivity bonuses stack at each additional assembler in the production chain - unlike speed, which only affects that single assembler.

Comparing the first graph to this one, we can see that the second assembler is now producing 12 science packs per minute (slightly down from previous 15 per minute), but the first assembler is now consuming only 4.8 iron plates per minute, which means that the overall process is now more than six times cheaper in raw iron cost.

<img src="/static/blog_media/factorio_prod_graph.jpg" alt="Much cheaper automation science packs">

You may wonder why it's okay that we settle for a slightly lower rate of those science packs, but remember - the productivity stacks, so if we put productivity modules into the consumer of those science packs (the lab building that consumes science packs to research new technologies on the tech tree), then we'll need less science packs to achieve the same result.

This translates well to software development - if we can reduce the amount of code that needs to be written (by e.g. limiting the scope), then we also reduce the amount of code review that needs to be done, reduce the amount of testing that needs to be done and so on.

## How to be productive

If we were to compare Factorio's speed and productivity modules side by side in a vacuum, speed modules would appear faster and thus look more enticing - the reality is however that productivity is a better choice in almost all cases because its effects compound and stack.

It is however not always obvious how productivity can be improved, as real-world is not as simple as inserting modules into a digital machine.

This post should then serve as a reminder that sometimes the most productive thing we can do is slow down and **think**: question the scope, simplify the solution, improve the process, or avoid creating unnecessary work in the first place.

If you want to discuss the topic or have examples of productivity, feel free to reach out (or leave a comment on the LinkedIn post).
