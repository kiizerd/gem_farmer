module Takara
  module Controllers
    def Controllers.init
      {
        ui:    UIController.new,
        item:  ItemController.new,
        game:  GameController.new,
        scene: SceneController.new,
        interaction: InteractionController.new
      }
    end
  end
end