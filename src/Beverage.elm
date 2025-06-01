module Beverage exposing
    ( Beverage
    , BeverageForm
    , beverageDecoder
    , emptyBeverageForm
    , viewBeverageCard
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as Decode exposing (Decoder, nullable)
import Json.Decode.Pipeline as Pipeline


type alias Beverage =
    { id : String
    , name : String
    , category : String
    , alcoholPercentage : Maybe Float
    , manufacturer : Maybe String
    , description : Maybe String
    }


type alias BeverageForm =
    { name : String
    , category : String
    , alcoholPercentage : String
    , manufacturer : String
    , description : String
    }


emptyBeverageForm : BeverageForm
emptyBeverageForm =
    { name = ""
    , category = ""
    , alcoholPercentage = ""
    , manufacturer = ""
    , description = ""
    }


beverageDecoder : Decoder Beverage
beverageDecoder =
    Decode.succeed Beverage
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "category" Decode.string
        |> Pipeline.optional "alcoholPercentage" (nullable Decode.float) Nothing
        |> Pipeline.optional "manufacturer" (nullable Decode.string) Nothing
        |> Pipeline.optional "description" (nullable Decode.string) Nothing


viewBeverageCard : (String -> msg) -> Beverage -> Html msg
viewBeverageCard toBeverageDetail beverage =
    div
        [ class "bg-white rounded-lg shadow-md p-5 cursor-pointer hover:translate-y-[-5px] hover:shadow-lg transition-transform"
        , onClick (toBeverageDetail beverage.id)
        ]
        [ h3 [] [ text beverage.name ]
        , p [] [ text ("カテゴリー: " ++ beverage.category) ]
        ]
