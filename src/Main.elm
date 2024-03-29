port module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D exposing (..)
import Json.Encode as E exposing (..)



-- main


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- ports


port sendMessage : String -> Cmd msg


port messageReceiver : (String -> msg) -> Sub msg



-- model


type alias Message =
    { name : String
    , message : String
    , time : String
    }


type alias Model =
    { currentMessage : Message
    , allMessages : List Message
    }


initModel : Model
initModel =
    Model { name = "", message = "", time = "" } []


init : () -> ( Model, Cmd Msg )
init _ =
    ( initModel, Cmd.none )



-- update


type Msg
    = SendMessage
    | UpdateChat (List Message)
    | InputName String
    | InputMessage String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputName name ->
            let
                newModel =
                    changeInnerRecord
                        "name"
                        name
                        model
            in
            ( newModel, Cmd.none )

        InputMessage message ->
            let
                newModel =
                    changeInnerRecord
                        "message"
                        message
                        model
            in
            ( newModel, Cmd.none )

        SendMessage ->
            ( model, sendMessage (E.encode 0 (encodeData model.currentMessage)) )

        UpdateChat list ->
            let
                newModel =
                    { model | allMessages = List.concat [ model.allMessages, list ], currentMessage = Message model.currentMessage.name "" "" }
            in
            ( newModel, Cmd.none )


changeInnerRecord : String -> String -> Model -> Model
changeInnerRecord field val ({ currentMessage } as inner) =
    case field of
        "name" ->
            { inner
                | currentMessage = { currentMessage | name = val }
            }

        "message" ->
            { inner
                | currentMessage = { currentMessage | message = val }
            }

        _ ->
            inner


encodeData : Message -> E.Value
encodeData data =
    E.object
        [ ( "name", E.string data.name )
        , ( "message", E.string data.message )
        ]


recordDecoder : D.Decoder Message
recordDecoder =
    D.map3
        Message
        (D.field "name" D.string)
        (D.field "message" D.string)
        (D.field "time" D.string)


listOfRecordsDecoder : D.Decoder (List Message)
listOfRecordsDecoder =
    D.list recordDecoder


decodeMsg : String -> Msg
decodeMsg message =
    D.decodeString listOfRecordsDecoder message
        |> Result.withDefault []
        |> UpdateChat



-- view


view : Model -> Html Msg
view model =
    div []
        [ h3 [] [ text "Chat with friends" ]
        , formSection model
        , chatSection model
        ]


formSection : Model -> Html Msg
formSection model =
    Html.form [ onSubmit SendMessage ]
        [ input
            [ type_ "text"
            , name "name"
            , placeholder "name"
            , onInput InputName
            , Html.Attributes.value model.currentMessage.name
            ]
            []
        , input
            [ type_ "text"
            , name "message"
            , placeholder "message"
            , onInput InputMessage
            , Html.Attributes.value model.currentMessage.message
            ]
            []
        , button
            [ type_ "submit" ]
            [ text "Send" ]
        ]


chatSection : Model -> Html Msg
chatSection model =
    model.allMessages
        |> List.map chatRow
        |> ul []


chatRow : Message -> Html Msg
chatRow item =
    li []
        [ div [ class "name-in-chat" ] [ text (item.name ++ ":") ]
        , div [ class "time-in-chat" ] [ text item.time ]
        , div [ class "message-in-chat" ] [ text item.message ]
        ]



-- subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    messageReceiver decodeMsg
