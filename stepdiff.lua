-- stepdiff.lua
-- stepdiff v0.1.0
-- Author: Ernest Terjyan
-- Description: LuaLaTeX package for step-by-step derivations with visual diffing.
-- License: MIT
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

local weak_tokens = {
  ["+"] = true, ["-"] = true, ["("] = true, [")"] = true,
  ["["] = true, ["]"] = true, [","] = true, [";"] = true
}

local function normalize_diff_mode(mode)
  mode = strip_tex_sentinels(mode):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if mode == "false" or mode == "none" then
    return "none"
  elseif mode == "all" then
    return "all"
  end
  return "auto"
end

local function find_alignment_index(tokens)
  for i, token in ipairs(tokens) do
    if token.text == "=" then
      return i
    end
  end
  return nil
end

local function should_highlight_token(index, token, matched, alignment_index)
  if matched == nil or matched[index] then
    return false
  end

  -- The first equals sign is structural: it is used for alignment.
  if alignment_index == index and token.text == "=" then
    return false
  end

  return true
end

local function append_changed_chunk(out, chunk)
  if #chunk == 0 then
    return
  end

  local only_weak = true
  for _, token in ipairs(chunk) do
    if not weak_tokens[token.text] then
      only_weak = false
      break
    end
  end

  local first = chunk[1]
  local text = first.text
  for i = 2, #chunk do
    text = text .. chunk[i].leading .. chunk[i].text
  end

  if only_weak then
    out[#out + 1] = first.leading .. text
  else
    out[#out + 1] = first.leading .. "\\SDchanged{" .. text .. "}"
  end
end

local function render_plain_range(tokens, first_index, last_index)
  local out = {}
  for i = first_index, last_index do
    local token = tokens[i]
    out[#out + 1] = token.leading .. token.text
  end
  return table.concat(out)
end

local function render_all_range(tokens, first_index, last_index)
  local plain = render_plain_range(tokens, first_index, last_index)
  if plain == "" then
    return plain
  end
  return "\\SDchanged{" .. plain .. "}"
end

local function render_token_range(tokens, first_index, last_index, matched, alignment_index)
  local out = {}
  local chunk = {}

  for i = first_index, last_index do
    local token = tokens[i]

    if should_highlight_token(i, token, matched, alignment_index) then
      chunk[#chunk + 1] = token
    else
      append_changed_chunk(out, chunk)
      chunk = {}
      out[#out + 1] = token.leading .. token.text
    end
  end

  append_changed_chunk(out, chunk)
  return table.concat(out)
end

local function render_reason(reason)
  reason = strip_tex_sentinels(reason)
  if reason == "" then
    return "{}"
  end
  return "\\SDmaybereason{" .. reason .. "}"
end

function M.begin()
  steps = {}
end

function M.add(math, reason, diff_mode)
  math = strip_tex_sentinels(math)
  reason = strip_tex_sentinels(reason)
  diff_mode = normalize_diff_mode(diff_mode or "auto")

  steps[#steps + 1] = {
    math = math,
    reason = reason,
    diff_mode = diff_mode,
    tokens = tokenize(math)
  }
end

function M.render()
  local rows = {}

  rows[#rows + 1] = "\\begin{aligned}"

  for i, step in ipairs(steps) do
    local body

    local matched = nil
    if i > 1 and step.diff_mode == "auto" then
      matched = lcs_matches(steps[i - 1].tokens, step.tokens)
    end

    local alignment_index = find_alignment_index(step.tokens)
    local render_range = render_token_range
    if step.diff_mode == "none" then
      render_range = function(tokens, first_index, last_index)
        return render_plain_range(tokens, first_index, last_index)
      end
    elseif step.diff_mode == "all" then
      render_range = function(tokens, first_index, last_index)
        return render_all_range(tokens, first_index, last_index)
      end
    end

    if alignment_index ~= nil then
      local lhs = render_range(step.tokens, 1, alignment_index - 1, matched, alignment_index)
      local rhs = render_range(step.tokens, alignment_index + 1, #step.tokens, matched, alignment_index)
      local relation = "="
      if step.diff_mode == "all" then
        relation = "\\SDchanged{=}"
      end
      body = lhs .. " & " .. relation .. " " .. rhs
    else
      body = render_range(step.tokens, 1, #step.tokens, matched, alignment_index) .. " & {}"
    end

    rows[#rows + 1] = body .. " && " .. render_reason(step.reason)
    if i < #steps then
      rows[#rows + 1] = "\\\\"
    end
  end

  rows[#rows + 1] = "\\end{aligned}"

  local latex = strip_tex_sentinels(table.concat(rows, " "))
  tex.sprint(latex)
end

return M
