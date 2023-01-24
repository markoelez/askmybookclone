import React, { useState, useEffect } from 'react'
import axios from 'axios'

const Home = ({}) => {
  // Static data
  const defaultQuestion = 'What is The Minimalist Entrepreneur about?'
  const feelingLuckyOptions = [
    'What is a minimalist entrepreneur?',
    'What is your definition of community?',
    'How do I decide what kind of business I should start?',
    'What made you decide to write this book?',
  ]

  // Stateful data
  const [question, setQuestion] = useState(defaultQuestion)
  const [answerDisplay, setAnswerDisplay] = useState(null)
  const [answer, setAnswer] = useState(null)

  // State machine
  const [waitingForQuestion, setWaitingForQuestion] = useState(true)
  const [questionSubmitted, setQuestionSubmitted] = useState(false)
  const [answerAnimating, setAnswerAnimating] = useState(false)
  const [answerLoaded, setAnswerLoaded] = useState(false)

  // State machine transitions
  useEffect(() => {
    if (waitingForQuestion) {
      setQuestionSubmitted(false)
      setAnswerAnimating(false)
      setAnswerLoaded(false)

      setAnswer('')
    }
  }, [waitingForQuestion])

  useEffect(() => {
    if (questionSubmitted) {
      setWaitingForQuestion(false)
      setAnswerAnimating(false)
      setAnswerLoaded(false)

      getAnswer(question)
        .then((answer) => {
          setAnswer(answer)
          setAnswerAnimating(true)
        })
        .catch((error) => {
          alert(error)
          setWaitingForQuestion(true)
        })
    }
  }, [questionSubmitted])

  useEffect(() => {
    if (answerAnimating) {
      setWaitingForQuestion(false)
      setQuestionSubmitted(false)
      setAnswerLoaded(false)

      const animateShowAnswer = (str, idx = 0, callback) => {
        if (idx > str.length) {
          callback()
          return
        }

        setAnswerDisplay(str.slice(0, idx++))

        setTimeout(() => {
          animateShowAnswer(str, idx, callback)
        }, randInt(30, 70))
      }

      animateShowAnswer(answer, 0, () => {
        setAnswerLoaded(true)
      })
    }
  }, [answerAnimating])

  // Handle button clicks
  const handleLuckyButtonClicked = (event) => {
    event.preventDefault()
    idx = randInt(0, feelingLuckyOptions.length - 1)
    const randomQuestion = feelingLuckyOptions[idx]
    setQuestion(randomQuestion)
    setQuestionSubmitted(true)
  }

  const handleAskAnotherClicked = (event) => {
    event.preventDefault()
    setWaitingForQuestion(true)
  }

  const handleSubmit = (event) => {
    event.preventDefault()

    if (!/\S/.test(question)) {
      alert('Invalid question provided!')
      return
    }

    setQuestion(question.trim())

    setQuestionSubmitted(true)
  }

  // Utilities
  const randInt = (min, max) => {
    return Math.floor(Math.random() * (max - min + 1)) + min
  }

  const getAnswer = async (question) => {
    if (!/\S/.test(question)) {
      throw 'Invalid question provided!'
    }

    try {
      const response = await axios.post('/questions', {
        question: question,
      })
      return response.data.answer
    } catch (error) {
      return await Promise.reject(error)
    }
  }

  return (
    <div className='vw-100 vh-100 body'>
      <div className='header'>
        <div className='logo'>
          <a href='https://www.amazon.com/Minimalist-Entrepreneur-Great-Founders-More/dp/0593192397'>
            <img src='https://askmybook.com/static/book.2a513df7cb86.png' />
          </a>
          <h1>Ask My Book</h1>
        </div>
      </div>
      <div className='main'>
        <p className='credits'>
          This is an experiment in using AI to make my book's content more
          accessible. Ask a question and AI'll answer it in real-time:
        </p>
        <form onSubmit={handleSubmit}>
          <textarea
            disabled={!waitingForQuestion}
            name='question'
            id='question'
            value={question}
            onChange={(e) => setQuestion(e.target.value)}
          />
          {(waitingForQuestion || questionSubmitted) && (
            <div className='buttons' disabled={!waitingForQuestion}>
              <button type='submit' id='ask-button'>
                {questionSubmitted ? 'Asking question...' : 'Ask question'}
              </button>
              <button
                id='lucky-button'
                className='button-secondary'
                data=''
                onClick={handleLuckyButtonClicked}
                disabled={!waitingForQuestion}
              >
                I'm feeling lucky
              </button>
            </div>
          )}
        </form>
        {answerAnimating && (
          <p className='answer'>
            <strong>Answer:</strong>
            <span id='answer'>{answerDisplay}</span>
            {answerLoaded && (
              <button id='ask-another-button' onClick={handleAskAnotherClicked}>
                Ask another question
              </button>
            )}
          </p>
        )}
      </div>
      <footer>
        <p className='credits'>
          Project by <a href='https://twitter.com/shl'>Sahil Lavingia</a> •{' '}
          <a href='https://github.com/slavingia/askmybook'>Fork on GitHub</a>
        </p>
      </footer>
    </div>
  )
}

export default Home
