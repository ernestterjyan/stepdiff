local stepdiff = require("stepdiff")
local diff = stepdiff._test

return function(t)
  t.test("single color mode keeps generic changed wrapper", function()
    local out = diff.render_pair_color("x", "y", "auto", "single")
    t.assert_contains(out, "\\SDchanged{y}")
    t.assert_not_contains(out, "\\SDmodified{y}")
  end)

  t.test("typed color mode renders simple additions", function()
    local out = diff.render_pair_color("x", "x+1", "auto", "typed")
    t.assert_contains(out, "\\SDadded{+1}")
    t.assert_not_contains(out, "\\SDchanged{1}")
  end)

  t.test("typed color mode renders replacements as modified", function()
    local out = diff.render_pair_color("x", "y", "auto", "typed")
    t.assert_contains(out, "\\SDmodified{y}")
  end)

  t.test("diff=all uses modified category in typed mode", function()
    local out = diff.render_pair_color("x", "y", "all", "typed")
    t.assert_equal(out, "\\SDmodified{y} & {}")
  end)

  t.test("teaching mode detects lim applied to both sides", function()
    local out = diff.render_pair_color("a_n \\le b_n", "\\lim a_n \\le \\lim b_n", "auto", "teaching")
    t.assert_contains(out, "\\SDoperation{\\lim} a_n")
    t.assert_contains(out, "\\le  \\SDoperation{\\lim} b_n")
  end)

  t.test("typed mode falls back to added for detected operations", function()
    local out = diff.render_pair_color("a_n \\le b_n", "\\lim a_n \\le \\lim b_n", "auto", "typed")
    t.assert_contains(out, "\\SDadded{\\lim} a_n")
    t.assert_not_contains(out, "\\SDoperation{\\lim}")
  end)

  t.test("operation detection falls back when only one side has the prefix", function()
    local out = diff.render_pair_color("a_n \\le b_n", "\\lim a_n \\le b_n", "auto", "teaching")
    t.assert_not_contains(out, "\\SDoperation{\\lim}")
    t.assert_contains(out, "\\SDadded{\\lim}")
  end)
end
