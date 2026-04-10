local M = {}

local state_file = vim.fn.stdpath("state") .. "/header_state.lua"

M.user = "YOUR_LOGIN"
M.mail = "YOUR_EMAIL"

local function lua_escape(str)
	return str:gsub("\\", "\\\\"):gsub('"', '\\"')
end

local function apply()
	vim.g.user = M.user
	vim.g.mail = M.mail
end

function M.load()
	local ok, data = pcall(dofile, state_file)

	if ok and type(data) == "table" then
		if type(data.user) == "string" and data.user ~= "" then
			M.user = data.user
		end
		if type(data.mail) == "string" and data.mail ~= "" then
			M.mail = data.mail
		end
	end

	apply()
end

function M.save()
	local file = io.open(state_file, "w")
	if not file then
		vim.notify("Failed to save header state", vim.log.levels.ERROR)
		return false
	end

	file:write("return {\n")
	file:write(string.format('\tuser = "%s",\n', lua_escape(M.user)))
	file:write(string.format('\tmail = "%s",\n', lua_escape(M.mail)))
	file:write("}\n")
	file:close()

	apply()
	return true
end

function M.set(user, mail)
	if type(user) == "string" and user ~= "" then
		M.user = user
	end
	if type(mail) == "string" and mail ~= "" then
		M.mail = mail
	end
	apply()
end

function M.prompt_and_save()
	vim.ui.input({ prompt = "42 username: ", default = M.user }, function(user)
		if not user or user == "" then
			return
		end

		vim.ui.input({ prompt = "42 email: ", default = M.mail }, function(mail)
			if not mail or mail == "" then
				return
			end

			M.set(user, mail)

			if M.save() then
				vim.notify(
					string.format("Saved header identity: %s <%s>", M.user, M.mail),
					vim.log.levels.INFO
				)
			end
		end)
	end)
end

return M
