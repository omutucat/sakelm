port module Main exposing (main)

import Beverage
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Json.Decode as Decode exposing (Decoder, field)
import Json.Encode as Encode
import Review exposing (viewReviewCard, viewReviewDetail)
import Url
import Url.Parser as Parser exposing ((</>), Parser, oneOf)
import User exposing (Error, User)



-- ポート定義


port requestLogin : () -> Cmd msg


port requestLogout : () -> Cmd msg


port receiveError : (Decode.Value -> msg) -> Sub msg


port saveReview : Encode.Value -> Cmd msg


port reviewSaved : (Decode.Value -> msg) -> Sub msg


port requestReviews : () -> Cmd msg


port receiveReviews : (Decode.Value -> msg) -> Sub msg


port saveBeverage : Encode.Value -> Cmd msg


port beverageSaved : (Decode.Value -> msg) -> Sub msg


port requestBeverages : () -> Cmd msg


port receiveBeverages : (Decode.Value -> msg) -> Sub msg



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


type alias Model =
    { key : Nav.Key
    , page : Page
    , reviews : List Review.Review -- Firestoreから取得したレビューを格納
    , user : Maybe User
    , error : Maybe Error
    , reviewForm : Review.ReviewForm
    , formSubmitting : Bool
    , formSuccess : Bool
    , beverages : List Beverage.Beverage -- お酒のリストを追加
    , reviewsLoading : Bool -- レビュー読み込み中フラグを追加
    , beverageForm : Beverage.BeverageForm -- お酒追加フォーム
    , beverageFormSubmitting : Bool
    , beverageFormSuccess : Bool
    , beveragesLoading : Bool -- お酒の読み込み中フラグ
    }


type Page
    = Home
    | Login
    | Register
    | BeverageList
    | BeverageDetail String -- 追加: お酒IDを保持
    | ReviewDetail String
    | NewReview
    | NewBeverage -- 新しいお酒追加ページ
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
      , reviews = [] -- 初期状態は空リスト
      , user = decodedFlags.user
      , error = Nothing
      , reviewForm = Review.emptyReviewForm
      , formSubmitting = False
      , formSuccess = False
      , beverages = []
      , reviewsLoading = True -- 初期状態は読み込み中
      , beverageForm = Beverage.emptyBeverageForm
      , beverageFormSubmitting = False
      , beverageFormSuccess = False
      , beveragesLoading = True
      }
    , Cmd.batch
        [ requestReviews () -- レビュー取得
        , requestBeverages () -- お酒のリスト取得
        ]
    )


flagsDecoder : Decoder Flags
flagsDecoder =
    Decode.map Flags
        (Decode.field "user" (Decode.nullable User.userDecoder))



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
    | RequestReviews -- レビュー取得リクエストメッセージ
    | ReceivedReviews Decode.Value -- レビュー受信メッセージ
    | UpdateBeverageForm BeverageFormField String
    | SubmitBeverageForm
    | BeverageSaved Decode.Value
    | RequestBeverages
    | ReceivedBeverages Decode.Value


type ReviewFormField
    = BeverageField
    | TitleField
    | ContentField
    | ImageField


type BeverageFormField
    = BeverageNameField
    | BeverageCategoryField
    | BeverageAlcoholField
    | BeverageManufacturerField
    | BeverageDescriptionField



-- URL パーサーの定義


