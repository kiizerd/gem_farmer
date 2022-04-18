PATH = 'lib/user_interface/'

# UI module - Constants for unified and consistent UI
require "#{PATH}ui.rb"

# Message API
# Used to display temporary informative and contextual messages
require "#{PATH}message.rb"

# Confirmation API
# Displays a question to the user and returns -1, 0, 1 based on input
require "#{PATH}confirmation.rb"

# ContextMenu API
# Displays a contextual list of options, disappears when clicked away from
require "#{PATH}context_menu.rb"

# Toolbar component
# Display buttons and useful info at the top of the game screen.
require "#{PATH}toolbar.rb"

# Panel component
# Displays information in a consistent manner
require "#{PATH}panel.rb"
require "#{PATH}panels/require.rb"

# ActionBar component
# Displays the items in the players active row of their inventory
# Also whichever item is currently being held
require "#{PATH}action_bar.rb"
