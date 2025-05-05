port module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Time
import Url



-- ポート定義


port requestLogin : () -> Cmd msg


port requestLogout : () -> Cmd msg


port receiveUser : (Decode.Value -> msg) -> Sub msg


port receiveError : (Decode.Value -> msg) -> Sub msg


port saveReview : Encode.Value -> Cmd msg


port reviewSaved : (Decode.Value -> msg) -> Sub msg



-- モデル定義


type alias User =
    { uid : String
    , displayName : String
    , email : String
    , photoURL : Maybe String
    }


type alias Error =
    { code : String
    , message : String
    }


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
    , imageFile : Maybe String -- 実際は画像ファイル参照だがハリボテ
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


type alias Model =
    { key : Nav.Key
    , page : Page
    , reviews : List Review
    , user : Maybe User
    , error : Maybe Error
    , reviewForm : ReviewForm
    , formSubmitting : Bool
    , formSuccess : Bool
    , beverages : List Beverage -- お酒のリストを追加
    }


type alias Beverage =
    { id : String
    , name : String
    , category : String
    }


type Page
    = Home
    | Login
    | Register
    | BeverageList
    | BeverageDetail String
    | ReviewDetail String
    | NewReview
    | NotFound


type alias Flags =
    { user : Maybe User
    }


init : Decode.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags _ key =
    let
        decodedFlags =
            case Decode.decodeValue flagsDecoder flags of
                Ok value ->
                    value

                Err _ ->
                    { user = Nothing }
    in
    ( { key = key
      , page = Home
      , reviews = sampleReviews
      , user = decodedFlags.user
      , error = Nothing
      , reviewForm = emptyReviewForm
      , formSubmitting = False
      , formSuccess = False
      , beverages = sampleBeverages
      }
    , Cmd.none
    )


flagsDecoder : Decoder Flags
flagsDecoder =
    Decode.map Flags
        (Decode.field "user" (Decode.nullable userDecoder))


userDecoder : Decoder User
userDecoder =
    Decode.map4 User
        (Decode.field "uid" Decode.string)
        (Decode.field "displayName" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "photoURL" (Decode.nullable Decode.string))


errorDecoder : Decoder Error
errorDecoder =
    Decode.map2 Error
        (Decode.field "code" Decode.string)
        (Decode.field "message" Decode.string)


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


sampleBeverages : List Beverage
sampleBeverages =
    [ { id = "bev1", name = "山崎12年", category = "ウイスキー" }
    , { id = "bev2", name = "獺祭 純米大吟醸", category = "日本酒" }
    , { id = "bev3", name = "よなよなエール", category = "ビール" }
    , { id = "bev4", name = "久保田 千寿", category = "日本酒" }
    , { id = "bev5", name = "ヘネシーXO", category = "ブランデー" }
    ]



-- メッセージ定義


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NavigateTo Page
    | LikeReview String
    | LogIn
    | LogOut
    | ReceivedUser Decode.Value
    | ReceivedError Decode.Value
    | UpdateReviewForm ReviewFormField String
    | SetRating Int
    | SubmitReviewForm
    | ReviewSaved Decode.Value


