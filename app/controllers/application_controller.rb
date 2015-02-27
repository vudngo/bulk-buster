class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  UPLOAD_DIRECTORY = 'public/uploads'
  protect_from_forgery with: :exception
end
