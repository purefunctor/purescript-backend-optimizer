import * as $runtime from "../runtime.js";
import * as Data$dSemigroup from "../Data.Semigroup/index.js";
import * as Snapshot$dDefaultRulesSemigroup02$foreign from "./foreign.js";
const x = Snapshot$dDefaultRulesSemigroup02$foreign.x;
const append = ra => rb => ({bar: Data$dSemigroup.concatArray(ra.bar)(rb.bar), foo: ra.foo + rb.foo});
const test4 = {bar: ["hello", "World!"], foo: "hello, World!"};
const test3 = /* #__PURE__ */ append({foo: "hello", bar: ["hello"]});
const test2 = a => b => ({bar: Data$dSemigroup.concatArray(a.bar)(b.bar), foo: a.foo + b.foo});
const test1 = append;
export {append, test1, test2, test3, test4, x};
export * from "./foreign.js";