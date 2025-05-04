module Main exposing (main)

import Browser
import Html exposing (div, text)


main : Program () Int msg
main =
    Browser.sandbox
        { init = 0
        , update = \_ model -> model
        , view = \model -> div [] [ text ("Counter: " ++ String.fromInt model) ]
        }
