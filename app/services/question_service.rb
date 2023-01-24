require 'csv'
require "ruby/openai"
require 'matrix'

COMPLETIONS_MODEL = "text-davinci-003"
MODEL_NAME = "curie"

DOC_EMBEDDINGS_MODEL = "text-search-#{MODEL_NAME}-doc-001"
QUERY_EMBEDDINGS_MODEL = "text-search-#{MODEL_NAME}-query-001"

MAX_SECTION_LEN = 500
SEPARATOR = "\n* "

PREFIX = "book"

CONTEXT_PATH = "#{Rails.root}/app/assets/data/#{PREFIX}.pdf.pages.csv"
EMBEDDINGS_PATH = "#{Rails.root}/app/assets/data/#{PREFIX}.pdf.embeddings.csv"

class QuestionService

    def initialize()
        raise 'Missing OpenAI API key' unless openai_access_key = ENV['OPENAI_API_KEY']

        # Setup our OpenAI API client.
        @openai_client = OpenAI::Client.new(access_token: openai_access_key)

        # Parse our static context and embeddings.
        @context = self.parse_context_csv(CONTEXT_PATH)
        @embeddings = self.parse_embeddings_csv(EMBEDDINGS_PATH)
    end

    # Anwers a given query using a prompt constructed from relevent context fed into an OpenAI text completion model.
    def answer_query_with_context(query)
        
        prompt, relevent_context = self.construct_prompt(query)
      
        response = @openai_client.completions(
            parameters: {
                model: COMPLETIONS_MODEL,
                prompt: prompt,
                max_tokens: 150,
                temperature: 0,
            }
        )
        
        return response['choices'][0]['text'], relevent_context
    end

    private

    # Constructs a prompt used to retrieve text completions for a given query.
    def construct_prompt(question)
        preamble = "Sahil Lavingia is the founder and CEO of Gumroad, and the author of the book The Minimalist Entrepreneur (also known as TME). These are questions and answers by him. Please keep your answers to three sentences maximum, and speak in complete sentences. Stop speaking once your point is made.\n\nContext that may be useful, pulled from The Minimalist Entrepreneur:\n"
    
        relevent_context = self.get_relevent_context(question)
        preamble << relevent_context
    
        preamble << "\n\n\nQ: How to choose what business to start?\n\nA: First off don't be in a rush. Look around you, see what problems you or other people are facing, and solve one of these problems if you see some overlap with your passions or skills. Or, even if you don't see an overlap, imagine how you would solve that problem anyway. Start super, super small."
        preamble << "\n\n\nQ: Q: Should we start the business on the side first or should we put full effort right from the start?\n\nA:   Always on the side. Things start small and get bigger from there, and I don't know if I would ever “fully” commit to something unless I had some semblance of customer traction. Like with this product I'm working on now!"
        preamble << "\n\n\nQ: Should we sell first than build or the other way around?\n\nA: I would recommend building first. Building will teach you a lot, and too many people use “sales” as an excuse to never learn essential skills like building. You can't sell a house you can't build!"
        preamble << "\n\n\nQ: Andrew Chen has a book on this so maybe touché, but how should founders think about the cold start problem? Businesses are hard to start, and even harder to sustain but the latter is somewhat defined and structured, whereas the former is the vast unknown. Not sure if it's worthy, but this is something I have personally struggled with\n\nA: Hey, this is about my book, not his! I would solve the problem from a single player perspective first. For example, Gumroad is useful to a creator looking to sell something even if no one is currently using the platform. Usage helps, but it's not necessary."
        preamble << "\n\n\nQ: What is one business that you think is ripe for a minimalist Entrepreneur innovation that isn't currently being pursued by your community?\n\nA: I would move to a place outside of a big city and watch how broken, slow, and non-automated most things are. And of course the big categories like housing, transportation, toys, healthcare, supply chain, food, and more, are constantly being upturned. Go to an industry conference and it's all they talk about! Any industry…"
        preamble << "\n\n\nQ: How can you tell if your pricing is right? If you are leaving money on the table\n\nA: I would work backwards from the kind of success you want, how many customers you think you can reasonably get to within a few years, and then reverse engineer how much it should be priced to make that work."
        preamble << "\n\n\nQ: Why is the name of your book 'the minimalist entrepreneur' \n\nA: I think more people should start businesses, and was hoping that making it feel more “minimal” would make it feel more achievable and lead more people to starting-the hardest step."
        preamble << "\n\n\nQ: How long it takes to write TME\n\nA: About 500 hours over the course of a year or two, including book proposal and outline."
        preamble << "\n\n\nQ: What is the best way to distribute surveys to test my product idea\n\nA: I use Google Forms and my email list / Twitter account. Works great and is 100% free."
        preamble << "\n\n\nQ: How do you know, when to quit\n\nA: When I'm bored, no longer learning, not earning enough, getting physically unhealthy, etc… loads of reasons. I think the default should be to “quit” and work on something new. Few things are worth holding your attention for a long period of time."
      
        return preamble + "\n\n\nQ: " + question + "\n\nA: ", relevent_context
    end

    # Retrieves relevent sections from our static context given a target query.
    def get_relevent_context(query)
        query_embeddings = self.get_query_embeddings(query)
        
        vector_similarities = {}

        @embeddings.each do |key, dat|
            vector_similarities[key] = self.vector_similarity(dat, query_embeddings)
        end

        vector_similarities = vector_similarities.sort_by{|k , v| v}.reverse.to_h

        space_left = MAX_SECTION_LEN

        res = ""

        vector_similarities.each do |key, _|
            ctx = @context[key]
            tokens = ctx.split.size

            res << SEPARATOR

            if space_left - tokens - SEPARATOR.size < 0
                # take partial
                res << ctx[..space_left]
                break
            else
                # take all
                res << ctx
                space_left -= tokens
            end
        end

        return res
    end

    # Retrieves word embeddings from OpenAI.
    def get_query_embeddings(text)
        response = @openai_client.embeddings(
            parameters: {
                model: QUERY_EMBEDDINGS_MODEL,
                input: text
            }
        )
        return response['data'][0]['embedding']
    end

    # Compute similarity between two arrays containing word embeddings.
    def vector_similarity(x, y)
        vect_x = Vector.elements(x, true)
        vect_y = Vector.elements(y, true)
        return vect_x.inner_product(vect_y)
    end
    
    # Parse CSV containing text completion context by page.
    def parse_context_csv(path)
        context_by_page = {}
        rows = CSV.read(path)
        rows[1..].each_with_index do |row, i|
            context_by_page[row[0]] = row[1]
        end
        return context_by_page 
    end
      
    # Parse CSV containing word embeddings by page.
    def parse_embeddings_csv(path)
        embeddings_by_page = {}
        rows = CSV.read(path)
        rows[1..].each_with_index do |row, i|
            embeddings_by_page[row[0]] = row[1..].map(&:to_f)
        end
        return embeddings_by_page
    end
end