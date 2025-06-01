module Review exposing
    ( Review
    , ReviewForm
    , emptyReviewForm
    , reviewDecoder
    , viewRating
    , viewReviewCard
    , viewReviewDetail
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as Decode exposing (Decoder, nullable)
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


viewReviewCard : (String -> msg) -> (String -> msg) -> (String -> msg) -> Review -> Html msg
viewReviewCard toReviewDetail toBeverageDatail onLikeClicked review =
    div [ class "review-card", onClick (toReviewDetail review.id) ]
        [ div [ class "review-header" ]
            [ h3 [] [ text review.title ]
            , div [ class "review-meta" ]
                [ span [ class "review-author" ] [ text ("投稿者: " ++ review.userName) ]

                -- お酒名をクリック可能にする
                , span
                    [ class "review-beverage cursor-pointer hover:underline"
                    , -- 親要素の onClick イベント伝播を停止し、メッセージを送信する
                      Html.Events.stopPropagationOn "click"
                        (Decode.succeed ( toBeverageDatail review.beverageId, True ))

                    -- <- これで置き換え
                    ]
                    [ text ("お酒: " ++ review.beverageName) ]
                ]
            ]
        , viewRating review.rating
        , div [ class "review-content" ] [ text review.content ]
        , case review.imageUrl of
            Just url ->
                img [ src url, class "review-image" ] []

            Nothing ->
                div [] []
        , div [ class "review-footer" ]
            [ button
                [ class "like-button"

                -- LikeReview メッセージを送信し、親要素へのイベント伝播を停止する
                , Html.Events.stopPropagationOn "click" (Decode.succeed ( onLikeClicked review.id, True ))
                ]
                [ text ("♥ " ++ String.fromInt review.likes) ]
            ]
        ]


viewRating : Int -> Html msg
viewRating rating =
    div [ class "rating" ]
        (List.map
            (\i ->
                span
                    [ class
                        (if i <= rating then
                            "star filled"

                         else
                            "star"
                        )
                    ]
                    [ text "★" ]
            )
            (List.range 1 5)
        )


viewReviewDetail : (String -> msg) -> (String -> msg) -> msg -> String -> List Review -> Html msg
viewReviewDetail toBeverageDatail onLikeClicked toHome id reviews =
    case List.head (List.filter (\r -> r.id == id) reviews) of
        Just review ->
            div [ class "review-detail" ]
                [ h1 [] [ text review.title ]
                , div [ class "review-meta" ]
                    [ span [ class "review-author" ] [ text ("投稿者: " ++ review.userName) ]

                    -- お酒名をクリック可能にする
                    , span
                        [ class "review-beverage cursor-pointer hover:underline"
                        , onClick (toBeverageDatail review.beverageId)
                        ]
                        [ text ("お酒: " ++ review.beverageName) ]
                    ]
                , viewRating review.rating
                , div [ class "review-content-full" ] [ text review.content ]
                , case review.imageUrl of
                    Just url ->
                        img [ src url, class "review-image-large" ] []

                    Nothing ->
                        div [] []
                , div [ class "review-actions" ]
                    [ button [ class "like-button", onClick (onLikeClicked review.id) ]
                        [ text ("♥ " ++ String.fromInt review.likes) ]
                    ]
                , div [ class "comments" ] [ text "ここにコメントが入ります" ]
                ]

        Nothing ->
            div [ class "not-found bg-white rounded-lg shadow-md p-8 mt-5" ]
                [ h1 [] [ text "レビューが見つかりません" ]
                , p [] [ text ("ID: " ++ id ++ " のレビューは見つかりませんでした。") ]
                , button [ class "button-primary mt-4", onClick toHome ] [ text "ホームに戻る" ]
                ]
