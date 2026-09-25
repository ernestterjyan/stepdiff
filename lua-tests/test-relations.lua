local stepdiff = require("stepdiff")
local test_api = stepdiff._test

local function relation_for(expr)
  local index, relation = test_api.find_alignment_relation(test_api.tokenize(expr))
  return index, relation
end

return function(t)
  local relations = {
    "=",
    "\\le",
    "\\ge",
    "<",
    ">",
    "\\approx",
    "\\sim",
    "\\equiv",
    "\\Rightarrow",
    "\\Longrightarrow"
  }

  for _, relation in ipairs(relations) do
    t.test("detects relation " .. relation, function()
      local index, found = relation_for("a " .. relation .. " b")
      t.assert_equal(index, 2)
      t.assert_equal(found, relation)
    end)

    t.test("aligns rendered output at " .. relation, function()
      local out = test_api.render_pair(nil, "a " .. relation .. " b")
      t.assert_contains(out, " & " .. relation .. " ")
    end)
  end

  t.test("keeps equality alignment unchanged", function()
    local out = test_api.render_pair("x=1", "x=2")
    t.assert_contains(out, "x & = ")
    t.assert_not_contains(out, "\\SDchanged{=}")
  end)

  t.test("does not highlight structural inequality in auto mode", function()
    local out = test_api.render_pair("a \\le b", "a \\le c")
    t.assert_contains(out, " & \\le ")
    t.assert_not_contains(out, "\\SDchanged{\\le}")
    t.assert_contains(out, "\\SDchanged{c}")
  end)

  t.test("highlights a changed alignment relation", function()
    local out = test_api.render_pair("a \\le b", "a \\ge b")
    t.assert_contains(out, "a & \\SDchanged{\\ge} ")
  end)

  t.test("highlights a new relation", function()
    local out = test_api.render_pair("a+b", "a=b")
    t.assert_contains(out, " & \\SDchanged{=} ")
  end)

  t.test("diff=all highlights the detected relation", function()
    local out = test_api.render_pair("a \\le b", "x \\le y", "all")
    t.assert_contains(out, "\\SDchanged{x}")
    t.assert_contains(out, "\\SDchanged{\\le}")
    t.assert_contains(out, "\\SDchanged{ y}")
  end)

  t.test("uses the first relation in mixed relation output", function()
    local index, relation = relation_for("a < b = c")
    t.assert_equal(index, 2)
    t.assert_equal(relation, "<")

    local out = test_api.render_pair(nil, "a < b = c")
    t.assert_contains(out, "a & < ")
  end)

  t.test("does not split relation symbols inside fraction arguments", function()
    local index, relation = relation_for("\\frac{a=b}{c}")
    t.assert_equal(index, nil)
    t.assert_equal(relation, nil)
  end)

  t.test("does not split relation symbols inside braced atoms", function()
    local index, relation = relation_for("{a \\le b}")
    t.assert_equal(index, nil)
    t.assert_equal(relation, nil)
  end)

  t.test("does not confuse longer command names with relation commands", function()
    local index, relation = relation_for("\\simulator x")
    t.assert_equal(index, nil)
    t.assert_equal(relation, nil)
  end)
end
