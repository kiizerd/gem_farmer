APP = 'app/'
LIB = 'lib/'

require "#{LIB}constants.rb"

# Top level Takara module - Contains toolbox methods for GTK
require "#{LIB}takara.rb" 

# Geometric shape modules - Only contains Takara::Rect for now
require "#{LIB}shapes/require.rb"

# Extensions to Ruby Numeric class - required by Perlin module
require "#{LIB}numeric.rb"

# Perlin Noise Module
require "#{LIB}perlin/require.rb"

# Game World Module - Encapsulates virtual planes of existence
require "#{LIB}world/require.rb"

# Render Scenes - Contains a list of renderable objects to display
require "#{LIB}scene/require.rb"

# UI Module - Creates and maintains the user interface
require "#{LIB}user_interface/require.rb"

# Action module - Turns data from user interaction into an effect on the world.
require "#{LIB}action.rb"

# Logic Controllers - Each class controls a library module
require "#{APP}controllers/require.rb"

# Container class - Contains items
require "#{LIB}container.rb"

# Player Class - Handles inputs and maintains data specific to player.
require "#{LIB}player.rb"

# Camera Class - Handles the viewport and what will be rendered. Currently inside Views module.
require "#{LIB}camera.rb"

# Game definition
require "#{APP}game.rb"

# Contains GTK#tick method
require "#{APP}tick.rb"
