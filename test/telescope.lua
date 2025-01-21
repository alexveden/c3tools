local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")
local telescope = require("telescope")
local themes = require("telescope.themes")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local putils = require("telescope.previewers.utils")
local make_entry = require("telescope.make_entry")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local c3fzf = function(opts)
	local tbl_clone = function(original)
		local copy = {}
		for key, value in pairs(original) do
			copy[key] = value
		end
		return copy
	end

	local setup_opts = {
		auto_quoting = true,
		mappings = {},
	}

	local c3previewer = function(opts)
		return previewers.new_buffer_previewer({
			title = "C3 module preview",
			get_buffer_by_name = function(_, entry)
				return entry.value
			end,

			define_preview = function(self, entry)
				-- print(vim.inspect(entry))

				local words = {}
				local arg_cnt = 0
				for word in entry.value:gmatch("[%w%d_%p]+") do
					table.insert(words, word)
					arg_cnt = arg_cnt + 1
					if arg_cnt == 2 then
						break
					end
				end
				if arg_cnt == 0 then
					return nil
				end

				local cmd = vim.tbl_flatten({
					"/home/ubertrader/code/c3test/build/c3fzf",
					"--preview",
					words,
				})

				putils.job_maker(cmd, self.state.bufnr, {
					value = entry.value,
					bufname = self.state.bufname,
					cwd = opts.cwd,
					callback = function(bufnr, content)
						if not content then
							return
						end
						-- print(content)
						require("telescope.previewers.utils").highlighter(bufnr, "c3")
					end,
				})
			end,
		})
	end

	local c3fzf_sorter = function(opts)
		opts = opts or {}
		local fzy = opts.fzy_mod or require("telescope.algos.fzy")

		local fzy_sorter = sorters.get_generic_fuzzy_sorter(opts)

		return sorters.Sorter:new({
			scoring_function = function(_, prompt, line, _)
				local words = {}
				for word in prompt:gmatch("[%w%d_%p]+") do
					table.insert(words, word)
				end
				if #words > 2 then
					-- print(words[#words])
					return fzy_sorter.scoring_function(nil, words[#words], line, nil)
				else
					return 1
				end
			end,

			highlighter = function(_, prompt, display)
				return fzy.positions(prompt, display)
			end,
		})
	end
	opts = vim.tbl_extend("force", setup_opts, opts or {})

	opts.vimgrep_arguments = opts.vimgrep_arguments or conf.vimgrep_arguments
	-- opts.entry_maker = opts.entry_maker or make_entry.gen_from_vimgrep(opts)
	opts.cwd = opts.cwd and vim.fn.expand(opts.cwd)

	local cmd_generator = function(prompt)
		if not prompt or prompt == "" then
			prompt = "."
		end

		local words = {}
		for word in prompt:gmatch("[%w%d_%p]+") do
			table.insert(words, word)
		end

		-- print(vim.inspect(words))

		local cmd = vim.tbl_flatten({
			"/home/ubertrader/code/c3test/build/c3fzf",
			words,
		})
		return cmd
	end

	local picker = pickers.new(opts, {
		prompt_title = "c3fzf [.|module_name] [.|symbol name] fuzzy_query",
		finder = finders.new_job(cmd_generator, opts.entry_maker, opts.max_results, opts.cwd),
		previewer = c3previewer(opts),
		sorter = c3fzf_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			for mode, mappings in pairs(opts.mappings) do
				for key, action in pairs(mappings) do
					map(mode, key, action)
				end
			end
			actions.select_default:replace(function()
				local current_picker = action_state.get_current_picker(prompt_bufnr) -- picker state
				local selection = action_state.get_selected_entry()

				local sel_prompt = selection[1]
				if not sel_prompt:find(" ") then
					sel_prompt = sel_prompt .. " ."
				end
				current_picker:reset_prompt(sel_prompt)
			end)
			return true
		end,
	})

	picker:find()
end

c3fzf()
