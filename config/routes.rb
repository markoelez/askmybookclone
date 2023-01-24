Rails.application.routes.draw do
  post '/questions' => 'questions#ask'
  root 'homepage#index'
end