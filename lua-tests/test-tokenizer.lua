local stepdiff = require("stepdiff")
local tokenizer = stepdiff._test.tokenize

local function token_texts(expr)
  local out = {}
  for _, token in ipairs(tokenizer(expr)) do
    out[#out + 1] = token.text
  end
  return out
end

local function join(tokens)
  return table.concat(tokens, " | ")
end

return function(t)
  local cases = {
    { expr = "x^2", expected = "x^2" },
    { expr = "x^{2}", expected = "x^{2}" },
    { expr = "a_n", expected = "a_n" },
    { expr = "a_{n+1}", expected = "a_{n+1}" },
    { expr = "\\frac{a}{b}", expected = "\\frac{a}{b}" },
    { expr = "\\sqrt{x}", expected = "\\sqrt{x}" },
    { expr = "\\sqrt[n]{x}", expected = "\\sqrt[n]{x}" },
    { expr = "\\sin x", expected = "\\sin x" },
    { expr = "\\log x", expected = "\\log x" },
    { expr = "(n+1)", expected = "(n+1)" }
  }

  for _, case in ipairs(cases) do
    t.test("tokenizer keeps " .. case.expr .. " as a useful atom", function()
      local tokens = token_texts(case.expr)
      t.assert_equal(#tokens, 1, "expected one visual atom, got " .. join(tokens))
      t.assert_equal(tokens[1], case.expected)
    end)
  end

  t.test("tokenizer preserves several visual atoms in an expression", function()
    local tokens = token_texts("x^2 + 2x + 1")
    t.assert_true(#tokens >= 5, "expected multiple comparable tokens")
    t.assert_equal(tokens[1], "x^2")
    t.assert_equal(tokens[2], "+")
    t.assert_equal(tokens[#tokens], "1")
  end)
end
