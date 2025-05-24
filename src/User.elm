port module User exposing
    ( Error
    , User
    , errorDecoder
    , receiveError
    , receiveUser
    , requestLogin
    , requestLogout
    , userDecoder
    )

import Json.Decode as Decode exposing (Decoder)



-- ユーザー型定義


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



-- ポート定義


port requestLogin : () -> Cmd msg


port requestLogout : () -> Cmd msg


port receiveUser : (Decode.Value -> msg) -> Sub msg


port receiveError : (Decode.Value -> msg) -> Sub msg



-- デコーダー


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
