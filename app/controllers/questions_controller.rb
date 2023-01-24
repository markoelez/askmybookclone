require 'csv'
require "ruby/openai"
require 'matrix'
require 'question_service.rb'

$question_service = QuestionService.new

class QuestionsController < ApplicationController
    skip_before_action :verify_authenticity_token

    def ask
        @question = params[:question]

        # Verify question isn't empty.
        if @question.nil?
            return head 500
        end

        # Prepare question text. Use canonical form to inrease probability of cache hit.
        @question = @question.strip
        @question = @question.downcase

        # Ensure input is phrased as a question.
        if !@question.end_with?("?")
            @question << "?"
        end

        # Check cache for existing answer.
        @existing_record = Question.find_by(question: @question)
        if @existing_record
            render json: @existing_record and return
        end

        # Otherwise pose a new question.
        @answer, @context = $question_service.answer_query_with_context(@question)

        # Cache this answer.
        @new_record = Question.create(
            question: @question,
            context: @context,
            answer: @answer,
        )

        # Ensure this answer was persisted in the cache.
        if @new_record.persisted? == false
            return head 500
        end

        render json: @new_record
    end
end
