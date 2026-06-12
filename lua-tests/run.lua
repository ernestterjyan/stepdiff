local script_path = arg and arg[0] or "lua-tests/run.lua"
local script_dir = script_path:match("^(.*)[/\\]") or "."
local repo_dir = script_dir .. "/.."

package.path = table.concat({
  repo_dir .. "/?.lua",
  script_dir .. "/?.lua",
  package.path
}, ";")

local total = 0
local failed = 0

local function fail(message)
  error(message or "assertion failed", 2)
end

local function contains(haystack, needle)
  return tostring(haystack):find(needle, 1, true) ~= nil
end

local ctx = {}

function ctx.test(name, fn)
  total = total + 1
  io.write("- " .. name .. " ... ")

  local ok, err = pcall(fn)
  if ok then
    io.write("ok\n")
  else
    failed = failed + 1
    io.write("FAIL\n")
    io.stderr:write(err .. "\n")
  end
end

function ctx.assert_true(value, message)
  if not value then
    fail(message or "expected truthy value")
  end
end

function ctx.assert_equal(actual, expected, message)
  if actual ~= expected then
    fail((message or "values differ")
      .. "\nexpected: " .. tostring(expected)
      .. "\nactual:   " .. tostring(actual))
  end
end

function ctx.assert_contains(haystack, needle, message)
  if not contains(haystack, needle) then
    fail((message or "missing expected text")
      .. "\nexpected to contain: " .. tostring(needle)
      .. "\nactual: " .. tostring(haystack))
  end
end

function ctx.assert_not_contains(haystack, needle, message)
  if contains(haystack, needle) then
    fail((message or "unexpected text found")
      .. "\ndid not expect: " .. tostring(needle)
      .. "\nactual: " .. tostring(haystack))
  end
end

local modules = {
  "test-tokenizer",
  "test-diff"
}

for _, module_name in ipairs(modules) do
  local register = require(module_name)
  register(ctx)
end

io.write(string.format("%d Lua tests, %d failures\n", total, failed))

if failed > 0 then
  os.exit(1)
end
