module Review exposing
    ( Review
    , ReviewForm
    , emptyReviewForm
    , reviewDecoder
    )

import Json.Decode as Decode exposing (Decoder, field, nullable)
import Json.Decode.Pipeline as Pipeline
import Time


type alias Review =
    { id : String
    , userId : String
    , userName : String
    , beverageId : String
    , beverageName : String
    , rating : Int
    , title : String
    , content : String
    , imageUrl : Maybe String
    , likes : Int
    , createdAt : Time.Posix
    }


type alias ReviewForm =
    { beverageId : String
    , beverageName : String
    , rating : Int
    , title : String
    , content : String
    , imageFile : Maybe String
    }


emptyReviewForm : ReviewForm
emptyReviewForm =
    { beverageId = ""
    , beverageName = ""
    , rating = 3
    , title = ""
    , content = ""
    , imageFile = Nothing
    }


reviewDecoder : Decoder Review
reviewDecoder =
    Decode.succeed Review
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "userId" Decode.string
        |> Pipeline.required "userName" Decode.string
        |> Pipeline.required "beverageId" Decode.string
        |> Pipeline.required "beverageName" Decode.string
        |> Pipeline.required "rating" Decode.int
        |> Pipeline.required "title" Decode.string
        |> Pipeline.required "content" Decode.string
        |> Pipeline.required "imageUrl" (nullable Decode.string)
        |> Pipeline.required "likes" Decode.int
        |> Pipeline.required "createdAt" (Decode.map Time.millisToPosix Decode.int)