type ReviewFormField
    = BeverageField
    | TitleField
    | ContentField
    | ImageField



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
            ( { model | error = Nothing, reviewForm = emptyReviewForm }, Cmd.none )

        NavigateTo page ->
            ( { model | page = page, error = Nothing, reviewForm = emptyReviewForm }, Cmd.none )

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

        LogIn ->
            ( model, requestLogin () )

        LogOut ->
            ( model, requestLogout () )

        ReceivedUser value ->
            case Decode.decodeValue (Decode.nullable userDecoder) value of
                Ok maybeUser ->
                    ( { model | user = maybeUser, error = Nothing }, Cmd.none )

                Err error ->
                    ( { model | error = Just { code = "decode-error", message = Decode.errorToString error } }, Cmd.none )

        ReceivedError value ->
            case Decode.decodeValue errorDecoder value of
                Ok error ->
                    ( { model | error = Just error }, Cmd.none )

                Err decodeError ->
                    ( { model | error = Just { code = "decode-error", message = Decode.errorToString decodeError } }, Cmd.none )

        UpdateReviewForm field value ->
            let
                form =
                    model.reviewForm

                updatedForm =
                    case field of
                        BeverageField ->
                            -- 選択されたお酒IDからお酒名も設定する
                            let
                                selectedBeverage =
                                    model.beverages
                                        |> List.filter (\b -> b.id == value)
                                        |> List.head

                                beverageName =
                                    case selectedBeverage of
                                        Just beverage ->
                                            beverage.name

                                        Nothing ->
                                            ""
                            in
                            { form | beverageId = value, beverageName = beverageName }

                        TitleField ->
                            { form | title = value }

                        ContentField ->
                            { form | content = value }

                        ImageField ->
                            { form | imageFile = Just value }
            in
            ( { model | reviewForm = updatedForm }, Cmd.none )

        SetRating rating ->
            let
                form =
                    model.reviewForm

                updatedForm =
                    { form | rating = rating }
            in
            ( { model | reviewForm = updatedForm }, Cmd.none )

        SubmitReviewForm ->
            case model.user of
                Just user ->
                    if String.isEmpty model.reviewForm.beverageId || String.isEmpty model.reviewForm.title then
                        ( { model | error = Just { code = "validation-error", message = "お酒と評価タイトルは必須です" } }, Cmd.none )

                    else
                        let
                            reviewData =
                                Encode.object
                                    [ ( "userId", Encode.string user.uid )
                                    , ( "userName", Encode.string user.displayName )
                                    , ( "beverageId", Encode.string model.reviewForm.beverageId )
                                    , ( "beverageName", Encode.string model.reviewForm.beverageName )
                                    , ( "rating", Encode.int model.reviewForm.rating )
                                    , ( "title", Encode.string model.reviewForm.title )
                                    , ( "content", Encode.string model.reviewForm.content )
                                    , ( "imageFile", Maybe.withDefault Encode.null (Maybe.map Encode.string model.reviewForm.imageFile) )
                                    ]
                        in
                        ( { model | formSubmitting = True }, saveReview reviewData )

                Nothing ->
                    ( { model | error = Just { code = "auth-error", message = "投稿するにはログインしてください" }, formSubmitting = False }, Cmd.none )

        ReviewSaved value ->
            case Decode.decodeValue (Decode.field "success" Decode.bool) value of
                Ok success ->
                    if success then
                        case Decode.decodeValue (Decode.field "review" reviewDecoder) value of
                            Ok newReview ->
                                ( { model
                                    | reviewForm = emptyReviewForm
                                    , formSubmitting = False
                                    , formSuccess = True
                                    , reviews = newReview :: model.reviews
                                    , page = Home
                                  }
                                , Cmd.none
                                )

                            Err _ ->
                                ( { model
                                    | formSubmitting = False
                                    , formSuccess = True
                                    , page = Home
                                  }
                                , Cmd.none
                                )

                    else
                        ( { model
                            | formSubmitting = False
                            , error = Just { code = "save-error", message = "レビューの保存に失敗しました" }
                          }
                        , Cmd.none
                        )

                Err error ->
                    ( { model
                        | formSubmitting = False
                        , error = Just { code = "decode-error", message = Decode.errorToString error }
                      }
                    , Cmd.none
                    )


reviewDecoder : Decoder Review
reviewDecoder =
    Decode.succeed
        (\id userId userName beverageId beverageName rating title content imageUrl ->
            { id = id
            , userId = userId
            , userName = userName
            , beverageId = beverageId
            , beverageName = beverageName
            , rating = rating
            , title = title
            , content = content
            , imageUrl = imageUrl
            , likes = 0
            , createdAt = Time.millisToPosix 0
            }
        )
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "userId" Decode.string
        |> Pipeline.required "userName" Decode.string
        |> Pipeline.required "beverageId" Decode.string
        |> Pipeline.required "beverageName" Decode.string
        |> Pipeline.required "rating" Decode.int
        |> Pipeline.required "title" Decode.string
        |> Pipeline.required "content" Decode.string
        |> Pipeline.required "imageUrl" (Decode.nullable Decode.string)



-- ビュー関数


view : Model -> Browser.Document Msg
view model =
    { title = "SakElm - お酒レビューアプリ"
    , body =
        [ viewHeader model
        , div [ class "container" ]
            [ case model.error of
                Just error ->
                    div [ class "error-message" ]
                        [ text ("エラー: " ++ error.message) ]

                Nothing ->
                    text ""
            , case model.page of
                Home ->
                    viewHome model

                Login ->
                    viewLogin model

                Register ->
                    viewRegister

                BeverageList ->
                    viewBeverageList model

                BeverageDetail id ->
                    viewBeverageDetail id

                ReviewDetail id ->
                    viewReviewDetail id model

                NewReview ->
                    viewNewReview model

                NotFound ->
                    viewNotFound
            ]
        , viewFooter
        ]
    }


