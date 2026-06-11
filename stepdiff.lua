-- stepdiff.lua
--
-- Token-level visual diffing for the stepdiff LaTeX package.
-- This module deliberately does not understand mathematics. It tokenizes the
-- input as simple LaTeX/math syntax, compares consecutive lines with an LCS
-- algorithm, and wraps changed tokens from the current line in \SDchanged{...}.

local M = {}

local steps = {}

local function strip_tex_sentinels(s)
  -- tex.sprint inserts literal newlines as ordinary character tokens in math
  -- mode, which can render as visible glyphs. Keep emitted TeX one-line.
  return (s or ""):gsub("Ω", ""):gsub("%$", ""):gsub("[\r\n]", " ")
end

local function is_space(c)
  return c:match("%s") ~= nil
end

local function is_letter(c)
  return c:match("%a") ~= nil
end

local function is_digit(c)
  return c:match("%d") ~= nil
end

local function capture_balanced(s, i, open_char, close_char)
  local depth = 0
  local j = i

  while j <= #s do
    local c = s:sub(j, j)

    if c == "\\" then
      -- Skip escaped single characters while looking for the matching brace.
      j = math.min(j + 2, #s + 1)
    else
      if c == open_char then
        depth = depth + 1
      elseif c == close_char then
        depth = depth - 1
        if depth == 0 then
          return s:sub(i, j), j + 1
        end
      end
      j = j + 1
    end
  end

  -- Unbalanced input: return the rest rather than failing hard.
  return s:sub(i), #s + 1
end

local function skip_spaces(s, i)
  while i <= #s and is_space(s:sub(i, i)) do
    i = i + 1
  end
  return i
end

local function read_command_token(s, i)
  local j = i + 1
  local name_start = j

  if j <= #s and is_letter(s:sub(j, j)) then
    while j <= #s and is_letter(s:sub(j, j)) do
      j = j + 1
    end
  elseif j <= #s then
    j = j + 1
  end

  local text = s:sub(i, j - 1)

  -- Keep common command arguments attached to the command token. This avoids
  -- producing invalid LaTeX such as \SDchanged{\frac}\SDchanged{{a}}.
  local k = skip_spaces(s, j)
  if k <= #s and s:sub(k, k) == "[" then
    local opt, after_opt = capture_balanced(s, k, "[", "]")
    text = text .. s:sub(j, k - 1) .. opt
    j = after_opt
    k = skip_spaces(s, j)
  end

  local group_count = 0
  while k <= #s and s:sub(k, k) == "{" and group_count < 2 do
    local group, after_group = capture_balanced(s, k, "{", "}")
    text = text .. s:sub(j, k - 1) .. group
    j = after_group
    k = skip_spaces(s, j)
    group_count = group_count + 1
  end

  return text, j
end

local function read_number_token(s, i)
  local j = i
  while j <= #s do
    local c = s:sub(j, j)
    if is_digit(c) or c == "." then
      j = j + 1
    else
      break
    end
  end
  return s:sub(i, j - 1), j
end

local function read_script_argument(s, i)
  if i > #s then
    return "", i
  end

  local c = s:sub(i, i)

  if c == "{" then
    return capture_balanced(s, i, "{", "}")
  elseif c == "\\" then
    return read_command_token(s, i)
  elseif is_digit(c) then
    return read_number_token(s, i)
  else
    return c, i + 1
  end
end

local function read_math_suffixes(s, text, i)
  while i <= #s do
    local c = s:sub(i, i)

    if c == "'" then
      text = text .. c
      i = i + 1
    elseif c == "^" or c == "_" then
      local op = c
      local arg_start = skip_spaces(s, i + 1)
      local arg, after_arg = read_script_argument(s, arg_start)
      text = text .. op .. s:sub(i + 1, arg_start - 1) .. arg
      i = after_arg
    else
      break
    end
  end

  return text, i
end

local function tokenize(s)
  local tokens = {}
  local i = 1
  local leading = ""

  while i <= #s do
    local c = s:sub(i, i)

    if is_space(c) then
      leading = leading .. c
      i = i + 1
    elseif c == "\\" then
      local text, next_i = read_command_token(s, i)
      text, next_i = read_math_suffixes(s, text, next_i)
      tokens[#tokens + 1] = { text = text, leading = leading }
      leading = ""
      i = next_i
    elseif c == "{" then
      local text, next_i = capture_balanced(s, i, "{", "}")
      tokens[#tokens + 1] = { text = text, leading = leading }
      leading = ""
      i = next_i
    elseif is_digit(c) then
      local text, next_i = read_number_token(s, i)
      text, next_i = read_math_suffixes(s, text, next_i)
      tokens[#tokens + 1] = { text = text, leading = leading }
      leading = ""
      i = next_i
    elseif is_letter(c) then
      -- Treat variables as individual tokens so "ax" can be compared as a*x.
      local text, next_i = read_math_suffixes(s, c, i + 1)
      tokens[#tokens + 1] = { text = text, leading = leading }
      leading = ""
      i = next_i
    else
      tokens[#tokens + 1] = { text = c, leading = leading }
      leading = ""
      i = i + 1
    end
  end

  return tokens
end

local function lcs_matches(prev, curr)
  local n = #prev
  local m = #curr
  local dp = {}

  for i = 0, n do
    dp[i] = {}
    for j = 0, m do
      dp[i][j] = 0
    end
  end

  for i = 1, n do
    for j = 1, m do
      if prev[i].text == curr[j].text then
        dp[i][j] = dp[i - 1][j - 1] + 1
      else
        dp[i][j] = math.max(dp[i - 1][j], dp[i][j - 1])
      end
    end
  end

  local matched_curr = {}
  local i = n
  local j = m

  while i > 0 and j > 0 do
    if prev[i].text == curr[j].text then
      matched_curr[j] = true
      i = i - 1
      j = j - 1
    elseif dp[i - 1][j] >= dp[i][j - 1] then
      i = i - 1
    else
      j = j - 1
    end
  end

  return matched_curr
end

local function highlight_token(token)
  return token.leading .. "\\SDchanged{" .. token.text .. "}"
end

local function render_tokens(tokens, matched)
  local out = {}

  for i, token in ipairs(tokens) do
    if matched == nil or matched[i] then
      out[#out + 1] = token.leading .. token.text
    else
      out[#out + 1] = highlight_token(token)
    end
  end

  return table.concat(out)
end

local function render_reason(reason)
  reason = strip_tex_sentinels(reason)
  if reason == "" then
    return "{}"
  end
  return "\\quad\\text{\\SDreason{" .. reason .. "}}"
end

function M.begin()
  steps = {}
end

function M.add(math, reason)
  math = strip_tex_sentinels(math)
  reason = strip_tex_sentinels(reason)

  steps[#steps + 1] = {
    math = math,
    reason = reason,
    tokens = tokenize(math)
  }
end

function M.render()
  local rows = {}

  rows[#rows + 1] = "\\begin{aligned}"

  for i, step in ipairs(steps) do
    local body

    if i == 1 then
      body = render_tokens(step.tokens, nil)
    else
      local matched = lcs_matches(steps[i - 1].tokens, step.tokens)
      body = render_tokens(step.tokens, matched)
    end

    rows[#rows + 1] = body .. " & " .. render_reason(step.reason)
    if i < #steps then
      rows[#rows + 1] = "\\\\"
    end
  end

  rows[#rows + 1] = "\\end{aligned}"

  local latex = strip_tex_sentinels(table.concat(rows, " "))
  tex.sprint(latex)
end

return M
