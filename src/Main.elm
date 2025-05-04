module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Time
import Url



-- モデル定義


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


type alias Model =
    { key : Nav.Key
    , page : Page
    , reviews : List Review
    }


type Page
    = Home
    | Login
    | Register
    | BeverageList
    | BeverageDetail String
    | ReviewDetail String
    | NotFound


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ _ key =
    ( { key = key
      , page = Home
      , reviews = sampleReviews
      }
    , Cmd.none
    )


sampleReviews : List Review
sampleReviews =
    [ { id = "1"
      , userId = "user1"
      , userName = "田中太郎"
      , beverageId = "bev1"
      , beverageName = "山崎12年"
      , rating = 5
      , title = "素晴らしいウイスキー"
      , content = "バランスの取れた味わいで、余韻も長く楽しめます。"
      , imageUrl = Just "https://via.placeholder.com/150"
      , likes = 12
      , createdAt = Time.millisToPosix 1715000000000
      }
    , { id = "2"
      , userId = "user2"
      , userName = "佐藤花子"
      , beverageId = "bev2"
      , beverageName = "獺祭 純米大吟醸"
      , rating = 4
      , title = "フルーティで飲みやすい"
      , content = "日本酒が苦手な方でも楽しめる、フルーティな味わいです。"
      , imageUrl = Just "https://via.placeholder.com/150"
      , likes = 8
      , createdAt = Time.millisToPosix 1714900000000
      }
    , { id = "3"
      , userId = "user3"
      , userName = "鈴木一郎"
      , beverageId = "bev3"
      , beverageName = "よなよなエール"
      , rating = 4
      , title = "クラフトビールの定番"
      , content = "ホップの香りが強く、苦味と甘みのバランスが良いです。"
      , imageUrl = Nothing
      , likes = 5
      , createdAt = Time.millisToPosix 1714800000000
      }
    ]



-- メッセージ定義


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NavigateTo Page
    | LikeReview String



-- 更新関数


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( model, Cmd.none )

        NavigateTo page ->
            ( { model | page = page }, Cmd.none )

        LikeReview reviewId ->
            ( { model
                | reviews =
                    List.map
                        (\review ->
                            if review.id == reviewId then
                                { review | likes = review.likes + 1 }

                            else
                                review
                        )
                        model.reviews
              }
            , Cmd.none
            )



-- ビュー関数


view : Model -> Browser.Document Msg
view model =
    { title = "SakElm - お酒レビューアプリ"
    , body =
        [ viewHeader
        , div [ class "container" ]
            [ case model.page of
                Home ->
                    viewHome model

                Login ->
                    viewLogin

                Register ->
                    viewRegister

                BeverageList ->
                    viewBeverageList

                BeverageDetail id ->
                    viewBeverageDetail id

                ReviewDetail id ->
                    viewReviewDetail id model

                NotFound ->
                    viewNotFound
            ]
        , viewFooter
        ]
    }


viewHeader : Html Msg
viewHeader =
    header [ class "header" ]
        [ div [ class "logo" ] [ text "SakElm" ]
        , nav [ class "nav" ]
            [ ul [ class "nav-list" ]
                [ li [ class "nav-item", onClick (NavigateTo Home) ] [ text "ホーム" ]
                , li [ class "nav-item", onClick (NavigateTo BeverageList) ] [ text "お酒一覧" ]
                , li [ class "nav-item", onClick (NavigateTo Login) ] [ text "ログイン" ]
                , li [ class "nav-item", onClick (NavigateTo Register) ] [ text "新規登録" ]
                ]
            ]
        ]


viewHome : Model -> Html Msg
viewHome model =
    div [ class "home" ]
        [ h1 [] [ text "最新のレビュー" ]
        , div [ class "review-list" ] (List.map viewReviewCard model.reviews)
        ]


viewReviewCard : Review -> Html Msg
viewReviewCard review =
    div [ class "review-card", onClick (NavigateTo (ReviewDetail review.id)) ]
        [ div [ class "review-header" ]
            [ h3 [] [ text review.title ]
            , div [ class "review-meta" ]
                [ span [ class "review-author" ] [ text ("投稿者: " ++ review.userName) ]
                , span [ class "review-beverage" ] [ text ("お酒: " ++ review.beverageName) ]
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
            [ button [ class "like-button", onClick (LikeReview review.id) ]
                [ text ("♥ " ++ String.fromInt review.likes) ]
            ]
        ]


viewRating : Int -> Html Msg
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


viewLogin : Html Msg
viewLogin =
    div [ class "login" ]
        [ h1 [] [ text "ログイン" ]
        , div [] [ text "ここにログインフォームが入ります" ]
        ]


viewRegister : Html Msg
viewRegister =
    div [ class "register" ]
        [ h1 [] [ text "新規登録" ]
        , div [] [ text "ここに新規登録フォームが入ります" ]
        ]


viewBeverageList : Html Msg
viewBeverageList =
    div [ class "beverage-list" ]
        [ h1 [] [ text "お酒一覧" ]
        , div [] [ text "ここにお酒のリストが入ります" ]
        ]


viewBeverageDetail : String -> Html Msg
viewBeverageDetail id =
    div [ class "beverage-detail" ]
        [ h1 [] [ text ("お酒の詳細: ID " ++ id) ]
        , div [] [ text "ここにお酒の詳細情報が入ります" ]
        ]


viewReviewDetail : String -> Model -> Html Msg
viewReviewDetail id model =
    case List.head (List.filter (\r -> r.id == id) model.reviews) of
        Just review ->
            div [ class "review-detail" ]
                [ h1 [] [ text review.title ]
                , div [ class "review-meta" ]
                    [ span [ class "review-author" ] [ text ("投稿者: " ++ review.userName) ]
                    , span [ class "review-beverage" ] [ text ("お酒: " ++ review.beverageName) ]
                    ]
                , viewRating review.rating
                , div [ class "review-content-full" ] [ text review.content ]
                , case review.imageUrl of
                    Just url ->
                        img [ src url, class "review-image-large" ] []

                    Nothing ->
                        div [] []
                , div [ class "review-actions" ]
                    [ button [ class "like-button", onClick (LikeReview review.id) ]
                        [ text ("♥ " ++ String.fromInt review.likes) ]
                    ]
                , div [ class "comments" ] [ text "ここにコメントが入ります" ]
                ]

        Nothing ->
            div [] [ text "レビューが見つかりません" ]


viewNotFound : Html Msg
viewNotFound =
    div [ class "not-found" ]
        [ h1 [] [ text "404 - ページが見つかりません" ]
        , button [ onClick (NavigateTo Home) ] [ text "ホームに戻る" ]
        ]


viewFooter : Html Msg
viewFooter =
    footer [ class "footer" ]
        [ div [] [ text "© 2024 SakElm - お酒レビューアプリ" ]
        ]



-- メイン


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }
