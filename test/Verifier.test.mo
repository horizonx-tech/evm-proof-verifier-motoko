import M "mo:matchers/Matchers";
import { run; suite; test } "mo:matchers/Suite";
import T "mo:matchers/Testable";

import Verifier "../src/Verifier";

run(
  suite(
    "Verifier",
    [
      test("Hello, World", Verifier.greet("World"), M.equals(T.text("Hello, World!"))),
    ],
  )
)