viewHeader : Model -> Html Msg
viewHeader model =
    header [ class "header" ]
        [ div [ class "logo" ] [ text "SakElm" ]
        , nav [ class "nav" ]
            [ ul [ class "nav-list" ]
                [ li [ class "nav-item", onClick (NavigateTo Home) ] [ text "ホーム" ]
                , li [ class "nav-item", onClick (NavigateTo BeverageList) ] [ text "お酒一覧" ]
                , case model.user of
                    Just _ ->
                        li [ class "nav-item", onClick (NavigateTo NewReview) ] [ text "レビューを投稿" ]

                    Nothing ->
                        text ""
                , case model.user of
                    Just user ->
                        div [ class "user-menu" ]
                            [ div [ class "user-info" ]
                                [ case user.photoURL of
                                    Just url ->
                                        img [ src url, class "user-avatar" ] []

                                    Nothing ->
                                        div [ class "user-avatar-placeholder" ] [ text (String.left 1 user.displayName) ]
                                , span [ class "user-name" ] [ text user.displayName ]
                                ]
                            , li [ class "nav-item", onClick LogOut ] [ text "ログアウト" ]
                            ]

                    Nothing ->
                        li [ class "nav-item", onClick (NavigateTo Login) ] [ text "ログイン" ]
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


viewLogin : Model -> Html Msg
viewLogin model =
    div [ class "login" ]
        [ h1 [] [ text "ログイン" ]
        , case model.user of
            Just user ->
                div [ class "login-status" ]
                    [ p [] [ text ("こんにちは、" ++ user.displayName ++ "さん！") ]
                    , button [ class "logout-button", onClick LogOut ] [ text "ログアウト" ]
                    ]

            Nothing ->
                div [ class "login-buttons" ]
                    [ button [ class "google-sign-in", onClick LogIn ]
                        [ text "Googleでログイン" ]
                    ]
        ]


viewRegister : Html Msg
viewRegister =
    div [ class "register" ]
        [ h1 [] [ text "新規登録" ]
        , div [] [ text "ここに新規登録フォームが入ります" ]
        ]


viewBeverageList : Model -> Html Msg
viewBeverageList model =
    div [ class "beverage-list" ]
        [ h1 [] [ text "お酒一覧" ]
        , div [ class "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5" ]
            (List.map
                (\beverage ->
                    div
                        [ class "bg-white rounded-lg shadow-md p-5 cursor-pointer hover:translate-y-[-5px] hover:shadow-lg transition-transform"
                        , onClick (NavigateTo (BeverageDetail beverage.id))
                        ]
                        [ h3 [] [ text beverage.name ]
                        , p [] [ text ("カテゴリー: " ++ beverage.category) ]
                        ]
                )
                model.beverages
            )
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


viewNewReview : Model -> Html Msg
viewNewReview model =
    div [ class "new-review bg-white rounded-lg shadow-md p-8 mt-5" ]
        [ h1 [] [ text "新規レビューを投稿" ]
        , case model.user of
            Nothing ->
                div []
                    [ p [] [ text "レビューを投稿するにはログインが必要です。" ]
                    , button [ class "button-primary", onClick (NavigateTo Login) ] [ text "ログイン" ]
                    ]

            Just _ ->
                if model.formSubmitting then
                    div [ class "text-center py-8" ]
                        [ p [] [ text "送信中..." ]
                        ]

                else if model.formSuccess then
                    div [ class "text-center py-8" ]
                        [ p [] [ text "レビューが投稿されました！" ]
                        , button [ class "button-primary", onClick (NavigateTo Home) ] [ text "ホームに戻る" ]
                        ]

                else
                    Html.form [ class "review-form", onSubmit SubmitReviewForm ]
                        [ div [ class "form-group" ]
                            [ label [ for "beverage" ] [ text "お酒を選択" ]
                            , select
                                [ id "beverage"
                                , class "form-select"
                                , onInput (UpdateReviewForm BeverageField)
                                , required True
                                ]
                                (option [ value "" ] [ text "-- 選択してください --" ]
                                    :: List.map
                                        (\beverage ->
                                            option [ value beverage.id ] [ text beverage.name ]
                                        )
                                        model.beverages
                                )
                            ]
                        , div [ class "form-group" ]
                            [ label [] [ text "評価" ]
                            , div [ class "flex items-center" ]
                                (List.map
                                    (\i ->
                                        span
                                            [ class
                                                (if i <= model.reviewForm.rating then
                                                    "star filled cursor-pointer text-2xl mx-1"

                                                 else
                                                    "star cursor-pointer text-2xl mx-1"
                                                )
                                            , onClick (SetRating i)
                                            ]
                                            [ text "★" ]
                                    )
                                    (List.range 1 5)
                                )
                            ]
                        , div [ class "form-group" ]
                            [ label [ for "title" ] [ text "タイトル" ]
                            , input
                                [ id "title"
                                , class "form-input"
                                , type_ "text"
                                , placeholder "レビューのタイトル"
                                , value model.reviewForm.title
                                , onInput (UpdateReviewForm TitleField)
                                , required True
                                ]
                                []
                            ]
                        , div [ class "form-group" ]
                            [ label [ for "content" ] [ text "内容" ]
                            , textarea
                                [ id "content"
                                , class "form-textarea"
                                , placeholder "レビューの内容を入力..."
                                , rows 5
                                , value model.reviewForm.content
                                , onInput (UpdateReviewForm ContentField)
                                ]
                                []
                            ]
                        , div [ class "form-group" ]
                            [ label [ for "image" ] [ text "画像" ]
                            , input
                                [ id "image"
                                , class "form-input"
                                , type_ "file"
                                , accept "image/*"
                                , onInput (UpdateReviewForm ImageField)
                                ]
                                []
                            ]
                        , div [ class "form-actions" ]
                            [ button
                                [ class "button-primary"
                                , type_ "submit"
                                ]
                                [ text "投稿する" ]
                            , button
                                [ class "button-secondary ml-4"
                                , type_ "button"
                                , onClick (NavigateTo Home)
                                ]
                                [ text "キャンセル" ]
                            ]
                        ]
        ]


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



-- サブスクリプション


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveUser ReceivedUser
        , receiveError ReceivedError
        , reviewSaved ReviewSaved
        ]



-- メイン


main : Program Decode.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }
