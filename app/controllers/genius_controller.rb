class GeniusController < ApplicationController
  def index
    if params[:query].present?
      @songs = 'hello'
    end
  end
end
