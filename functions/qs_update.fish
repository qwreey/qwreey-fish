# Moves qwreey-fish to the latest main, whose qs_setup then applies its own
# (newer) pins. A pinned or path install of qwreey-fish is replaced by the
# unpinned one - to move to a reviewed commit instead, run that commit's
# qs_setup with --self qwreey/qwreey-fish@<commit> (see README).
function qs_update
	# Loads qs_setup.fish, which defines _qs_fisher_pin_self.
	functions --query qs_setup
	if contains -- qwreey/qwreey-fish $_fisher_plugins
		fisher update qwreey/qwreey-fish
	else
		_qs_fisher_pin_self qwreey/qwreey-fish
	end
	and qs_setup $argv
end
