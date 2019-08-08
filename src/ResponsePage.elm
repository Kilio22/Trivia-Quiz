module ResponsePage exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Bootstrap.CDN exposing (stylesheet)

viewScore : Int -> List Bool -> Html msg
viewScore results =
    let
        counter = List.length results
        nbTrue = List.filter (\x -> x) results
                    |> List.length
    in
        div [class "text-center"]
            [ stylesheet
            , h1 [ class "my-5"] [text ("Your score: " ++ String.fromInt nbTrue ++ "/" ++ String.fromInt counter)]
            , viewResults results
            ]

viewResults : List Bool -> Html msg
viewResults results =
    List.map viewResult results
    |> div []

viewResult: Bool -> Html msg
viewResult result =
    if result then
        div [class "text-success"] [text "Correct!"]
    else
        div [class "text-danger"] [text "Incorrect..."]

