module Main exposing (..)

import Browser exposing (Document, UrlRequest(..))
import Browser.Navigation as Navigation exposing (Key)
import Categories
import Home
import Html
import Json.Decode exposing (Value)
import QuizzPage
import Url exposing (Url)
import Url.Parser as Parser exposing ((<?>), oneOf, parse, s, top)
import Url.Parser.Query as Query

main : Program Value Model Msg
main =
    Browser.application
    {
    init = init
    , view = view
    , update = update
    , subscriptions = always Sub.none
    , onUrlRequest = OnUrlRequest
    , onUrlChange = OnUrlChange
    }

type Page =
    HomePage
    | QuizPage QuizzPage.Model
    | CategoriePage

type Route =
    HomeRoute
    | QuizRoute (Maybe String)
    | CategorieRoute
type alias Model =
    { key : Key, page : Page }

type Msg =
    OnUrlRequest UrlRequest
    | OnUrlChange Url
    | QuizPageMsg QuizzPage.Msg

init : Value -> Url -> Key -> (Model, Cmd Msg)
init _ url key =
    ( Model key HomePage, Cmd.none )

view : Model -> Document Msg
view model =
    { title = "Oui.sh"
    , body = [
        case model.page of
            HomePage ->
               Home.view
            QuizPage quizzPageModel ->
                QuizzPage.view quizzPageModel
                    |> Html.map QuizPageMsg
            CategoriePage ->
                Categories.view
        ]
    }

parseUrlToRoute : Url -> Route
parseUrlToRoute url =
        oneOf
        [
            Parser.map HomeRoute top
            , Parser.map QuizRoute (s "quiz" <?> Query.string "q")
            , Parser.map CategorieRoute (s "categories")
        ]
            |> (\parser -> parse parser url)
            |> Maybe.withDefault HomeRoute

changePage : Model -> Route -> (Model, Cmd Msg)
changePage model route =
    case route of
        HomeRoute ->
            ({model | page = HomePage}, Cmd.none)
        QuizRoute arg ->
            case arg of
                Just oui ->
                    let
                        (initialModel, cmd) =
                            QuizzPage.init oui
                    in
                        ({model | page = QuizPage initialModel}, Cmd.map QuizPageMsg cmd)
                Nothing ->
                    let
                        (initialModel, cmd) =
                            QuizzPage.init "medium"
                    in
                        ({model | page = QuizPage initialModel}, Cmd.map QuizPageMsg cmd)
        CategorieRoute ->
                        ({model | page = CategoriePage}, Cmd.none)

update : Msg -> Model -> ( Model, Cmd Msg)
update msg model =
    case msg of
        OnUrlRequest (External url) ->
            (model, Navigation.load url)
        OnUrlRequest (Internal url) ->
            (model, Navigation.pushUrl model.key (Url.toString url))
        OnUrlChange url ->
            parseUrlToRoute url
                |> changePage model
        QuizPageMsg quizzPageMsg ->
            case model.page of
                QuizPage quizzPageModel ->
                    let
                        (newModel, cmd) =
                            QuizzPage.update quizzPageMsg quizzPageModel
                    in
                        ({model | page = QuizPage newModel}, Cmd.map QuizPageMsg cmd)
                _ ->
                    (model, Cmd.none)
