### metadata
header: Testing
title: Writing tests I actually trust
subtitle: Moving past coverage numbers toward meaningful assertions.
seo_description: How to write tests you actually trust by moving past coverage numbers toward meaningful assertions.
is_featured: false
tags: ["Testing", "Quality"]
topic: null
thumbnail: null
embed_text: Writing tests I actually trust — moving past coverage numbers toward assertions that mean something.
### metadata

# Writing tests I actually trust

For a long time I chased ~~100% coverage~~ a green coverage badge. Then a fully-covered
module shipped an embarrassing bug, and I changed how I think about tests.

## Coverage is a map, not the territory

A test is only worth keeping if it would **fail** for a real reason. Assert on behaviour,
not on implementation details:

```php
final class PriceTest extends TestCase
{
    public function testAppliesPercentageDiscount(): void
    {
        $price = new Price(100_00);

        $discounted = $price->applyDiscount(15);

        self::assertSame(85_00, $discounted->cents());
    }
}
```

## My checklist for a test worth keeping

- [x] Fails when the behaviour breaks
- [x] Has a name that reads like a sentence
- [ ] Depends on the current implementation
- [ ] Needs a comment to explain what it's doing

If a test only exists to bump a number, it is a liability, not an asset.
