# frozen_string_literal: true

Rails.application.routes.draw do
  resources :trashed_issues, only: :show
end
