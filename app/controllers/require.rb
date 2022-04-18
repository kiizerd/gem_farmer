PATH = 'app/controllers/'

# UI controller - Contains Message and Confirmation APIs
require "#{PATH}ui_controller.rb"

# Item controller - Manages items and item types
require "#{PATH}item_controller.rb"

# Scene controller - Handles sending render object to camera
require "#{PATH}scene_controller.rb"

# Interaction controller - Handles and listens for interactions
require "#{PATH}interaction_controller.rb"

# Game controller - Manages general game state
require "#{PATH}game_controller.rb"

# Controller module - Methods to control controllers
require "#{PATH}controllers.rb"