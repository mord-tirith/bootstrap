return {
	"Diogo-ss/42-header.nvim",
	cmd = { "Stdheader" },
	keys = { "<F1>" },
	opts = {
		default_map = true,
		auto_update = true,
		user = "YOUR_LOGIN",
		mail = "YOUR_EMAIL",
	},
	config = function(_, opts)
		require("42header").setup(opts)
	end,
}
