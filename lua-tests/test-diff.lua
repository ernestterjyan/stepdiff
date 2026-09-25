local stepdiff = require("stepdiff")
local diff = stepdiff._test

local function render_pair(prev_math, curr_math, mode)
  return diff.render_pair(prev_math, curr_math, mode)
end

return function(t)
  t.test("diff renders changed chunks for algebra expansion", function()
    local out = render_pair("a(x+b)", "ax+ab")
    t.assert_contains(out, "\\SDchanged{", "changed algebra output should be highlighted")
    t.assert_contains(out, "& {}", "unaligned expression should still render an alignment cell")
  end)

  t.test("diff renders changed chunks for derivative-like pair", function()
    local out = render_pair("x^2+2x+1", "2x+2")
    t.assert_contains(out, "\\SDchanged{", "changed derivative-like output should be highlighted")
    t.assert_not_contains(out, "nil", "rendered output should not contain Lua nil")
  end)

  t.test("diff renders aligned equations without highlighting the structural equals", function()
    local out = render_pair("S_n=1+\\cdots+n", "S_n=n+(n-1)+\\cdots+1")
    t.assert_contains(out, " & = ", "equations should align at the first equals sign")
    t.assert_contains(out, "\\SDchanged{", "changed equation terms should be highlighted")
    t.assert_not_contains(out, "\\SDchanged{=}", "auto mode should not highlight the alignment equals")
  end)

  t.test("identical expressions are not highlighted", function()
    local out = render_pair("x^2+1", "x^2+1")
    t.assert_not_contains(out, "\\SDchanged{", "unchanged output should not be highlighted")
  end)

  t.test("repeated atoms keep their common prefix", function()
    local out = render_pair("x+x", "x+x+x")
    t.assert_equal(out, "x+x\\SDchanged{+x} & {}")
  end)

  t.test("matching does not cross the relation", function()
    local out = render_pair("a=b", "b=a")
    t.assert_contains(out, "\\SDchanged{b} & = \\SDchanged{a}")
  end)

  t.test("removing a relation remains visible", function()
    local out = render_pair("a=b", "ab")
    t.assert_equal(out, "\\SDchanged{ab} & {}")
  end)

  t.test("deletion-only changes emphasize the surviving expression", function()
    local out = render_pair("x+y", "x")
    t.assert_equal(out, "\\SDchanged{x} & {}")
  end)

  t.test("diff=false disables highlighting", function()
    local out = render_pair("x", "y", "false")
    t.assert_equal(out, "y & {}")
    t.assert_not_contains(out, "\\SDchanged{", "diff=false should render plain output")
  end)

  t.test("diff=all highlights the whole unaligned expression", function()
    local out = render_pair("x", "y", "all")
    t.assert_equal(out, "\\SDchanged{y} & {}")
  end)

  t.test("diff=all highlights both sides and relation for equations", function()
    local out = render_pair("x=1", "y=2", "all")
    t.assert_contains(out, "\\SDchanged{y}")
    t.assert_contains(out, "\\SDchanged{=}")
    t.assert_contains(out, "\\SDchanged{2}")
  end)

  t.test("overlay rendering wraps each aligned cell", function()
    local out = diff.render_overlay_pair("x=1", "x=2", "2-")
    t.assert_contains(out, "\\onslide<2->{x}")
    t.assert_contains(out, " & \\onslide<2->{= \\SDchanged{2}}")
    t.assert_contains(out, " && \\onslide<2->{\\SDmaybereason{shown}}")
  end)

end
