local M = {}

local state_file = vim.fn.stdpath("state") .. "/config_state.lua"

M.defaults = {
	tutorial_enabled = true,

	header_user = "YOUR_LOGIN",
	header_mail = "YOUR_EMAIL",

	diag_inline_all = true,
	diag_inline_warnings = true,

	number = true,
	relativenumber = true,
	wrap = false,
	hlsearch = true,
}

M.values = vim.deepcopy(M.defaults)

local function lua_escape(str)
	return tostring(str):gsub("\\", "\\\\"):gsub('"', '\\"')
end

local function serialize_value(v)
	if type(v) == "string" then
		return string.format('"%s"', lua_escape(v))
	elseif type(v) == "boolean" then
		return v and "true" or "false"
	elseif type(v) == "number" then
		return tostring(v)
	else
		return "nil"
	end
end

local function apply_header()
	vim.g.user = M.values.header_user
	vim.g.mail = M.values.header_mail
end

local function apply_diagnostics()
	if not M.values.diag_inline_all then
		vim.diagnostic.config({
			virtual_text = false,
		})
		return
	end

	if M.values.diag_inline_warnings then
		vim.diagnostic.config({
			virtual_text = true,
		})
	else
		vim.diagnostic.config({
			virtual_text = {
				severity = { min = vim.diagnostic.severity.ERROR },
			},
		})
	end
end

local function apply_editor_options()
	vim.wo.number = M.values.number
	vim.wo.relativenumber = M.values.relativenumber
	vim.wo.wrap = M.values.wrap
	vim.o.hlsearch = M.values.hlsearch
end

function M.apply()
	apply_header()
	apply_diagnostics()
	apply_editor_options()
end

function M.load()
	local ok, data = pcall(dofile, state_file)

	if ok and type(data) == "table" then
		for k, default in pairs(M.defaults) do
			if data[k] ~= nil and type(data[k]) == type(default) then
				M.values[k] = data[k]
			end
		end
	end

	M.apply()
end

function M.save()
	local file = io.open(state_file, "w")
	if not file then
		vim.notify("Failed to save config state", vim.log.levels.ERROR)
		return false
	end

	file:write("return {\n")
	for k, _ in pairs(M.defaults) do
		file:write(string.format("\t%s = %s,\n", k, serialize_value(M.values[k])))
	end
	file:write("}\n")
	file:close()

	return true
end

function M.reset()
	M.values = vim.deepcopy(M.defaults)
	M.apply()
	M.save()
end

function M.toggle(key)
	if type(M.values[key]) ~= "boolean" then
		vim.notify("Cannot toggle non-boolean state: " .. tostring(key), vim.log.levels.ERROR)
		return nil
	end

	M.values[key] = not M.values[key]
	M.apply()
	M.save()
	return M.values[key]
end

function M.set(key, value)
	if M.values[key] == nil then
		vim.notify("Unknown config key: " .. tostring(key), vim.log.levels.ERROR)
		return false
	end

	M.values[key] = value
	M.apply()
	M.save()
	return true
end

function M.set_header(user, mail)
	if type(user) == "string" and user ~= "" then
		M.values.header_user = user
	end
	if type(mail) == "string" and mail ~= "" then
		M.values.header_mail = mail
	end

	M.apply()
	M.save()
	return true
end

function M.prompt_header()
	vim.ui.input({ prompt = "42 username: ", default = M.values.header_user }, function(user)
		if not user or user == "" then
			return
		end

		vim.ui.input({ prompt = "42 email: ", default = M.values.header_mail }, function(mail)
			if not mail or mail == "" then
				return
			end

			M.set_header(user, mail)
			vim.notify(
				string.format("Saved header identity: %s <%s>", M.values.header_user, M.values.header_mail),
				vim.log.levels.INFO
			)
		end)
	end)
end

return M