pageParser : Parser (Page -> a) a
pageParser =
    oneOf
        [ Parser.map Home Parser.top
        , Parser.map Login (Parser.s "login")
        , Parser.map Register (Parser.s "register")
        , Parser.map BeverageList (Parser.s "beverages")
        , Parser.map BeverageDetail (Parser.s "beverages" </> Parser.string) -- /beverages/{id}
        , Parser.map ReviewDetail (Parser.s "reviews" </> Parser.string) -- /reviews/{id}
        , Parser.map NewReview (Parser.s "new-review")
        , Parser.map NewBeverage (Parser.s "new-beverage") -- /new-beverage
        ]



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
            -- Url.Parser を使用してページを決定
            let
                newPage =
                    Maybe.withDefault NotFound (Parser.parse pageParser url)

                -- ページ遷移時にフォームの状態をリセットする
                resetFormState page model_ =
                    case page of
                        NewReview ->
                            { model_ | formSuccess = False, reviewForm = Review.emptyReviewForm }

                        NewBeverage ->
                            { model_ | beverageFormSuccess = False, beverageForm = Beverage.emptyBeverageForm }

                        _ ->
                            model_
            in
            ( { model | page = newPage, error = Nothing } |> resetFormState newPage, Cmd.none )

        NavigateTo page ->
            -- URL を更新して UrlChanged をトリガーする
            let
                urlPath =
                    case page of
                        Home ->
                            "/"

                        Login ->
                            "/login"

                        Register ->
                            "/register"

                        BeverageList ->
                            "/beverages"

                        BeverageDetail id ->
                            "/beverages/" ++ id

                        ReviewDetail id ->
                            "/reviews/" ++ id

                        NewReview ->
                            "/new-review"

                        NewBeverage ->
                            "/new-beverage"

                        NotFound ->
                            "/404"

                -- または他の適切なパス
            in
            ( model, Nav.pushUrl model.key urlPath )

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
            ( model, User.requestLogin () )

        LogOut ->
            ( model, User.requestLogout () )

        ReceivedUser value ->
            case Decode.decodeValue (Decode.nullable User.userDecoder) value of
                Ok maybeUser ->
                    -- ユーザー状態が変わったらレビューを再取得
                    ( { model | user = maybeUser, error = Nothing, reviewsLoading = True }, requestReviews () )

                Err error ->
                    ( { model | error = Just { code = "decode-error", message = Decode.errorToString error } }, Cmd.none )

        ReceivedError value ->
            case Decode.decodeValue User.errorDecoder value of
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
                        case Decode.decodeValue (Decode.field "review" Review.reviewDecoder) value of
                            Ok newReview ->
                                -- 新しいレビューをリストの先頭に追加
                                ( { model
                                    | reviewForm = Review.emptyReviewForm
                                    , formSubmitting = False
                                    , formSuccess = True
                                    , reviews = newReview :: model.reviews -- Firestoreから再取得せず、ローカルで追加
                                    , page = Home
                                  }
                                , Cmd.none
                                )

                            Err decodeError ->
                                -- デコードエラーの場合でも成功メッセージは表示し、リストは更新しない（あるいはエラー表示）
                                ( { model
                                    | formSubmitting = False
                                    , formSuccess = True
                                    , page = Home
                                    , error = Just { code = "decode-error", message = "受信したレビューデータの形式が正しくありません: " ++ Decode.errorToString decodeError }
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

        RequestReviews ->
            ( { model | reviewsLoading = True }, requestReviews () )

        ReceivedReviews value ->
            case Decode.decodeValue (Decode.list Review.reviewDecoder) value of
                Ok receivedReviews ->
                    ( { model | reviews = receivedReviews, reviewsLoading = False, error = Nothing }, Cmd.none )

                Err decodeError ->
                    ( { model | reviewsLoading = False, error = Just { code = "decode-error", message = "レビューリストのデコードに失敗しました: " ++ Decode.errorToString decodeError } }, Cmd.none )

        -- お酒のフォーム更新
        UpdateBeverageForm field value ->
            let
                form =
                    model.beverageForm

                updatedForm =
                    case field of
                        BeverageNameField ->
                            { form | name = value }

                        BeverageCategoryField ->
                            { form | category = value }

                        BeverageAlcoholField ->
                            { form | alcoholPercentage = value }

                        BeverageManufacturerField ->
                            { form | manufacturer = value }

                        BeverageDescriptionField ->
                            { form | description = value }
            in
            ( { model | beverageForm = updatedForm }, Cmd.none )

        -- お酒の登録送信
        SubmitBeverageForm ->
            case model.user of
                Just user ->
                    if String.isEmpty model.beverageForm.name || String.isEmpty model.beverageForm.category then
                        ( { model | error = Just { code = "validation-error", message = "お酒の名前とカテゴリーは必須です" } }, Cmd.none )

                    else
                        let
                            -- 度数をStringからMaybe Float に変換
                            alcoholPercentage =
                                case String.toFloat model.beverageForm.alcoholPercentage of
                                    Just value ->
                                        Encode.float value

                                    Nothing ->
                                        Encode.null

                            beverageData =
                                Encode.object
                                    [ ( "name", Encode.string model.beverageForm.name )
                                    , ( "category", Encode.string model.beverageForm.category )
                                    , ( "alcoholPercentage", alcoholPercentage )
                                    , ( "manufacturer", Encode.string model.beverageForm.manufacturer )
                                    , ( "description", Encode.string model.beverageForm.description )
                                    , ( "userId", Encode.string user.uid ) -- 作成者のIDも保存
                                    ]
                        in
                        ( { model | beverageFormSubmitting = True }, saveBeverage beverageData )

                Nothing ->
                    ( { model | error = Just { code = "auth-error", message = "お酒を登録するにはログインしてください" }, beverageFormSubmitting = False }, Cmd.none )

        -- お酒の保存結果処理
        BeverageSaved value ->
            case Decode.decodeValue (Decode.field "success" Decode.bool) value of
                Ok success ->
                    if success then
                        case Decode.decodeValue (Decode.field "beverage" Beverage.beverageDecoder) value of
                            Ok newBeverage ->
                                -- 新しいお酒をリストに追加
                                ( { model
                                    | beverageForm = Beverage.emptyBeverageForm
                                    , beverageFormSubmitting = False
                                    , beverageFormSuccess = True
                                    , beverages = newBeverage :: model.beverages
                                  }
                                , Cmd.none
                                )

                            Err decodeError ->
                                ( { model
                                    | beverageFormSubmitting = False
                                    , beverageFormSuccess = True
                                    , error = Just { code = "decode-error", message = "受信したお酒データの形式が正しくありません: " ++ Decode.errorToString decodeError }
                                  }
                                , Cmd.none
                                )

                    else
                        ( { model
                            | beverageFormSubmitting = False
                            , error = Just { code = "save-error", message = "お酒の保存に失敗しました" }
                          }
                        , Cmd.none
                        )

                Err error ->
                    ( { model
                        | beverageFormSubmitting = False
                        , error = Just { code = "decode-error", message = Decode.errorToString error }
                      }
                    , Cmd.none
                    )

        -- お酒リスト取得リクエスト
        RequestBeverages ->
            ( { model | beveragesLoading = True }, requestBeverages () )

        -- お酒リスト受信処理
        ReceivedBeverages value ->
            case Decode.decodeValue (Decode.list Beverage.beverageDecoder) value of
                Ok receivedBeverages ->
                    ( { model | beverages = receivedBeverages, beveragesLoading = False, error = Nothing }, Cmd.none )

                Err decodeError ->
                    ( { model | beveragesLoading = False, error = Just { code = "decode-error", message = "お酒リストのデコードに失敗しました: " ++ Decode.errorToString decodeError } }, Cmd.none )



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
                    viewBeverageDetail id model

                -- 呼び出しを追加
                ReviewDetail id ->
                    viewReviewDetail (\beverageId -> NavigateTo (BeverageDetail beverageId)) LikeReview (NavigateTo Home) id model.reviews

                NewReview ->
                    viewNewReview model

                NewBeverage ->
                    viewNewBeverage model

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
                    Just _ ->
                        li [ class "nav-item", onClick (NavigateTo NewBeverage) ] [ text "お酒を登録" ]

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
        , if model.reviewsLoading then
            div [ class "text-center py-8" ] [ text "レビューを読み込み中..." ]

          else if List.isEmpty model.reviews then
            div [ class "text-center py-8" ] [ text "まだレビューがありません。" ]

          else
            div [ class "review-list" ] (List.map (viewReviewCard (\reviewId -> NavigateTo (ReviewDetail reviewId)) (\beverageId -> NavigateTo (BeverageDetail beverageId)) LikeReview) model.reviews)
        ]


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
        [ div [ class "flex justify-between items-center mb-4" ]
            [ h1 [] [ text "お酒一覧" ]
            , case model.user of
                Just _ ->
                    button
                        [ class "button-primary"
                        , onClick (NavigateTo NewBeverage)
                        ]
                        [ text "お酒を登録" ]

                Nothing ->
                    text ""
            ]
        , if model.beveragesLoading then
            div [ class "text-center py-8" ] [ text "お酒リスト読み込み中..." ]

          else if List.isEmpty model.beverages then
            div [ class "text-center py-8" ] [ text "登録されているお酒がありません。" ]

          else
            div [ class "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5" ]
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


viewBeverageDetail : String -> Model -> Html Msg
viewBeverageDetail id model =
    case List.head (List.filter (\b -> b.id == id) model.beverages) of
        Just beverage ->
            div [ class "beverage-detail bg-white rounded-lg shadow-md p-8 mt-5" ]
                [ h1 [] [ text beverage.name ]
                , div [ class "mb-4 grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-2" ]
                    [ div []
                        [ strong [] [ text "カテゴリー: " ]
                        , text beverage.category
                        ]
                    , div []
                        [ strong [] [ text "度数: " ]
                        , text (Maybe.map (\p -> String.fromFloat p ++ "%") beverage.alcoholPercentage |> Maybe.withDefault "不明")
                        ]
                    , div []
                        [ strong [] [ text "製造元: " ]
                        , text (Maybe.withDefault "不明" beverage.manufacturer)
                        ]
                    ]
                , case beverage.description of
                    Just desc ->
                        div [ class "mt-4 mb-6" ]
                            [ strong [] [ text "説明: " ]
                            , p [ class "mt-1" ] [ text desc ]
                            ]

                    Nothing ->
                        text ""

                -- TODO: 将来的に追加されるであろうお酒の詳細情報を表示する箇所
                -- 例:
                -- , p [] [ text ("製造元: " ++ Maybe.withDefault "不明" beverage.manufacturer) ]
                -- , p [] [ text ("度数: " ++ Maybe.map String.fromFloat beverage.alcoholPercentage |> Maybe.withDefault "不明" ++ "%") ]
                -- , p [] [ text ("説明: " ++ Maybe.withDefault "" beverage.description) ]
                , h2 [ class "mt-8 mb-4 text-xl text-primary" ] [ text (beverage.name ++ " のレビュー") ]
                , let
                    relatedReviews =
                        List.filter (\r -> r.beverageId == id) model.reviews
                  in
                  if List.isEmpty relatedReviews then
                    p [] [ text "このお酒に関するレビューはまだありません。" ]

                  else if model.reviewsLoading then
                    div [ class "text-center py-8" ] [ text "レビューを読み込み中..." ]

                  else
                    div [ class "review-list" ] (List.map (viewReviewCard (\reviewId -> NavigateTo (ReviewDetail reviewId)) (\beverageId -> NavigateTo (BeverageDetail beverageId)) LikeReview) relatedReviews)
                , button
                    [ class "button-primary mt-8"

                    -- TODO: 新規レビューページにお酒IDを渡すように変更する
                    -- 現状は新規レビューページに遷移するだけ
                    , onClick (NavigateTo NewReview)
                    ]
                    [ text "このお酒のレビューを投稿する" ]
                ]

        Nothing ->
            div [ class "not-found bg-white rounded-lg shadow-md p-8 mt-5" ]
                [ h1 [] [ text "お酒が見つかりません" ]
                , p [] [ text ("ID: " ++ id ++ " のお酒は見つかりませんでした。") ]
                , button [ class "button-primary mt-4", onClick (NavigateTo BeverageList) ] [ text "お酒一覧に戻る" ]
                ]


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


viewNewBeverage : Model -> Html Msg
viewNewBeverage model =
    div [ class "new-beverage bg-white rounded-lg shadow-md p-8 mt-5" ]
        [ h1 [] [ text "新しいお酒を登録" ]
        , case model.user of
            Nothing ->
                div []
                    [ p [] [ text "お酒を登録するにはログインが必要です。" ]
                    , button [ class "button-primary", onClick (NavigateTo Login) ] [ text "ログイン" ]
                    ]

            Just _ ->
                if model.beverageFormSubmitting then
                    div [ class "text-center py-8" ]
                        [ p [] [ text "送信中..." ]
                        ]

                else if model.beverageFormSuccess then
                    div [ class "text-center py-8" ]
                        [ p [] [ text "お酒が登録されました！" ]
                        , button [ class "button-primary", onClick (NavigateTo BeverageList) ] [ text "お酒一覧に戻る" ]
                        ]

                else
                    Html.form [ class "beverage-form", onSubmit SubmitBeverageForm ]
                        [ div [ class "form-group" ]
                            [ label [ for "name" ] [ text "お酒の名前" ]
                            , input
                                [ id "name"
                                , class "form-input"
                                , type_ "text"
                                , placeholder "お酒の名前を入力"
                                , value model.beverageForm.name
                                , onInput (UpdateBeverageForm BeverageNameField)
                                , required True
                                ]
                                []
                            ]
                        , div [ class "form-group" ]
                            [ label [ for "category" ] [ text "カテゴリー" ]
                            , select
                                [ id "category"
                                , class "form-select"
                                , onInput (UpdateBeverageForm BeverageCategoryField)
                                , required True
                                ]
                                [ option [ value "" ] [ text "-- 選択してください --" ]
                                , option [ value "日本酒" ] [ text "日本酒" ]
                                , option [ value "ビール" ] [ text "ビール" ]
                                , option [ value "ワイン" ] [ text "ワイン" ]
                                , option [ value "ウイスキー" ] [ text "ウイスキー" ]
                                , option [ value "焼酎" ] [ text "焼酎" ]
                                , option [ value "ジン" ] [ text "ジン" ]
                                , option [ value "ブランデー" ] [ text "ブランデー" ]
                                , option [ value "その他" ] [ text "その他" ]
                                ]
                            ]
                        , div [ class "form-group" ]
                            [ label [ for "alcohol" ] [ text "度数 (%)" ]
                            , input
                                [ id "alcohol"
                                , class "form-input"
                                , type_ "number"
                                , Html.Attributes.min "0"
                                , Html.Attributes.max "100"
                                , Html.Attributes.step "0.1"
                                , placeholder "例: 15.0"
                                , value model.beverageForm.alcoholPercentage
                                , onInput (UpdateBeverageForm BeverageAlcoholField)
                                ]
                                []
                            ]
                        , div [ class "form-group" ]
                            [ label [ for "manufacturer" ] [ text "製造元" ]
                            , input
                                [ id "manufacturer"
                                , class "form-input"
                                , type_ "text"
                                , placeholder "製造元"
                                , value model.beverageForm.manufacturer
                                , onInput (UpdateBeverageForm BeverageManufacturerField)
                                ]
                                []
                            ]
                        , div [ class "form-group" ]
                            [ label [ for "description" ] [ text "説明" ]
                            , textarea
                                [ id "description"
                                , class "form-textarea"
                                , placeholder "お酒の説明文..."
                                , rows 5
                                , value model.beverageForm.description
                                , onInput (UpdateBeverageForm BeverageDescriptionField)
                                ]
                                []
                            ]
                        , div [ class "form-actions" ]
                            [ button
                                [ class "button-primary"
                                , type_ "submit"
                                ]
                                [ text "登録する" ]
                            , button
                                [ class "button-secondary ml-4"
                                , type_ "button"
                                , onClick (NavigateTo BeverageList)
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
        [ User.receiveUser ReceivedUser
        , User.receiveError ReceivedError
        , reviewSaved ReviewSaved
        , receiveReviews ReceivedReviews -- レビュー受信ポートを購読
        , beverageSaved BeverageSaved -- お酒保存結果の購読
        , receiveBeverages ReceivedBeverages -- お酒リスト受信の購読
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
