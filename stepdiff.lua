-- stepdiff.lua
-- Version: 1.1.1
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
local current_options = { frame = false, color_mode = "single", legend = false }

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

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

-- ---------------------------------------------------------------------------
-- Tokenizer
-- ---------------------------------------------------------------------------

local command_group_counts = {
  ["\\frac"] = 2,
  ["\\dfrac"] = 2,
  ["\\tfrac"] = 2,
  ["\\binom"] = 2,
  ["\\sqrt"] = 1,
  ["\\text"] = 1,
  ["\\mathrm"] = 1,
  ["\\mathbf"] = 1,
  ["\\operatorname"] = 1
}

local function_commands = {
  ["\\sin"] = true,
  ["\\cos"] = true,
  ["\\tan"] = true,
  ["\\cot"] = true,
  ["\\sec"] = true,
  ["\\csc"] = true,
  ["\\log"] = true,
  ["\\ln"] = true,
  ["\\exp"] = true
}

local function capture_balanced(s, i, open_char, close_char)
  local depth = 0
  local j = i

  while j <= #s do
    local c = s:sub(j, j)

    if c == "\\" then
      -- Skip escaped single characters while looking for the matching delimiter.
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

local read_command_token
local read_math_suffixes
local read_atom

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

  local text, next_i = read_atom(s, i)
  return text, next_i
end

read_math_suffixes = function(s, text, i)
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

read_command_token = function(s, i)
  local j = i + 1

  if j <= #s and is_letter(s:sub(j, j)) then
    while j <= #s and is_letter(s:sub(j, j)) do
      j = j + 1
    end
  elseif j <= #s then
    j = j + 1
  end

  local command = s:sub(i, j - 1)
  local text = command
  local group_limit = command_group_counts[command] or 0

  local k = skip_spaces(s, j)
  if k <= #s and s:sub(k, k) == "[" then
    local opt, after_opt = capture_balanced(s, k, "[", "]")
    text = text .. s:sub(j, k - 1) .. opt
    j = after_opt
    k = skip_spaces(s, j)
  end

  local group_count = 0
  while k <= #s and s:sub(k, k) == "{" and group_count < group_limit do
    local group, after_group = capture_balanced(s, k, "{", "}")
    text = text .. s:sub(j, k - 1) .. group
    j = after_group
    k = skip_spaces(s, j)
    group_count = group_count + 1
  end

  return text, j, command
end

local function read_function_argument(s, i)
  local arg_start = skip_spaces(s, i)
  if arg_start > #s then
    return "", i
  end

  local c = s:sub(arg_start, arg_start)
  if c == "=" or c == "+" or c == "-" or c == ")" or c == "]" or c == "," or c == ";" then
    return "", i
  end

  local arg, after_arg = read_atom(s, arg_start)
  return s:sub(i, arg_start - 1) .. arg, after_arg
end

