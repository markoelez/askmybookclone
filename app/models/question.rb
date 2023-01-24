class Question < ApplicationRecord
    validates :question, uniqueness: true
end
