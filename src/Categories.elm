module Categories exposing (..)

import Bootstrap.CDN exposing (stylesheet)
import Html exposing (a, div, h1, text)
import Html.Attributes exposing (class, href)
view =
    div [class "text-center"]
    [
        stylesheet
        , h1 [class "my-5"] [ text "Choose a difficulty bellow." ]
        , a [class "btn btn-primary mr-2", href "/quiz?q=easy"] [text "Easy"]
        , a [class "btn btn-primary mr-2", href "/quiz?q=medium"] [text "Medium"]
        , a [class "btn btn-primary mr-2", href "/quiz?q=hard"] [text "Hard"]
    ]