read_atom = function(s, i)
  local c = s:sub(i, i)
  local text
  local next_i

  if c == "\\" then
    local command
    text, next_i, command = read_command_token(s, i)
    text, next_i = read_math_suffixes(s, text, next_i)

    if function_commands[command] then
      local arg, after_arg = read_function_argument(s, next_i)
      if arg ~= "" then
        text = text .. arg
        next_i = after_arg
      end
    end

    return text, next_i
  elseif c == "{" then
    text, next_i = capture_balanced(s, i, "{", "}")
    return read_math_suffixes(s, text, next_i)
  elseif c == "(" then
    text, next_i = capture_balanced(s, i, "(", ")")
    return read_math_suffixes(s, text, next_i)
  elseif c == "[" then
    text, next_i = capture_balanced(s, i, "[", "]")
    return read_math_suffixes(s, text, next_i)
  elseif is_digit(c) then
    text, next_i = read_number_token(s, i)
    return read_math_suffixes(s, text, next_i)
  elseif is_letter(c) then
    -- Variables remain individual atoms, but scripts/primes stay attached.
    return read_math_suffixes(s, c, i + 1)
  else
    return c, i + 1
  end
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
    else
      local text, next_i = read_atom(s, i)
      tokens[#tokens + 1] = { text = text, leading = leading }
      leading = ""
      i = next_i
    end
  end

  return tokens
end

-- ---------------------------------------------------------------------------
-- LCS diffing
-- ---------------------------------------------------------------------------

local function lcs_match_maps(prev, curr)
  local n = #prev
  local m = #curr
  local dp = {}

  for i = 1, n + 1 do
    dp[i] = {}
    for j = 1, m + 1 do
      dp[i][j] = 0
    end
  end

  -- Work from the start when reconstructing a match. With repeated atoms,
  -- this anchors the earliest common prefix and marks a trailing insertion
  -- at the end instead of attributing it to the first occurrence.
  for i = n, 1, -1 do
    for j = m, 1, -1 do
      if prev[i].text == curr[j].text then
        dp[i][j] = dp[i + 1][j + 1] + 1
      else
        dp[i][j] = math.max(dp[i + 1][j], dp[i][j + 1])
      end
    end
  end

  local matched_curr = {}
  local matched_prev = {}
  local pairs = {}
  local i = 1
  local j = 1

  while i <= n and j <= m do
    if prev[i].text == curr[j].text then
      matched_prev[i] = true
      matched_curr[j] = true
      pairs[#pairs + 1] = { prev = i, curr = j }
      i = i + 1
      j = j + 1
    elseif dp[i + 1][j] >= dp[i][j + 1] then
      i = i + 1
    else
      j = j + 1
    end
  end

  return matched_curr, matched_prev, pairs
end

local function lcs_matches(prev, curr)
  local matched_curr = lcs_match_maps(prev, curr)
  return matched_curr
end

-- ---------------------------------------------------------------------------
-- Rendering
-- ---------------------------------------------------------------------------

local weak_tokens = {
  ["+"] = true,
  ["-"] = true,
  ["("] = true,
  [")"] = true,
  ["["] = true,
  ["]"] = true,
  [","] = true,
  [";"] = true
}

local bridge_tokens = {
  ["+"] = true,
  ["-"] = true,
  ["("] = true,
  [")"] = true,
  ["["] = true,
  ["]"] = true
}

local relation_tokens = {
  ["="] = true,
  ["\\le"] = true,
  ["\\ge"] = true,
  ["<"] = true,
  [">"] = true,
  ["\\approx"] = true,
  ["\\sim"] = true,
  ["\\equiv"] = true,
  ["\\Rightarrow"] = true,
  ["\\Longrightarrow"] = true
}

local function is_relation_token(text)
  return relation_tokens[text] == true
end

local function normalize_diff_mode(mode)
  mode = strip_tex_sentinels(mode):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if mode == "false" or mode == "none" then
    return "none"
  elseif mode == "all" then
    return "all"
  end
  return "auto"
end

local function normalize_tag(tag)
  return strip_tex_sentinels(tag or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalize_bool(value)
  value = strip_tex_sentinels(value or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  return value == "true"
end

local function normalize_color_mode(mode)
  mode = strip_tex_sentinels(mode or "single"):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if mode == "typed" or mode == "teaching" then
    return mode
  end
  return "single"
end

local function is_final_step(step)
  return step ~= nil and step.tag == "final"
end

local function find_alignment_relation(tokens)
  for i, token in ipairs(tokens) do
    if is_relation_token(token.text) then
      return i, token.text
    end
  end

  return nil, nil
end

local function should_highlight_token(index, token, matched, alignment_index)
  if matched == nil or matched[index] then
    return false
  end

  -- The first recognized relation is structural: it is used for alignment.
  if alignment_index == index and is_relation_token(token.text) then
    return false
  end

  return true
end

local function wrapper_for_category(category)
  local mode = current_options.color_mode or "single"

  if category == "final" then
    return "\\SDfinal"
  end

  if mode == "single" then
    return "\\SDchanged"
  end

  if category == "operation" and mode == "teaching" then
    return "\\SDoperation"
  elseif category == "operation" then
    return "\\SDadded"
  elseif category == "added" then
    return "\\SDadded"
  elseif category == "modified" then
    return "\\SDmodified"
  elseif category == "moved" then
    return "\\SDmoved"
  end

  return "\\SDchanged"
end

local function append_typed_chunk(out, chunk, category)
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
    local wrapper = wrapper_for_category(category or "modified")
    out[#out + 1] = first.leading .. wrapper .. "{" .. text .. "}"
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

local function render_all_range(tokens, first_index, last_index, category)
  local plain = render_plain_range(tokens, first_index, last_index)
  if plain == "" then
    return plain
  end
  local wrapper = wrapper_for_category(category or "modified")
  return wrapper .. "{" .. plain .. "}"
end

local function side_slice(tokens, first_index, last_index)
  local side = {}
  for i = first_index, last_index do
    side[#side + 1] = { index = i, text = tokens[i].text }
  end
  return side
end

local function token_slice(tokens, first_index, last_index)
  local slice = {}
  for i = first_index, last_index do
    slice[#slice + 1] = tokens[i]
  end
  return slice
end

local function operation_slice(flags, first_index, last_index)
  local slice = {}
  for i = first_index, last_index do
    if flags[i] then
      slice[i - first_index + 1] = true
    end
  end
  return slice
end

local function match_context(prev_tokens, curr_tokens)
  local matched_curr, matched_prev, pairs = lcs_match_maps(prev_tokens, curr_tokens)
  return {
    prev_tokens = prev_tokens,
    matched_curr = matched_curr,
    matched_prev = matched_prev,
    pairs = pairs
  }
end

local function prefix_before_matching_suffix(prev_side, curr_side)
  if #prev_side == 0 or #curr_side <= #prev_side then
    return nil
  end

  local prefix_len = #curr_side - #prev_side
  -- Keep this intentionally conservative for v1.1: only short syntactic prefixes.
  if prefix_len > 3 then
    return nil
  end

  for i = 1, #prev_side do
    if curr_side[prefix_len + i].text ~= prev_side[i].text then
      return nil
    end
  end

  local prefix = {}
  for i = 1, prefix_len do
    prefix[#prefix + 1] = curr_side[i]
  end
  return prefix
end

local function same_prefix_text(a, b)
  if a == nil or b == nil or #a ~= #b then
    return false
  end
  for i = 1, #a do
    if a[i].text ~= b[i].text then
      return false
    end
  end
  return true
end

local function detect_operation_flags(prev_step, step)
  local flags = {}
  if prev_step == nil then
    return flags
  end

  local prev_relation_index, prev_relation = find_alignment_relation(prev_step.tokens)
  local curr_relation_index, curr_relation = find_alignment_relation(step.tokens)
  if
    prev_relation_index == nil
    or curr_relation_index == nil
    or prev_relation ~= curr_relation
  then
    return flags
  end

  local prev_lhs = side_slice(prev_step.tokens, 1, prev_relation_index - 1)
  local prev_rhs = side_slice(prev_step.tokens, prev_relation_index + 1, #prev_step.tokens)
  local curr_lhs = side_slice(step.tokens, 1, curr_relation_index - 1)
  local curr_rhs = side_slice(step.tokens, curr_relation_index + 1, #step.tokens)

  local lhs_prefix = prefix_before_matching_suffix(prev_lhs, curr_lhs)
  local rhs_prefix = prefix_before_matching_suffix(prev_rhs, curr_rhs)

  if not same_prefix_text(lhs_prefix, rhs_prefix) then
    return flags
  end

  for _, token in ipairs(lhs_prefix) do
    flags[token.index] = true
  end
  for _, token in ipairs(rhs_prefix) do
    flags[token.index] = true
  end

  return flags
end

local function changed_run_category(first_index, last_index, match_context)
  if match_context == nil then
    return nil
  end

  local before_prev = 0
  local after_prev = #match_context.prev_tokens + 1

  for _, pair in ipairs(match_context.pairs) do
    if pair.curr < first_index then
      before_prev = pair.prev
    elseif pair.curr > last_index then
      after_prev = pair.prev
      break
    end
  end

  for i = before_prev + 1, after_prev - 1 do
    local token = match_context.prev_tokens[i]
    if token ~= nil and not match_context.matched_prev[i] and not weak_tokens[token.text] then
      return "modified"
    end
  end

  return "added"
end

local function build_category_flags(
  tokens,
  first_index,
  last_index,
  match_context,
  alignment_index,
  operation_flags
)
  local categories = {}
  local matched = match_context and match_context.matched_curr or nil
  local i = first_index

  while i <= last_index do
    local token = tokens[i]
    if should_highlight_token(i, token, matched, alignment_index) then
      local run_first = i
      local run_last = i
      while
        run_last + 1 <= last_index
        and should_highlight_token(run_last + 1, tokens[run_last + 1], matched, alignment_index)
      do
        run_last = run_last + 1
      end

      local category = changed_run_category(run_first, run_last, match_context) or "modified"
      for k = run_first, run_last do
        categories[k] = category
      end
      i = run_last + 1
    else
      i = i + 1
    end
  end

  for index, is_operation in pairs(operation_flags or {}) do
    if is_operation and categories[index] ~= nil then
      categories[index] = "operation"
    end
  end

  -- If weak punctuation/operator tokens sit between changed atoms, include them
  -- in the same visual chunk. This stays textual: it does not infer meaning.
  for index = first_index + 1, last_index - 1 do
    local token = tokens[index]
    if not categories[index] and bridge_tokens[token.text] then
      local left = categories[index - 1]
      local right = categories[index + 1]
      if left ~= nil and right ~= nil then
        if left == right then
          categories[index] = left
        else
          categories[index] = "modified"
        end
      end
    end
  end

  return categories
end

local function render_token_range(
  tokens,
  first_index,
  last_index,
  match_context,
  alignment_index,
  operation_flags
)
  local out = {}
  local chunk = {}
  local chunk_category = nil
  local categories = build_category_flags(
    tokens,
    first_index,
    last_index,
    match_context,
    alignment_index,
    operation_flags
  )

  -- A deletion-only change leaves no unmatched token on the current line.
  -- Emphasize the surviving expression so that the step does not look
  -- identical; the removed material itself is not rendered.
  if match_context ~= nil then
    local visible_change = false
    for i = first_index, last_index do
      if categories[i] ~= nil and not weak_tokens[tokens[i].text] then
        visible_change = true
        break
      end
    end
    if not visible_change then
      for i, token in ipairs(match_context.prev_tokens) do
        if not match_context.matched_prev[i] and not weak_tokens[token.text] then
          return render_all_range(tokens, first_index, last_index, "modified")
        end
      end
    end
  end

  for i = first_index, last_index do
    local token = tokens[i]
    local category = categories[i]

    if category ~= nil then
      if chunk_category ~= nil and category ~= chunk_category then
        append_typed_chunk(out, chunk, chunk_category)
        chunk = {}
      end
      chunk[#chunk + 1] = token
      chunk_category = category
    else
      append_typed_chunk(out, chunk, chunk_category)
      chunk = {}
      chunk_category = nil
      out[#out + 1] = token.leading .. token.text
    end
  end

  append_typed_chunk(out, chunk, chunk_category)
  return table.concat(out)
end

local function render_reason(reason, is_final)
  reason = strip_tex_sentinels(reason)
  if reason == "" then
    return "{}"
  end
  if is_final then
    return "\\SDmaybefinalreason{" .. reason .. "}"
  end
  return "\\SDmaybereason{" .. reason .. "}"
end

local function make_step(math, reason, diff_mode, overlay, tag)
  math = strip_tex_sentinels(math)
  reason = strip_tex_sentinels(reason)
  overlay = strip_tex_sentinels(overlay or "")
  diff_mode = normalize_diff_mode(diff_mode or "auto")

  return {
    math = math,
    reason = reason,
    diff_mode = diff_mode,
    overlay = overlay,
    tag = normalize_tag(tag),
    tokens = tokenize(math)
  }
end

local function select_render_range(diff_mode, all_category)
  if diff_mode == "none" then
    return function(tokens, first_index, last_index)
      return render_plain_range(tokens, first_index, last_index)
    end
  elseif diff_mode == "all" then
    return function(tokens, first_index, last_index)
      return render_all_range(tokens, first_index, last_index, all_category)
    end
  end

  return render_token_range
end

local function render_step_cells(prev_step, step)
  local alignment_index, relation_text = find_alignment_relation(step.tokens)
  local prev_alignment_index, prev_relation_text = nil, nil
  if prev_step ~= nil then
    prev_alignment_index, prev_relation_text = find_alignment_relation(prev_step.tokens)
  end
  local all_category = is_final_step(step) and "final" or "modified"
  local render_range = select_render_range(step.diff_mode, all_category)

  if alignment_index ~= nil then
    local lhs_tokens = token_slice(step.tokens, 1, alignment_index - 1)
    local rhs_tokens = token_slice(step.tokens, alignment_index + 1, #step.tokens)
    local lhs_context, rhs_context = nil, nil
    local operation_flags = {}
    if prev_step ~= nil and step.diff_mode == "auto" then
      local prev_lhs = {}
      local prev_rhs = {}
      if prev_alignment_index ~= nil then
        prev_lhs = token_slice(prev_step.tokens, 1, prev_alignment_index - 1)
        prev_rhs = token_slice(prev_step.tokens, prev_alignment_index + 1, #prev_step.tokens)
      end
      lhs_context = match_context(prev_lhs, lhs_tokens)
      rhs_context = match_context(prev_rhs, rhs_tokens)
      operation_flags = detect_operation_flags(prev_step, step)
    end
    local lhs = render_range(
      lhs_tokens,
      1,
      #lhs_tokens,
      lhs_context,
      nil,
      operation_slice(operation_flags, 1, alignment_index - 1)
    )
    local rhs = render_range(
      rhs_tokens,
      1,
      #rhs_tokens,
      rhs_context,
      nil,
      operation_slice(operation_flags, alignment_index + 1, #step.tokens)
    )
    local relation = relation_text
    if step.diff_mode == "all" then
      local wrapper = wrapper_for_category(all_category)
      relation = wrapper .. "{" .. relation_text .. "}"
    elseif step.diff_mode == "auto" and prev_step ~= nil and relation_text ~= prev_relation_text then
      local category = prev_relation_text == nil and "added" or "modified"
      relation = wrapper_for_category(category) .. "{" .. relation_text .. "}"
    end
    return lhs, relation .. " " .. rhs
  end

  if prev_step ~= nil and step.diff_mode == "auto" and prev_alignment_index ~= nil then
    -- The old relation disappeared. Highlight the current expression rather
    -- than presenting a structural change as an unchanged line.
    return render_all_range(step.tokens, 1, #step.tokens, "modified"), "{}"
  end

  local context = nil
  if prev_step ~= nil and step.diff_mode == "auto" then
    context = match_context(prev_step.tokens, step.tokens)
  end
  return render_range(step.tokens, 1, #step.tokens, context, nil, {}), "{}"
end

local function render_step_body(prev_step, step)
  local left, right = render_step_cells(prev_step, step)
  return left .. " & " .. right
end

local function with_overlay(text, overlay)
  overlay = strip_tex_sentinels(overlay or "")
  if overlay == "" then
    return text
  end
  return "\\onslide<" .. overlay .. ">{" .. text .. "}"
end

local function render_step_row(prev_step, step)
  local left, right = render_step_cells(prev_step, step)
  local final = is_final_step(step)
  local reason = render_reason(step.reason, final)
  local overlay = step.overlay or ""

  if final then
    left = "\\SDfinalmath{" .. left .. "}"
    right = "\\SDfinalmath{" .. right .. "}"
  end

  return with_overlay(left, overlay)
    .. " & " .. with_overlay(right, overlay)
    .. " && " .. with_overlay(reason, overlay)
end

local function render_latex(step_list)
  local rows = {}

  rows[#rows + 1] = "\\begin{aligned}"

  for i, step in ipairs(step_list) do
    rows[#rows + 1] = render_step_row(step_list[i - 1], step)

    if i < #step_list then
      if is_final_step(step_list[i + 1]) then
        rows[#rows + 1] = "\\\\[\\SDfinalbeforeskip]"
      else
        rows[#rows + 1] = "\\\\"
      end
    end
  end

  rows[#rows + 1] = "\\end{aligned}"

  local latex = table.concat(rows, " ")
  if current_options.legend and current_options.color_mode ~= "single" then
    latex = "\\begin{gathered}\\SDlegend\\\\[2pt]" .. latex .. "\\end{gathered}"
  end

  if current_options.frame then
    latex = "\\SDframed{" .. latex .. "}"
  end

  return strip_tex_sentinels(latex)
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function M.begin(frame, color_mode, legend)
  steps = {}
  current_options = {
    frame = normalize_bool(frame),
    color_mode = normalize_color_mode(color_mode),
    legend = normalize_bool(legend)
  }
end

function M.add(math, reason, diff_mode, overlay, tag)
  steps[#steps + 1] = make_step(math, reason, diff_mode, overlay, tag)
end

function M.render()
  local latex = render_latex(steps)
  tex.sprint(latex)
  return latex
end

M._test = {
  strip_tex_sentinels = strip_tex_sentinels,
  tokenize = tokenize,
  lcs_matches = lcs_matches,
  lcs_match_maps = lcs_match_maps,
  normalize_diff_mode = normalize_diff_mode,
  normalize_tag = normalize_tag,
  normalize_color_mode = normalize_color_mode,
  is_relation_token = is_relation_token,
  find_alignment_relation = find_alignment_relation,
  detect_operation_flags = detect_operation_flags,
  make_step = make_step,
  render_step_cells = render_step_cells,
  render_step_body = render_step_body,
  with_overlay = with_overlay,
  render_step_row = render_step_row,
  render_latex = render_latex,
  render_pair = function(prev_math, curr_math, diff_mode)
    local prev_step = nil
    if prev_math ~= nil then
      prev_step = make_step(prev_math, "", "auto")
    end

    local step = make_step(curr_math, "", diff_mode or "auto")
    return render_step_body(prev_step, step)
  end,
  render_pair_color = function(prev_math, curr_math, diff_mode, color_mode)
    local previous_options = current_options
    current_options = {
      frame = false,
      color_mode = normalize_color_mode(color_mode),
      legend = false
    }

    local prev_step = nil
    if prev_math ~= nil then
      prev_step = make_step(prev_math, "", "auto")
    end

    local step = make_step(curr_math, "", diff_mode or "auto")
    local out = render_step_body(prev_step, step)
    current_options = previous_options
    return out
  end,
  render_overlay_pair = function(prev_math, curr_math, overlay)
    local prev_step = nil
    if prev_math ~= nil then
      prev_step = make_step(prev_math, "", "auto")
    end

    local step = make_step(curr_math, "shown", "auto", overlay)
    return render_step_row(prev_step, step)
  end
}

return M
