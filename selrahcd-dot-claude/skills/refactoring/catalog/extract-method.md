# Extract Method

## Motivation
A fragment of code does something that can be named at a higher level of intent than its statements reveal. Extracting the fragment into a method gives that intent a name, makes the surrounding code read at a single level of abstraction, and creates a unit reusable elsewhere.

## When NOT to use
When the fragment is trivial and the extracted name would not be clearer than the inline code. When the extracted code depends on many local variables that would need to become parameters or returned values, suggesting a deeper decomposition is needed first.

## Mechanics
1. Create a new function, name it by what it does (intent), not how.
2. Copy the extracted code from the source location into the new function. 🧪
3. Scan the extracted code for any local variables referenced only in the source. Pass them as parameters.
4. Compile.
5. Scan for any variables assigned by the extracted code that are still used in the source. Return them. 🧪
6. Replace the original fragment in the source with a call to the new function. 🧪
7. Look for similar code that can now call the new function (Replace Inline Code with Function Call). 🧪

## Example
Before:
```
function printOwing(invoice) {
  printBanner();
  let outstanding = calculateOutstanding();
  console.log(`name: ${invoice.customer}`);
  console.log(`amount: ${outstanding}`);
}
```
After:
```
function printOwing(invoice) {
  printBanner();
  let outstanding = calculateOutstanding();
  printDetails(invoice, outstanding);
}

function printDetails(invoice, outstanding) {
  console.log(`name: ${invoice.customer}`);
  console.log(`amount: ${outstanding}`);
}
```

## Common pitfalls
- Passing too many parameters because the extracted block touches too much state — that's a signal to split the source method differently or apply Extract Class.
- Reassigning a parameter inside the new function — break this into a separate variable first.
- Naming by mechanism (`doStep1`) instead of intent (`printDetails`).
