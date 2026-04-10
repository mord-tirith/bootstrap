local M = {}

local state_file = vim.fn.stdpath("state") .. "/tutorial_mode"

M.enabled = true

function M.load()
	local f = io.open(state_file, "r")
	if f then
		local content = f:read("*a")
		f:close()
		M.enabled = content == "1"
	end
end

function M.save()
	local f = io.open(state_file, "w")
	if f then
		f:write(M.enabled and "1" or "0")
		f:close()
	end
end

function M.toggle()
	M.enabled = not M.enabled
	M.save()
	return M.enabled
end

return M
