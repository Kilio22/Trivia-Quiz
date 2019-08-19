module QuizzPage exposing (view, update, init, Model, Msg)

import ElmEscapeHtml exposing (unescape)
import Html exposing (..)
import Html.Attributes exposing (..)
import Bootstrap.CDN exposing (stylesheet)
import Html.Events exposing (..)
import Http exposing (expectJson)
import Json.Decode as Decode exposing (Decoder, Value)
import Maybe exposing (Maybe(..))
import Random exposing (Generator)
import Random.List
import Random.Extra

type alias Question =
    {
    label: String
    , correctAnswer: String
    , incorrectAnswers: List String
    , shuffledAnswers: Maybe (List String)
    }

type alias Model =
    {
    game : Game
    , difficulty : String
    }

type Game =
    Loading
    | Loaded GameState
    | Result (List AnsweredQuestions)
    | OnError String

type alias GameState =
    {
    currentQuestion : Question
    , remainingQuestions : List Question
    , answers : List AnsweredQuestions
    }

type alias AnsweredQuestions =
    {
    question : Question
    , answer : String
    }

type Msg =
    Answer String
    | AnswerShuffled (List Question)
    | QuestionReceived (Result Http.Error (List Question))

initialModel : String -> Model
initialModel difficulty =
        {
        game = Loading
        , difficulty = difficulty
        }

init : String -> (Model, Cmd Msg)
init arg =
        (initialModel arg, getQuestion arg)

getQuestion : String -> Cmd Msg
getQuestion arg =
    Http.get
    {
    url = "https://opentdb.com/api.php?amount=5&difficulty=" ++ arg ++ "&type=multiple"
    , expect = expectJson QuestionReceived questionsDecoder --- Ce qui est reçu est envoyé au decoder, le resultat retourné par le decoder (donc le resultat décodé) vas être mis dans QuestionReceived ---
    }

questionsDecoder : Decoder (List Question)
questionsDecoder =
    Decode.list questionDecoder
        |> Decode.field "results"

questionDecoder : Decoder Question
questionDecoder =
    Decode.map4 Question --- On met les 4 champs voulut dans la Question ---
        (Decode.field "question" Decode.string)
        (Decode.field "correct_answer" Decode.string)
        (Decode.field "incorrect_answers" (Decode.list Decode.string))
        (Decode.succeed Nothing)
            |> Decode.map unescapeQuestion --- On unescape les valeurs reçues pour enlever les caractères avec le mauvais encoding ---

unescapeQuestion : Question -> Question
unescapeQuestion question =
    {
    question | label = unescape question.label
    , correctAnswer = unescape question.correctAnswer
    , incorrectAnswers = List.map unescape question.incorrectAnswers
    }

shuffleAnswers : Question -> Generator Question
shuffleAnswers question =
    Random.List.shuffle (question.correctAnswer :: question.incorrectAnswers)
    |> Random.map (\answers -> {question | shuffledAnswers = Just answers})

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Answer answer ->
            case model.game of
                Loaded gameState ->
                    let
                        newGame =
                            answerQuestion gameState answer
                    in
                        ({model | game = newGame}, Cmd.none)
                _ ->
                    (model, Cmd.none)
        AnswerShuffled questions ->
            case questions of
                currentQuestion :: remainingQuestions ->
                    let
                        gameState = GameState currentQuestion remainingQuestions []
                    in
                        ({model | game = Loaded gameState}, Cmd.none)
                [] ->
                    ({model | game = OnError "Error"}, Cmd.none)
        QuestionReceived (Ok questions) ->
            let
                shuffleAnswersCmd =
                    List.map shuffleAnswers questions
                        |> Random.Extra.combine
                        |> Random.generate AnswerShuffled
            in
                (model, shuffleAnswersCmd)
        QuestionReceived (Err _) ->
            ({model | game = OnError "Http Error"}, Cmd.none)

answerQuestion : GameState -> String -> Game
answerQuestion oldState answer =
    let
        answeredQuestion =
            AnsweredQuestions oldState.currentQuestion answer
        answeredQuestions =
            oldState.answers ++ [answeredQuestion]
    in
        case oldState.remainingQuestions of
            first :: remainingQuestions ->
                GameState first remainingQuestions answeredQuestions |> Loaded
            [] ->
                Result answeredQuestions

view : Model -> Html Msg
view model =
    div [ class "text-center", style "position" "absolute", style "top" "40%", style "left" "50%", style "transform" "translate(-50%, -50%)" ]
        [ stylesheet
        , case model.game of
            Loading ->
                text "Loading Questions..."
            OnError string ->
                div [class "text-danger"]
                [text ("An error occured: " ++ string)]
            Loaded gameState ->
                    viewQuestion gameState.currentQuestion
            Result answersList ->
                mainResultsView model answersList
        ]

mainResultsView : Model -> List AnsweredQuestions -> Html Msg
mainResultsView model list =
        div [] [
            viewResults list
            , a [class "btn btn-primary mr-2", href ("/quiz?q=" ++ model.difficulty)] [ text "Replay" ]
            , a [class "btn btn-primary mr-2", href "/home"] [ text "Home" ]
        ]

viewResults : List AnsweredQuestions -> Html Msg
viewResults answersList =
        List.map viewResult answersList
            |> div []

viewResult : AnsweredQuestions -> Html Msg
viewResult { question, answer } =
    if question.correctAnswer == answer then
        div [class "text-success"]
            [text (question.label ++ " " ++ answer)]
    else
        div [class "text-danger"]
            [text (question.label ++ " " ++ question.correctAnswer ++ " Your answer was: " ++ answer)]

viewQuestion : Question -> Html Msg
viewQuestion question =
    div []
        [ h1 [class "my-5"] [text question.label]
        , case question.shuffledAnswers of
            Nothing ->
                text "Shuffuling answers..."
            Just answers ->
                viewAnswers answers
        ]

viewAnswers : List String -> Html Msg
viewAnswers answers =
    List.map viewAnswer answers
        |> div []

viewAnswer : String -> Html Msg
viewAnswer answer =
    button [class "btn btn-primary mx-1"
    , onClick (Answer answer)] [text answer]
