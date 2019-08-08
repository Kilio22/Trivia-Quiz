module Home exposing (..)

import Bootstrap.CDN exposing (stylesheet)
import Html exposing (Html, a, div, h1, text)
import Html.Attributes exposing (class, href, style)

view =
    div [class "text-center", style "position" "absolute", style "top" "40%", style "left" "50%", style "transform" "translate(-50%, -50%)"]
     [ stylesheet
     , h1 [class "my-5"] [ text "Trivia-Quizz"]
     , a [class "btn btn-primary mr-2", href "/quiz?q=medium"] [
        text "Play !"
     ]
     , a [class "btn btn-primary mr-2", href "/categories"] [
        text "Play from a categorie"
     ]
    ]
